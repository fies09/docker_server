# Docker 容器服务全局分析报告

## 一、当前运行状态总览

### 1.1 运行中的容器 (9个)
| 容器名 | 镜像 | 状态 | 端口映射 | 所属项目 |
|--------|------|------|----------|----------|
| infra-redis | redis:7.2-alpine | Up 8h | 6379:6379 | infra (统一基础设施) |
| infra-postgres | pgvector/pgvector:pg16 | Up 8h | 5432:5432 | infra (统一基础设施) |
| infra-neo4j | neo4j:5.15.0 | Up 8h | 7474:7474, 7687:7687 | infra (统一基础设施) |
| infra-ollama | ollama/ollama:latest | Up 8h (unhealthy) | 11434:11434 | infra (统一基础设施) |
| postgres | postgres:latest | Up 8m | 5432 (内部) | docker_server |
| redis | redis:7.2 | Up 8m | 6379 (内部) | docker_server |
| neo4j | neo4j:5.15.0 | Up 11m | 7475:7474, 7688:7687 | docker_server |
| milvus-minio | minio/minio | Up 11m | 9000-9001:9000-9001 | docker_server |
| milvus-etcd | etcd:v3.5.18 | Up 11m | 2379 (内部) | docker_server |

### 1.2 已停止/创建未启动的容器 (10个)
| 容器名 | 镜像 | 状态 | 原因 |
|--------|------|------|------|
| langfuse-postgres-1 | postgres:17 | Created | 端口冲突 5432 |
| langfuse-redis-1 | redis:7 | Created | 端口冲突 6379 |
| langfuse-clickhouse-1 | clickhouse/clickhouse-server | Created | 依赖未启动 |
| langfuse-minio-1 | cgr.dev/chainguard/minio | Up 7m | 9090:9000 |
| langfuse-langfuse-web-1 | langfuse/langfuse:3 | Created | 依赖未启动 |
| langfuse-langfuse-worker-1 | langfuse/langfuse-worker:3 | Created | 依赖未启动 |
| milvus-standalone | milvusdb/milvus:v2.5.4 | Exited (134) | 内存不足或配置问题 |
| infra-milvus | milvusdb/milvus:v2.6.1 | Exited (255) 3d | 异常退出 |
| infra-minio | minio/minio | Exited (255) 3d | 异常退出 |
| infra-etcd | etcd:v3.5.18 | Exited (255) 3d | 异常退出 |

---

## 二、服务重复性分析

### 2.1 Redis (严重重复 - 4个实例)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-redis | 7.2-alpine (41MB) | 6379 | ✅ Running | 统一基础设施 |
| redis (docker_server) | 7.2 (139MB) | 6379 (内部) | ✅ Running | docker_server 项目 |
| langfuse-redis-1 | 7 (136MB) | 6380 (已修改) | ⏸️ Created | langfuse 项目 |
| personal_ai Redis | 7.2 (镜像存在) | - | ❌ 未运行 | personal_ai 项目 |

**问题:**
- 4个 Redis 实例占用 ~460MB 磁盘空间
- infra-redis 和 docker_server redis 同时占用 6379 端口 (冲突)
- 内存浪费: 每个实例至少 512MB-1GB

**建议:** ✅ **统一使用 infra-redis**
- 通过 key 前缀隔离不同项目: `pa:*`, `ma:*`, `langfuse:*`, `ds:*`
- 停止 docker_server redis 和 langfuse-redis-1
- 所有项目连接 `infra-redis:6379`

---

### 2.2 PostgreSQL (严重重复 - 4个实例)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-postgres | pgvector:pg16 (459MB) | 5432 | ✅ Running | 统一基础设施 (支持向量) |
| postgres (docker_server) | postgres:latest (479MB) | 5432 (内部) | ✅ Running | docker_server 项目 |
| langfuse-postgres-1 | postgres:17 (476MB) | 5433 (已修改) | ⏸️ Created | langfuse 项目 |
| personal_ai Postgres | pgvector (镜像存在) | - | ❌ 未运行 | personal_ai 项目 |

**问题:**
- 4个 PostgreSQL 实例占用 ~1.9GB 磁盘空间
- 端口冲突: infra-postgres 和 docker_server postgres 都占用 5432
- 内存浪费: 每个实例 4-8GB

