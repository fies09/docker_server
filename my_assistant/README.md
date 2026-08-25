# 基础设施一键部署

集中管理 PostgreSQL / Redis / Neo4j / Milvus 四个数据服务，以及可选的 FastAPI 智能助手服务。

## 目录结构

```
infra/
├── docker-compose.yml          # 全栈（数据服务 + FastAPI）
├── docker-compose.data.yml     # 仅 4 个数据库
├── env.example                 # 凭证模板
└── README.md                   # 本文件
```

## 快速开始

### 仅启动数据服务

```bash
cd infra
docker compose -f docker-compose.data.yml up -d

# 检查状态
docker compose -f docker-compose.data.yml ps
docker ps
```

启动后端口占用：

| 服务 | 端口 | 凭证 |
|------|------|------|
| PostgreSQL | 5432 | postgres / postgres123 |
| Redis | 6379 | 密码 redis123 |
| Neo4j HTTP | 7474 | neo4j / neo4j123 |
| Neo4j Bolt | 7687 | neo4j / neo4j123 |
| Milvus | 19530 | 无 |
| Milvus Health | 9091 | 无 |
| MinIO | 9000 | minioadmin / minioadmin |

### 启动全栈（数据服务 + FastAPI）

```bash
cd infra
# 先启动数据服务
docker compose -f docker-compose.data.yml up -d
# 再启动 FastAPI
docker compose up -d

# 检查
docker compose ps
```

FastAPI 端口：`8000`，访问 `http://localhost:8000/docs`。

## 数据导入

启动服务后，使用项目内的 `scripts/backup_restore/` 脚本：

```bash
# 假设备份包解压到 /path/to/full_backup_20260824_104240
cd /path/to/project
python3 scripts/backup_restore/import_all.py /path/to/full_backup_20260824_104240
```

详细参数见 `scripts/backup_restore/README.md`。

## 资源建议

| 服务 | 最低 | 推荐（导入大集合） |
|------|------|-------------------|
| Milvus | 8 GB | 16-24 GB |
| Neo4j | 4 GB | 8 GB |
| PostgreSQL | 512 MB | 2 GB |
| Redis | 256 MB | 1 GB |
| FastAPI | 2 GB | 4 GB |

调整方式：编辑 `docker-compose.data.yml` 中 `deploy.resources.limits.memory`，或运行时 `docker update --memory 16g infra-milvus`。

## 持久化数据位置

| 卷名 | 用途 |
|------|------|
| postgres-data | PG 数据库文件 |
| redis-data | Redis RDB |
| neo4j-data | Neo4j 节点/关系 |
| neo4j-logs | Neo4j 日志 |
| etcd-data | Milvus 元数据 |
| minio-data | Milvus 对象存储 |
| milvus-data | Milvus 向量数据 |

查看：`docker volume ls`

清理（⚠️ 会删除所有数据）：
```bash
docker compose -f docker-compose.data.yml down -v
```

## 故障排查

### 端口冲突

```bash
# 查找占用端口的进程
lsof -i :5432   # PG
lsof -i :7687   # Neo4j
lsof -i :19530  # Milvus
```

### Milvus 启动失败

依赖 `etcd` + `minio`，查看日志：
```bash
docker logs infra-etcd
docker logs infra-minio
docker logs infra-milvus
```

### Neo4j 内存不足

调整 `NEO4J_dbms_memory_heap_max__size` 环境变量。

### PostgreSQL 中文/字符集问题

初始化数据库时加 `POSTGRES_INITDB_ARGS: --encoding=UTF8 --locale=C.UTF-8`。