# 服务配置文档

**生成时间:** 2026-06-01  
**项目路径:** /Users/fanyong/Desktop/code/python/docker_server

---

## 一、Infra 统一基础设施

### 1.1 Redis
- **容器名:** infra-redis
- **镜像:** redis:7.2-alpine
- **主机地址:** localhost / 127.0.0.1
- **端口:** 6379
- **密码:** redis123
- **连接字符串:** `redis://:redis123@localhost:6379`
- **状态:** ✅ 运行中 (healthy)
- **资源限制:** CPU 2核, 内存 1GB
- **数据卷:** redis-data

**连接示例:**
```python
# Python
import redis
r = redis.Redis(host='localhost', port=6379, password='redis123', decode_responses=True)

# 环境变量
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123
```

**Key 前缀隔离策略:**
- `pa:*` - personal_ai 项目
- `ma:*` - my_assistant 项目
- `ds:*` - docker_server 项目

---

### 1.2 PostgreSQL + pgvector
- **容器名:** infra-postgres
- **镜像:** pgvector/pgvector:pg16
- **主机地址:** localhost / 127.0.0.1
- **端口:** 5432
- **用户名:** postgres
- **密码:** postgres123
- **默认数据库:** postgres
- **状态:** ✅ 运行中 (healthy)
- **资源限制:** CPU 4核, 内存 4GB
- **数据卷:** postgres-data

**已创建数据库:**
| 数据库名 | 用途 | 扩展 |
|---------|------|------|
| postgres | 默认数据库 | - |
| personal_ai_db | personal_ai 项目 | vector |
| my_assistant_db | my_assistant 项目 | vector |
| docker_server_db | docker_server 项目 | vector |
| langfuse_db | langfuse 项目 (备用) | vector |

**连接字符串:**
```bash
# personal_ai
postgresql://postgres:postgres123@localhost:5432/personal_ai_db

# my_assistant
postgresql://postgres:postgres123@localhost:5432/my_assistant_db

# docker_server
postgresql://postgres:postgres123@localhost:5432/docker_server_db
```

**连接示例:**
```python
# Python (psycopg2)
import psycopg2
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    user="postgres",
    password="postgres123",
    database="personal_ai_db"
)

# SQLAlchemy
from sqlalchemy import create_engine
engine = create_engine('postgresql://postgres:postgres123@localhost:5432/personal_ai_db')

# 环境变量
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_DB=personal_ai_db
```

---

### 1.3 Neo4j
- **容器名:** infra-neo4j
- **镜像:** neo4j:5.15.0
- **主机地址:** localhost / 127.0.0.1
- **HTTP 端口:** 7474
- **Bolt 端口:** 7687
- **用户名:** neo4j
- **密码:** neo4j123
- **状态:** ✅ 运行中 (healthy)
- **资源限制:** CPU 2核, 内存 3GB
- **数据卷:** neo4j-data, neo4j-logs

**连接字符串:**
```bash
bolt://neo4j:neo4j123@localhost:7687
```

**Web 控制台:**
```
http://localhost:7474
用户名: neo4j
密码: neo4j123
```

**连接示例:**
```python
# Python (neo4j driver)
from neo4j import GraphDatabase

driver = GraphDatabase.driver(
    "bolt://localhost:7687",
    auth=("neo4j", "neo4j123")
)

# 环境变量
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=neo4j123
NEO4J_HTTP_PORT=7474
NEO4J_BOLT_PORT=7687
```

**节点标签隔离策略:**
- `:PersonalAI` - personal_ai 项目
- `:MyAssistant` - my_assistant 项目
- `:DockerServer` - docker_server 项目

---

### 1.4 Milvus (向量数据库)
- **容器名:** infra-milvus
- **镜像:** milvusdb/milvus:v2.6.1
- **主机地址:** localhost / 127.0.0.1
- **端口:** 19530 (gRPC)
- **Metrics 端口:** 9091
- **状态:** ✅ 运行中 (healthy)
- **资源限制:** CPU 2核, 内存 4GB
- **数据卷:** milvus-data

