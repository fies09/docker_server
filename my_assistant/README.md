# my_assistant - 智能助手基础设施

my_assistant 项目的 Docker 一键部署栈，集中管理 PostgreSQL / Redis / Neo4j / Milvus / MinIO 及 FastAPI 应用。

## 目录结构

```
my_assistant/
├── docker-compose.yml              # 全栈（数据服务 + FastAPI）
├── docker-compose.data.yml         # 仅 4 个数据库
├── docker-compose.milvus.yml       # Milvus standalone 单容器版
├── Dockerfile                      # FastAPI 镜像构建
├── env.example                     # 凭证模板
├── scripts/
│   └── backup_restore/             # Milvus 备份恢复脚本
│       ├── export_milvus.py        #   逐 collection JSONL 导出
│       └── restore_milvus.py       #   从 JSONL 恢复 collection
└── README.md
```

## 启动顺序

```bash
# 1) 数据服务
docker compose -f docker-compose.data.yml up -d

# 2) FastAPI 应用
docker compose up -d
```

| 服务 | 端口 | 凭证 |
|------|------|------|
| PostgreSQL | 5432 | postgres / postgres123 |
| Redis | 6379 | redis123 |
| Neo4j HTTP | 7474 | neo4j / neo4j123 |
| Neo4j Bolt | 7687 | neo4j / neo4j123 |
| Milvus | 19530 | 无 |
| Milvus Health | 9091 | 无 |
| MinIO | 9000 | minioadmin / minioadmin |
| FastAPI | 8000 | — |

## Milvus 备份 / 恢复

```bash
# 导出当前所有 collection 到 JSONL
python scripts/backup_restore/export_milvus.py \
  --host 127.0.0.1 --port 19530 \
  --backup-root /path/to/backup_root

# 从 JSONL 恢复（按 collection 子目录）
python scripts/backup_restore/restore_milvus.py \
  --backup-dir /path/to/backup_root/<timestamp> \
  --skip-existing
```

注意：
- 业务 collection 缺索引时 `query()` 会失败，请改用 volume 物理打包（见根目录 `scripts/infra/restore_volumes.sh`）。
- standalone 模式下 Milvus 元数据落在 etcd + minio 三个 volume 中。

## 与 my_assistant 应用源码的对应

`docker-compose.yml` 中 FastAPI 构建上下文指向 `~/Desktop/code/deve/drass/my_assistant(3)/my_assistant`，修改源码后：

```bash
docker compose build assistant
docker compose up -d assistant
```

## 资源建议

| 服务 | 最低 | 推荐（导入大集合） |
|------|------|-------------------|
| Milvus | 8 GB | 16-24 GB |
| Neo4j | 4 GB | 8 GB |
| PostgreSQL | 512 MB | 2 GB |
| Redis | 256 MB | 1 GB |
| FastAPI | 2 GB | 4 GB |