# 统一基础设施服务

所有项目的 Docker 基础设施服务统一管理。

## 包含服务

| 服务 | 容器名 | 端口 | 用途 |
|------|--------|------|------|
| Redis | infra-redis | 6379 | 缓存 |
| PostgreSQL+pgvector | infra-postgres | 5432 | 关系数据库/向量存储 |
| Milvus | infra-milvus | 19530 | 向量数据库 |
| etcd | infra-etcd | 2379 | Milvus依赖 |
| minio | infra-minio | 9000/9001 | Milvus依赖 |
| Neo4j | infra-neo4j | 7474/7687 | 图数据库 |
| Ollama | infra-ollama | 11434 | 本地大模型 |

## 快速开始

```bash
# 1. 复制环境变量模板
cp .env.infra.example .env

# 2. 启动所有服务
docker-compose -f docker-compose.infra.yml up -d

# 3. 查看状态
docker-compose -f docker-compose.infra.yml ps

# 4. 拉取 Ollama 模型
docker exec -it infra-ollama ollama pull qwen3:4b
```

## 项目配置适配

### personal_ai

修改 `.env`:
```
POSTGRES_HOST=infra-postgres
POSTGRES_PORT=5432
REDIS_HOST=infra-redis
REDIS_PORT=6379
MILVUS_HOST=infra-milvus
MILVUS_PORT=19530
NEO4J_URI=bolt://infra-neo4j:7687
OLLAMA_BASE_URL=http://infra-ollama:11434
```

### my_assistant

修改 `.env`:
```
# 同上，使用 infra-* 作为主机名
```

## Paraformer ASR 建议

| 方案 | 适用场景 | 部署方式 |
|------|----------|----------|
| DashScope API | 低频使用/快速接入 | 无需部署，配置API Key |
| FunASR 本地 | 高频使用/隐私敏感 | docker run -p 10095:10095 registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-cpu-0.4.5 |

## Qwen3-VL-2B

该多模态模型不支持 Ollama，需独立部署:
- 保留原项目中的 VL 服务
- 或使用 transformers 直接加载

## 资源需求

- 内存: 32GB 推荐（全部服务）
- 存储: 50GB+（含模型文件）

## 原有配置处理

原项目 `docker-compose.yml` 可保留作为独立运行备份，或删除。