**连接示例:**
```python
# Python (pymilvus)
from pymilvus import connections, Collection

connections.connect(
    alias="default",
    host="localhost",
    port="19530"
)

# 环境变量
MILVUS_HOST=localhost
MILVUS_PORT=19530
```

**Collection 前缀隔离策略:**
- `pa_*` - personal_ai 项目
- `ma_*` - my_assistant 项目
- `ds_*` - docker_server 项目

---

### 1.5 Etcd (Milvus 依赖)
- **容器名:** infra-etcd
- **镜像:** quay.io/coreos/etcd:v3.5.18
- **端口:** 2379 (内部)
- **状态:** ✅ 运行中 (healthy)
- **资源限制:** CPU 2核, 内存 1GB
- **数据卷:** etcd-data

**内部连接:**
```bash
etcd:2379
```

---

### 1.6 Minio (Milvus 对象存储)
- **容器名:** infra-minio
- **镜像:** minio/minio:RELEASE.2024-12-18T13-15-44Z
- **主机地址:** localhost / 127.0.0.1
- **API 端口:** 9000
- **Console 端口:** 9001
- **Access Key:** minioadmin
- **Secret Key:** minioadmin
- **状态:** ✅ 运行中 (healthy)
- **资源限制:** CPU 2核, 内存 2GB
- **数据卷:** minio-data

**Web 控制台:**
```
http://localhost:9001
Access Key: minioadmin
Secret Key: minioadmin
```

**连接示例:**
```python
# Python (minio)
from minio import Minio

client = Minio(
    "localhost:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)

# 环境变量
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_CONSOLE_PORT=9001
```

---

### 1.7 Ollama (本地大模型)
- **容器名:** infra-ollama
- **镜像:** ollama/ollama:latest
- **主机地址:** localhost / 127.0.0.1
- **端口:** 11434
- **状态:** ⚠️ 运行中 (unhealthy - 健康检查配置问题,不影响使用)
- **资源限制:** CPU 6核, 内存 16GB
- **数据卷:** ollama-data

**已安装模型:**
- qwen3:8b (5.2GB)
- qwen3:4b (2.5GB)
- nomic-embed-text:latest (274MB)

**API 端点:**
```bash
http://localhost:11434
```

**连接示例:**
```python
# Python (requests)
import requests

response = requests.post(
    "http://localhost:11434/api/generate",
    json={
        "model": "qwen3:8b",
        "prompt": "你好"
    }
)

# 环境变量
OLLAMA_HOST=http://localhost:11434
```

**常用命令:**
```bash
# 列出模型
curl http://localhost:11434/api/tags

# 拉取模型
docker exec infra-ollama ollama pull qwen3:8b

# 运行模型
docker exec -it infra-ollama ollama run qwen3:8b
```

---

## 二、Langfuse 独立服务

### 2.1 PostgreSQL
- **容器名:** langfuse-postgres-1
- **镜像:** postgres:17
- **主机地址:** localhost / 127.0.0.1
- **端口:** 5433 (避免与 infra-postgres 冲突)
- **用户名:** postgres
- **密码:** 552abfe9d89ded25d5cb2d0feb29bfaa
- **数据库:** postgres
- **状态:** ✅ 运行中 (healthy)
- **数据卷:** langfuse_postgres_data

**连接字符串:**
```bash
postgresql://postgres:552abfe9d89ded25d5cb2d0feb29bfaa@localhost:5433/postgres
```

---

### 2.2 Redis
- **容器名:** langfuse-redis-1
- **镜像:** redis:7
- **主机地址:** localhost / 127.0.0.1
- **端口:** 6380 (避免与 infra-redis 冲突)
- **密码:** 552abfe9d89ded25d5cb2d0feb29bfaa
- **状态:** ✅ 运行中 (healthy)
- **数据卷:** langfuse_redis_data

**连接字符串:**
```bash
redis://:552abfe9d89ded25d5cb2d0feb29bfaa@localhost:6380
```

---

