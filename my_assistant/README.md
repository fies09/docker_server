# my_assistant - 智能助手基础设施

my_assistant 项目的 Docker 一键部署栈，自包含 PostgreSQL / Redis / Neo4j / Milvus(+etcd+minio) / Attu 及 FastAPI 应用。

## 目录结构

```
my_assistant/
├── docker-compose.yml              # FastAPI 应用(连接数据服务)
├── docker-compose.data.yml         # 数据服务栈 (PG/Redis/Neo4j/Milvus/etcd/minio/Attu)
├── docker-compose.milvus.yml       # Milvus 三件套独立栈 (etcd+minio+standalone)
├── Dockerfile                      # FastAPI 镜像构建
├── env.example                     # 凭证 + 端口模板
├── scripts/
│   └── backup_restore/
│       ├── export_milvus.py        # Milvus → JSONL 导出
│       ├── restore_milvus.py       # JSONL → Milvus 恢复
│       ├── backup_postgres.py      # PostgreSQL pg_dump 逻辑备份
│       ├── backup_redis.py         # Redis RDB 快照
│       └── backup_neo4j.py         # Neo4j cypher-shell 导出
└── README.md
```

## 启动顺序

```bash
cd /Users/fanyong/Desktop/code/python/docker_server/my_assistant

# 0) 复制环境变量
cp env.example .env

# 1) 数据服务栈
docker compose --env-file .env -f docker-compose.data.yml up -d

# 2) FastAPI 应用
docker compose --env-file .env up -d
```

> 若只需要 Milvus 三件套（不带 PG/Redis/Neo4j），改用 `docker-compose.milvus.yml`。

## 端口与凭证

| 服务 | 容器名 | 主机端口 | 凭证 |
|------|--------|----------|------|
| PostgreSQL | ma-postgres | 5432 | postgres / postgres123 |
| Redis | ma-redis | 6379 | redis123 |
| Neo4j HTTP | ma-neo4j | 7474 | neo4j / neo4j123 |
| Neo4j Bolt | ma-neo4j | 7687 | neo4j / neo4j123 |
| Milvus | ma-milvus | 19530 | — |
| Milvus Health | ma-milvus | 9091 | — |
| MinIO API | ma-minio | 9000 | minioadmin / minioadmin |
| MinIO Console | ma-minio | 9001 | minioadmin / minioadmin |
| Attu | ma-attu | 8001 | — |
| FastAPI | my-assistant | 8000 | — |

## 网络

两个 compose 文件共享 `assistant-network`（bridge）。数据栈启动时创建，应用 compose 通过同名网络加入。

## 备份与恢复

```bash
# PostgreSQL 逻辑备份 (pg_dump)
python scripts/backup_restore/backup_postgres.py

# Redis RDB 快照
python scripts/backup_restore/backup_redis.py

# Neo4j 节点 + 关系导出
python scripts/backup_restore/backup_neo4j.py

# Milvus 逐 collection JSONL 导出
python scripts/backup_restore/export_milvus.py \
  --host 127.0.0.1 --port 19530

# Milvus 从 JSONL 恢复
python scripts/backup_restore/restore_milvus.py \
  --backup-dir /path/to/backup_root/<timestamp> \
  --skip-existing
```

默认备份根目录：`/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份`

> 注意：Milvus standalone 元数据落在 etcd + minio 两个 volume 中。业务 collection 缺索引时 `query()` 会失败，可改用 volume 物理打包。

## 与 my_assistant 应用源码的对应

`docker-compose.yml` 中 FastAPI 构建上下文指向 `~/Desktop/code/deve/drass/my_assistant`，修改源码后：

```bash
docker compose build assistant
docker compose up -d assistant
```

## 资源建议

| 服务 | 最低 | 推荐（导入大集合） |
|------|------|-------------------|
| Milvus | 8 GB | 16-24 GB（调 MILVUS_MEMORY_LIMIT） |
| Neo4j | 2 GB | 4 GB |
| PostgreSQL | 512 MB | 2 GB |
| Redis | 256 MB | 1 GB |
| FastAPI | 2 GB | 4 GB |

## 与父目录 docker_server 的关系

本目录已自包含全部数据服务配置。父目录 `docker_server/infra/docker-compose.yml`（name: infra）仍可继续供 personal_ai 等其他项目共用，但 my_assistant 项目优先使用本目录自包含的栈。