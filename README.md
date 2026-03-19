# Docker Server - 个人知识库服务

## 项目概述

本项目为 [personal_ai](file:///Users/fanyong/Desktop/code/python/personal_ai) 项目提供独立的知识库服务，包含 Milvus 向量数据库、PostgreSQL 关系数据库和 Redis 缓存服务。

## 服务对应关系

### personal_ai 项目本地配置
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Milvus**: localhost:19530
- **Neo4j**: localhost:7687

### docker_server 知识库服务
- **PostgreSQL**: localhost:6432
- **Redis**: localhost:7379
- **Milvus**: localhost:20530
- **Milvus Metrics**: localhost:10091
- **Minio API**: localhost:10000
- **Minio Console**: localhost:10001

## 快速启动

### 1. 启动知识库服务
```bash
docker-compose -f docker-compose-kb.yml --env-file .env.kb up -d
```

### 2. 启动完整服务（包含 Neo4j）
```bash
docker-compose up -d
```

### 3. 查看服务状态
```bash
docker-compose -f docker-compose-kb.yml ps
docker-compose ps
```

### 4. 查看日志
```bash
docker-compose -f docker-compose-kb.yml logs -f
docker-compose logs -f [service_name]
```

### 5. 停止服务
```bash
docker-compose -f docker-compose-kb.yml down
docker-compose down
```

## 环境变量配置

### 知识库服务 (.env.kb)
```bash
# Redis
KB_REDIS_PASSWORD=kb123456
KB_REDIS_PORT=7379

# PostgreSQL
KB_POSTGRES_USER=kb_user
KB_POSTGRES_PASSWORD=kb123456
KB_POSTGRES_DB=knowledge_base
KB_POSTGRES_PORT=6432

# Milvus
KB_MILVUS_PORT=20530
KB_MILVUS_METRICS_PORT=10091

# Minio
KB_MINIO_ACCESS_KEY=kbadmin
KB_MINIO_SECRET_KEY=kbadmin123
KB_MINIO_API_PORT=10000
KB_MINIO_CONSOLE_PORT=10001
```

### 完整服务 (.env)
```bash
# Redis
REDIS_PASSWORD=123456
REDIS_PORT=6379

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=123456
POSTGRES_DB=mydb
POSTGRES_PORT=5432

# Neo4j
NEO4J_USER=neo4j
NEO4J_PASSWORD=12345678
NEO4J_HTTP_PORT=7474
NEO4J_BOLT_PORT=7687

# Milvus
MILVUS_PORT=19530
MILVUS_METRICS_PORT=9091

# Minio
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
```

## 服务访问

### 知识库服务
- **PostgreSQL**: `postgresql://kb_user:kb123456@localhost:6432/knowledge_base`
- **Redis**: `redis://:kb123456@localhost:7379/0`
- **Milvus**: `localhost:20530`
- **Minio Console**: http://localhost:10001

### 完整服务
- **PostgreSQL**: `postgresql://postgres:123456@localhost:5432/mydb`
- **Redis**: `redis://:123456@localhost:6379/0`
- **Neo4j Browser**: http://localhost:7474
- **Neo4j Bolt**: `bolt://localhost:7687`
- **Milvus**: `localhost:19530`
- **Minio Console**: http://localhost:9001

## 与 personal_ai 项目集成

### personal_ai 使用默认服务
编辑 `/Users/fanyong/Desktop/code/python/personal_ai/.env`:

```bash
# 使用 docker_server 默认服务
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=123456
POSTGRES_DB=mydb

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=123456

MILVUS_HOST=localhost
MILVUS_PORT=19530

NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=12345678
```

### personal_ai 使用知识库服务
编辑 `/Users/fanyong/Desktop/code/python/personal_ai/.env`:

```bash
# 使用 docker_server 知识库服务
POSTGRES_HOST=localhost
POSTGRES_PORT=6432
POSTGRES_USER=kb_user
POSTGRES_PASSWORD=kb123456
POSTGRES_DB=knowledge_base

REDIS_HOST=localhost
REDIS_PORT=7379
REDIS_PASSWORD=kb123456

MILVUS_HOST=localhost
MILVUS_PORT=20530
```

### Python 连接示例

```python
# PostgreSQL
from sqlalchemy import create_engine
engine = create_engine('postgresql://kb_user:kb123456@localhost:6432/knowledge_base')

# Redis
import redis
r = redis.Redis(host='localhost', port=7379, password='kb123456', db=0)

# Milvus
from pymilvus import connections
connections.connect(host='localhost', port='20530')
```

## 数据持久化

### 知识库服务
- `kb-redis-data`: Redis 数据
- `kb-postgres-data`: PostgreSQL 数据
- `./volumes/kb-etcd`: Etcd 数据
- `./volumes/kb-minio`: Minio 对象存储
- `./volumes/kb-milvus`: Milvus 向量数据

### 完整服务
- `redis-data`: Redis 数据
- `postgres-data`: PostgreSQL 数据
- `neo4j-data`: Neo4j 图数据库
- `neo4j-logs`: Neo4j 日志
- `neo4j-import`: Neo4j 导入目录
- `neo4j-plugins`: Neo4j 插件

## 备份与恢复

### 导出 Neo4j 数据
```bash
python export_neo4j.py
```

### 导入 Neo4j 数据
```bash
python import_neo4j.py
```

### 备份 PostgreSQL
```bash
docker exec kb-postgres pg_dump -U kb_user knowledge_base > backup.sql
```

### 恢复 PostgreSQL
```bash
docker exec -i kb-postgres psql -U kb_user knowledge_base < backup.sql
```

## 资源限制

### 知识库服务
- **Redis**: 2 CPUs, 4GB RAM
- **PostgreSQL**: 4 CPUs, 8GB RAM
- **Milvus**: 4 CPUs, 8GB RAM

### 完整服务
- **Redis**: 2 CPUs, 4GB RAM
- **PostgreSQL**: 4 CPUs, 8GB RAM
- **Milvus**: 4 CPUs, 8GB RAM

## 健康检查

所有服务均配置健康检查，启动后自动验证服务可用性。

### 手动检查
```bash
# Redis
docker exec kb-redis redis-cli -a kb123456 ping

# PostgreSQL
docker exec kb-postgres pg_isready -U kb_user

# Milvus
curl http://localhost:10091/healthz
```

## 故障排除

### 端口冲突
```bash
# 查看端口占用
lsof -i :6432
lsof -i :7379
lsof -i :20530

# 修改 .env.kb 中的端口配置
```

### 容器启动失败
```bash
# 查看日志
docker-compose -f docker-compose-kb.yml logs [service_name]

# 重启服务
docker-compose -f docker-compose-kb.yml restart [service_name]
```

### 数据清理
```bash
# 停止并删除容器、网络
docker-compose -f docker-compose-kb.yml down

# 删除数据卷（谨慎操作）
docker-compose -f docker-compose-kb.yml down -v
```

## 项目文件

```
docker_server/
├── docker-compose.yml          # 完整服务配置
├── docker-compose-kb.yml       # 知识库服务配置
├── .env                        # 完整服务环境变量
├── .env.kb                     # 知识库服务环境变量
├── redis.conf                  # Redis 配置
├── export_neo4j.py            # Neo4j 导出脚本
├── import_neo4j.py            # Neo4j 导入脚本
├── app/
│   └── app.py                 # Flask 示例应用
└── volumes/                   # 数据持久化目录
    ├── kb-etcd/
    ├── kb-minio/
    ├── kb-milvus/
    ├── etcd/
    ├── minio/
    └── milvus/
```

docker compose --env-file .env.kb -f docker-compose-kb.yml up -d