**建议:** ✅ **统一使用 infra-postgres (pgvector)**
- 已支持多数据库: `personal_ai_db`, `my_assistant_db`
- 添加数据库: `docker_server_db`, `langfuse_db`
- 停止其他 3 个实例
- 所有项目连接 `infra-postgres:5432`

---

### 2.3 Neo4j (中度重复 - 2个实例)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-neo4j | neo4j:5.27.0 | 7474, 7687 | ✅ Running | 统一基础设施 |
| neo4j (docker_server) | neo4j:5.15.0 (488MB) | 7475, 7688 | ✅ Running | docker_server 项目 |

**问题:**
- 2个 Neo4j 实例占用 ~976MB 磁盘空间
- 版本不一致: 5.27.0 vs 5.15.0
- 内存浪费: 每个实例 2-3GB

**建议:** ✅ **统一使用 infra-neo4j (5.27.0)**
- 通过节点标签隔离: `:DockerServer`, `:PersonalAI`, `:MyAssistant`
- 停止 docker_server neo4j
- 所有项目连接 `infra-neo4j:7687`

---

### 2.4 Milvus (严重重复 - 2套完整环境)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-milvus | v2.6.1 (2.19GB) | 19530, 9091 | ❌ Exited | 统一基础设施 |
| milvus-standalone | v2.5.4 (1.56GB) | 19530, 9091 | ❌ Exited | docker_server 项目 |
| infra-etcd | v3.5.18 (57MB) | 2379 | ❌ Exited | infra 依赖 |
| milvus-etcd | v3.5.18 (57MB) | 2379 | ✅ Running | docker_server 依赖 |
| infra-minio | RELEASE.2024-12-18 (172MB) | 9000-9001 | ❌ Exited | infra 依赖 |
| milvus-minio | RELEASE.2024-12-18 (172MB) | 9000-9001 | ✅ Running | docker_server 依赖 |

**问题:**
- 2套 Milvus 环境占用 ~4.2GB 磁盘空间
- 版本不一致: v2.6.1 vs v2.5.4
- 依赖服务重复: etcd (2个), minio (2个)
- 两套环境都已停止,资源完全浪费

**建议:** ✅ **统一使用 infra-milvus (v2.6.1)**
- 通过 collection 前缀隔离: `ds_*`, `pa_*`, `ma_*`
- 删除 docker_server 的 milvus-standalone, milvus-etcd, milvus-minio
- 重启 infra-milvus + infra-etcd + infra-minio
- 所有项目连接 `infra-milvus:19530`

---

### 2.5 Minio (严重重复 - 3个实例)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-minio | minio/minio (172MB) | 9000-9001 | ❌ Exited | infra Milvus 依赖 |
| milvus-minio | minio/minio (172MB) | 9000-9001 | ✅ Running | docker_server Milvus 依赖 |
| langfuse-minio-1 | cgr.dev/chainguard/minio (160MB) | 9090:9000 | ✅ Running | langfuse S3 存储 |

**问题:**
- 3个 Minio 实例占用 ~504MB 磁盘空间
- 端口冲突: infra-minio 和 milvus-minio 都占用 9000-9001
- langfuse-minio 使用不同镜像 (chainguard)

**建议:** ⚠️ **部分统一**
- Milvus 相关: 统一使用 infra-minio (删除 milvus-minio)
- Langfuse: 保留独立 langfuse-minio (不同用途: S3 对象存储)

---

### 2.6 Etcd (中度重复 - 2个实例)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-etcd | v3.5.18 (57MB) | 2379 | ❌ Exited | infra Milvus 依赖 |
| milvus-etcd | v3.5.18 (57MB) | 2379 | ✅ Running | docker_server Milvus 依赖 |

**问题:**
- 2个 Etcd 实例占用 ~114MB 磁盘空间
- 端口冲突: 都占用 2379

**建议:** ✅ **统一使用 infra-etcd**
- 删除 milvus-etcd
- 重启 infra-etcd

---

### 2.7 Langfuse 专用服务 (无重复)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| langfuse-clickhouse-1 | clickhouse/clickhouse-server (824MB) | 8123, 9000 | ⏸️ Created | 分析数据库 |
| langfuse-langfuse-web-1 | langfuse/langfuse:3 (1.03GB) | 3000 | ⏸️ Created | Web 服务 |
| langfuse-langfuse-worker-1 | langfuse/langfuse-worker:3 (1.06GB) | 3030 | ⏸️ Created | 后台任务 |
| langfuse-minio-1 | cgr.dev/chainguard/minio (160MB) | 9090 | ✅ Running | S3 存储 |