### 2.3 ClickHouse
- **容器名:** langfuse-clickhouse-1
- **镜像:** clickhouse/clickhouse-server:latest
- **主机地址:** localhost / 127.0.0.1
- **HTTP 端口:** 8123 (内部)
- **Native 端口:** 9000 (内部)
- **用户名:** clickhouse
- **密码:** 552abfe9d89ded25d5cb2d0feb29bfaa
- **数据库:** default
- **状态:** ✅ 运行中 (healthy)
- **数据卷:** langfuse_clickhouse_data, langfuse_clickhouse_logs

**连接字符串:**
```bash
clickhouse://clickhouse:552abfe9d89ded25d5cb2d0feb29bfaa@localhost:9000/default
```

---

### 2.4 Minio (S3 存储)
- **容器名:** langfuse-minio-1
- **镜像:** cgr.dev/chainguard/minio:latest
- **主机地址:** localhost / 127.0.0.1
- **API 端口:** 9090 (映射到容器 9000)
- **Console 端口:** 9092 (映射到容器 9001)
- **Root User:** minio
- **Root Password:** 552abfe9d89ded25d5cb2d0feb29bfaa
- **状态:** ✅ 运行中 (healthy)
- **数据卷:** langfuse_minio_data

**Web 控制台:**
```
http://localhost:9092
Root User: minio
Root Password: 552abfe9d89ded25d5cb2d0feb29bfaa
```

**Bucket:**
- langfuse (自动创建)

---

### 2.5 Langfuse Web (已停止)
- **容器名:** langfuse-langfuse-web-1
- **镜像:** langfuse/langfuse:3
- **端口:** 3000
- **状态:** ⏸️ 已停止 (密码配置不匹配)

---

### 2.6 Langfuse Worker (已停止)
- **容器名:** langfuse-langfuse-worker-1
- **镜像:** langfuse/langfuse-worker:3
- **端口:** 3030
- **状态:** ⏸️ 已停止 (密码配置不匹配)

---

## 三、端口占用总览

| 端口 | 服务 | 容器名 | 协议 |
|------|------|--------|------|
| 5432 | PostgreSQL (infra) | infra-postgres | TCP |
| 5433 | PostgreSQL (langfuse) | langfuse-postgres-1 | TCP |
| 6379 | Redis (infra) | infra-redis | TCP |
| 6380 | Redis (langfuse) | langfuse-redis-1 | TCP |
| 7474 | Neo4j HTTP | infra-neo4j | HTTP |
| 7687 | Neo4j Bolt | infra-neo4j | Bolt |
| 9000 | Minio API (infra) | infra-minio | HTTP |
| 9001 | Minio Console (infra) | infra-minio | HTTP |
| 9090 | Minio API (langfuse) | langfuse-minio-1 | HTTP |
| 9091 | Milvus Metrics | infra-milvus | HTTP |
| 9092 | Minio Console (langfuse) | langfuse-minio-1 | HTTP |
| 11434 | Ollama API | infra-ollama | HTTP |
| 19530 | Milvus gRPC | infra-milvus | gRPC |

**内部端口 (仅容器间访问):**
- 2379 - Etcd
- 8123 - ClickHouse HTTP
- 9000 - ClickHouse Native

---

## 四、Docker Compose 文件

### 4.1 Infra 基础设施
```bash
# 启动所有服务
cd /Users/fanyong/Desktop/code/python/docker_server
docker compose -f docker-compose.unified.yml up -d

# 停止所有服务
docker compose -f docker-compose.unified.yml down

# 查看日志
docker compose -f docker-compose.unified.yml logs -f

# 重启单个服务
docker compose -f docker-compose.unified.yml restart redis
```

### 4.2 Langfuse 服务
```bash
# 启动所有服务
cd /Users/fanyong/Desktop/code/python/docker_server/langfuse
docker compose up -d

# 停止所有服务
docker compose down

# 查看日志
docker compose logs -f
```

---

## 五、数据备份

### 5.1 PostgreSQL 备份
```bash
# 备份所有数据库
docker exec infra-postgres pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# 备份单个数据库
docker exec infra-postgres pg_dump -U postgres personal_ai_db > personal_ai_backup_$(date +%Y%m%d).sql

# 恢复数据库
docker exec -i infra-postgres psql -U postgres < backup_20260601.sql
```