**建议:** ✅ **保留独立运行**
- Langfuse 是独立产品,需要专用服务
- 仅共享 Redis 和 PostgreSQL

---

### 2.8 其他服务 (无重复)
| 实例 | 镜像版本 | 端口 | 状态 | 用途 |
|------|----------|------|------|------|
| infra-ollama | ollama/ollama:latest (5.69GB) | 11434 | ✅ Running (unhealthy) | 本地大模型 |

**建议:** ✅ **保持独立**
- 检查 unhealthy 状态原因
- 所有项目共享此实例

---

## 三、优化方案

### 3.1 立即执行 (解决端口冲突)
```bash
# 1. 停止 docker_server 重复服务
docker stop redis postgres neo4j milvus-standalone milvus-minio milvus-etcd
docker rm redis postgres neo4j milvus-standalone milvus-minio milvus-etcd

# 2. 重启 infra 基础设施 (修复已停止的服务)
cd /Users/fanyong/Desktop/code/python/docker_server
docker compose -f docker-compose.unified.yml up -d

# 3. 启动 langfuse (端口已修改)
cd langfuse
docker compose up -d
```

### 3.2 配置修改 (统一连接 infra)

#### docker_server 项目
修改 `.env`:
```env
REDIS_HOST=infra-redis
REDIS_PORT=6379
POSTGRES_HOST=infra-postgres
POSTGRES_PORT=5432
NEO4J_HOST=infra-neo4j
NEO4J_BOLT_PORT=7687
MILVUS_HOST=infra-milvus
MILVUS_PORT=19530
```

修改 `docker-compose.yml`:
```yaml
services:
  # 删除 redis, postgresql, neo4j, milvus, etcd, minio 服务定义
  
  # 应用服务连接外部网络
  app:
    networks:
      - infra_infra-network
    external_links:
      - infra-redis:redis
      - infra-postgres:postgres
      - infra-neo4j:neo4j
      - infra-milvus:milvus

networks:
  infra_infra-network:
    external: true
```

#### langfuse 项目
修改 `docker-compose.yml`:
```yaml
services:
  langfuse-web:
    environment:
      DATABASE_URL: postgresql://postgres:postgres123@infra-postgres:5432/langfuse_db
      REDIS_HOST: infra-redis
      REDIS_PORT: 6379
      REDIS_AUTH: redis123
    networks:
      - default
      - infra_infra-network
  
  # 删除 redis, postgres 服务定义
  # 保留 clickhouse, minio, langfuse-web, langfuse-worker

networks:
  infra_infra-network:
    external: true
```

#### personal_ai / my_assistant 项目
已配置连接 infra,无需修改。

---

### 3.3 数据库初始化

#### PostgreSQL 添加数据库
```bash
docker exec -it infra-postgres psql -U postgres -c "CREATE DATABASE docker_server_db;"
docker exec -it infra-postgres psql -U postgres -c "CREATE DATABASE langfuse_db;"
docker exec -it infra-postgres psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;" -d docker_server_db
docker exec -it infra-postgres psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;" -d langfuse_db
```

---

## 四、资源节省估算

### 4.1 磁盘空间节省
| 服务 | 删除实例数 | 节省空间 |
|------|-----------|---------|
| Redis | 3 → 1 | ~320MB |
| PostgreSQL | 4 → 1 | ~1.4GB |
| Neo4j | 2 → 1 | ~488MB |
| Milvus | 2 → 1 | ~1.56GB |
| Etcd | 2 → 1 | ~57MB |
| Minio | 3 → 2 | ~172MB |
| **总计** | - | **~4GB** |

### 4.2 内存节省
| 服务 | 删除实例数 | 节省内存 |
|------|-----------|---------|
| Redis | 3 → 1 | ~2GB |
| PostgreSQL | 4 → 1 | ~12GB |
| Neo4j | 2 → 1 | ~3GB |
| Milvus | 2 → 1 | ~6GB |
| Etcd | 2 → 1 | ~1GB |
| Minio | 3 → 2 | ~2GB |
| **总计** | - | **~26GB** |

### 4.3 CPU 节省
- 减少 15 个容器进程
- 减少网络开销 (容器间通信)
- 减少磁盘 I/O 竞争

---

## 五、风险评估

### 5.1 低风险
- ✅ Redis/PostgreSQL/Neo4j 统一: 通过逻辑隔离,无数据混淆风险
- ✅ Milvus 统一: collection 前缀隔离,版本向下兼容

### 5.2 中风险
- ⚠️ 单点故障: 一个服务挂掉影响所有项目
  - **缓解**: 配置 healthcheck + restart: always
- ⚠️ 资源竞争: 多项目共享可能导致性能下降
  - **缓解**: 设置 CPU/内存限制 (已配置)

### 5.3 高风险
- ❌ 数据迁移: 需要从旧实例迁移数据到 infra
  - **缓解**: 先备份,再迁移,保留旧容器 7 天

---

## 六、迁移检查清单

### 6.1 迁移前
- [ ] 备份所有数据库
  ```bash
  docker exec redis redis-cli --rdb /data/dump.rdb
  docker exec postgres pg_dumpall -U postgres > backup.sql
  docker exec neo4j neo4j-admin dump --to=/data/backup.dump
  ```
- [ ] 记录当前连接配置
- [ ] 测试 infra 服务健康状态

### 6.2 迁移中
- [ ] 停止应用服务 (避免数据写入)
- [ ] 导入数据到 infra
- [ ] 修改配置文件
- [ ] 启动应用服务

### 6.3 迁移后
- [ ] 验证应用功能正常
- [ ] 监控资源使用情况
- [ ] 7 天后删除旧容器和镜像

---

## 七、推荐执行顺序

1. **Phase 1: 修复 infra 基础设施** (优先级: 🔴 高)
   - 重启 infra-milvus, infra-etcd, infra-minio
   - 检查 infra-ollama unhealthy 原因

2. **Phase 2: 迁移 docker_server** (优先级: 🟡 中)
   - 备份数据
   - 修改配置连接 infra
   - 删除重复服务

3. **Phase 3: 迁移 langfuse** (优先级: 🟢 低)
   - 修改配置连接 infra Redis/PostgreSQL
   - 保留 ClickHouse 和 Minio

4. **Phase 4: 清理镜像** (优先级: 🟢 低)
   ```bash
   docker image prune -a
   ```

---

## 八、监控建议

### 8.1 资源监控
```bash
# 实时监控容器资源
docker stats

# 查看磁盘使用
docker system df
```

### 8.2 健康检查
```bash
# 检查所有服务健康状态
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### 8.3 日志监控
```bash
# 查看 infra 服务日志
docker compose -f docker-compose.unified.yml logs -f
```

---

## 九、总结

### 当前问题
1. **严重资源浪费**: 15+ 个重复容器,浪费 ~4GB 磁盘 + ~26GB 内存
2. **端口冲突**: Redis/PostgreSQL/Minio 多处冲突
3. **版本不一致**: Neo4j (5.15.0 vs 5.27.0), Milvus (v2.5.4 vs v2.6.1)
4. **管理混乱**: 3 套独立环境 (infra, docker_server, langfuse)

### 优化目标
1. **统一基础设施**: 所有项目共享 infra 服务
2. **逻辑隔离**: 通过数据库/key前缀/collection前缀隔离
3. **资源节省**: 减少 ~4GB 磁盘 + ~26GB 内存
4. **简化管理**: 单一 docker-compose.unified.yml

### 最终架构
```
infra (统一基础设施)
├── Redis (6379) - 所有项目共享
├── PostgreSQL (5432) - 多数据库隔离
├── Neo4j (7474, 7687) - 标签隔离
├── Milvus (19530) - collection 前缀隔离
│   ├── Etcd (2379)
│   └── Minio (9000-9001)
└── Ollama (11434) - 本地大模型

langfuse (独立服务)
├── ClickHouse (8123, 9000)
├── Minio (9090) - S3 存储
├── Web (3000)
└── Worker (3030)

docker_server (应用层)
└── 连接 infra 服务

personal_ai (应用层)
└── 连接 infra 服务

my_assistant (应用层)
└── 连接 infra 服务
```