### 5.2 Redis 备份
```bash
# 触发 RDB 快照
docker exec infra-redis redis-cli -a redis123 SAVE

# 复制 RDB 文件
docker cp infra-redis:/data/dump.rdb ./redis_backup_$(date +%Y%m%d).rdb
```

### 5.3 Neo4j 备份
```bash
# 导出数据库
docker exec infra-neo4j neo4j-admin database dump neo4j --to-path=/data/backups

# 复制备份文件
docker cp infra-neo4j:/data/backups/neo4j.dump ./neo4j_backup_$(date +%Y%m%d).dump
```

---

## 六、常见问题

### 6.1 容器无法启动
```bash
# 查看容器日志
docker logs <container_name> --tail 50

# 检查端口占用
lsof -i :<port>

# 重建容器
docker compose -f docker-compose.unified.yml up -d --force-recreate <service_name>
```

### 6.2 健康检查失败
```bash
# 查看健康检查日志
docker inspect <container_name> --format='{{json .State.Health}}' | python3 -m json.tool

# 手动测试健康检查
docker exec <container_name> <health_check_command>
```

### 6.3 数据库连接失败
```bash
# 测试 PostgreSQL 连接
docker exec infra-postgres psql -U postgres -c "SELECT version();"

# 测试 Redis 连接
docker exec infra-redis redis-cli -a redis123 PING

# 测试 Neo4j 连接
curl http://localhost:7474
```

---

## 七、资源监控

### 7.1 实时监控
```bash
# 查看所有容器资源使用
docker stats

# 查看磁盘使用
docker system df

# 查看特定容器资源
docker stats infra-postgres infra-redis infra-neo4j
```

### 7.2 日志查看
```bash
# 查看所有 infra 服务日志
docker compose -f docker-compose.unified.yml logs -f

# 查看特定服务日志
docker logs infra-postgres -f --tail 100

# 查看错误日志
docker logs infra-milvus 2>&1 | grep -i error
```

---

## 八、安全建议

### 8.1 生产环境配置
⚠️ **当前配置为开发环境,生产环境需修改:**

1. **修改所有默认密码**
   - Redis: redis123 → 强密码
   - PostgreSQL: postgres123 → 强密码
   - Neo4j: neo4j123 → 强密码
   - Minio: minioadmin → 强密码

2. **限制端口绑定**
   - 将 `0.0.0.0` 改为 `127.0.0.1` (仅本机访问)
   - 或使用防火墙规则限制访问

3. **启用 TLS/SSL**
   - PostgreSQL: 配置 SSL 证书
   - Redis: 启用 TLS
   - Neo4j: 启用 HTTPS

4. **定期备份**
   - 设置自动备份脚本
   - 异地存储备份文件

---

## 九、项目迁移指南

### 9.1 docker_server 项目迁移到 infra

**修改 `.env` 文件:**
```env
# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_DB=docker_server_db

# Neo4j
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=neo4j123

# Milvus
MILVUS_HOST=localhost
MILVUS_PORT=19530

# Ollama
OLLAMA_HOST=http://localhost:11434
```

**修改 `docker-compose.yml`:**
```yaml
services:
  app:
    # 删除 redis, postgres, neo4j, milvus 等服务定义
    # 应用服务直接连接 localhost 端口
    environment:
      - REDIS_HOST=host.docker.internal
      - POSTGRES_HOST=host.docker.internal
      - NEO4J_URI=bolt://host.docker.internal:7687
      - MILVUS_HOST=host.docker.internal
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

---

## 十、联系信息

- **项目路径:** /Users/fanyong/Desktop/code/python/docker_server
- **配置文件:** docker-compose.unified.yml
- **备份目录:** /Users/fanyong/Desktop/code/python/docker_server/backup
- **分析报告:** CONTAINER_ANALYSIS.md

---

**最后更新:** 2026-06-01  
**维护者:** fanyong (fanyong109@163.com)
