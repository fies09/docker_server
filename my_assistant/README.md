# my_assistant - 智能助手 Docker 部署栈

my_assistant 项目的 FastAPI 应用容器编排。**数据服务统一由父目录 `infra/` 栈提供**，本目录只编排应用容器。

## 目录结构

```
my_assistant/
├── docker-compose.yml              # FastAPI 应用容器（连 host.docker.internal）
├── docker-compose.data.yml         # 数据服务模板（ma-*，备用，未启动）
├── docker-compose.milvus.yml       # Milvus 三件套独立栈（备用，未启动）
├── docker.sh                       # 应用容器一键管理脚本 ⭐
├── env.example                     # 凭证 + 端口模板（备用模板，无需 .env）
├── scripts/
│   └── backup_restore/             # PG/Redis/Neo4j/Milvus 备份脚本
└── README.md
```

## 快速启动（推荐）

数据服务已由 `infra/` 栈提供，应用容器只需：

```bash
cd /Users/fanyong/Desktop/code/python/docker_server/my_assistant

# 首次或源码改动大时
./docker.sh up

# 日常源码改动
./docker.sh rebuild

# 查看日志 / 状态 / 重启
./docker.sh logs 100
./docker.sh ps
./docker.sh restart
```

数据服务若未启动，先启动：

```bash
cd /Users/fanyong/Desktop/code/python/docker_server/infra
./docker.sh up
```

## 命令一览

| 命令 | 作用 |
|------|------|
| `./docker.sh up` | 构建并后台启动 my-assistant |
| `./docker.sh build` | 强制重建镜像（`--no-cache`，依赖或 Dockerfile 改动后） |
| `./docker.sh rebuild` | 增量重建 + 重启（常规源码改动） |
| `./docker.sh down` | 停止应用容器（保留数据卷） |
| `./docker.sh restart` | 重启应用容器 |
| `./docker.sh ps` | 应用 + infra 服务合并状态 |
| `./docker.sh logs [N]` | 应用日志（默认 50 行） |
| `./docker.sh status` | 应用健康检查（`/docs`） |
| `./docker.sh shell` | 进入应用容器 bash |
| `./docker.sh clean` | 删除容器 + 镜像（需确认） |
| `./docker.sh -h` | 帮助 |

## 端口与凭证（当前运行中）

| 服务 | 容器名 | 主机端口 | 来源 | 凭证 |
|------|--------|----------|------|------|
| PostgreSQL | infra-postgres | 5432 | infra 栈 | postgres / postgres123 |
| Redis | infra-redis | 6379 | infra 栈 | redis123 |
| Neo4j HTTP / Bolt | infra-neo4j | 7474 / 7687 | infra 栈 | neo4j / neo4j123 |
| Milvus | infra-milvus | 19530 | infra 栈 | — |
| Milvus Health | infra-milvus | 9091 | infra 栈 | — |
| MinIO API | infra-minio | 9000 | infra 栈 | minioadmin / minioadmin |
| MinIO Console | infra-minio | 9001 | infra 栈 | minioadmin / minioadmin |
| Attu | infra-attu | 8001 | infra 栈 | — |
| Ollama | infra-ollama | 11434 | infra 栈 | — |
| Langfuse | langfuse-langfuse-web-1 | 3000 | langfuse 栈 | 见 langfuse/ |
| **FastAPI** | **my-assistant** | **8000** | **本栈** | — |

## 网络架构

```
+--------------------+        host.docker.internal       +------------------------+
| my-assistant       |  ─────────────────────────────>  | infra-* 数据服务       |
| (FastAPI)          |  <───────────────────────────── | (主机端口已暴露)        |
+--------------------+                                  +------------------------+
       │                                                       │
       └── docker compose 默认网络 ──┐                         │
                                     ▼                         │
                          (host-gateway) ←───────┬─ Mac 主机 ──┘
```

应用容器使用 `host.docker.internal` 直连主机的 infra-* 服务端口，不参与 infra 栈内部网络。Docker Desktop Mac 自动注入 `host.docker.internal`，compose 文件额外显式声明 `extra_hosts` 作为保险。

## 备用部署模式

如需独立部署（不依赖 infra 栈），改用：

```bash
# 数据服务（自包含 ma-* 前缀）
docker compose -f docker-compose.data.yml up -d

# 应用容器（需修改 compose 文件内服务名指向 ma-* 容器）
docker compose up -d assistant
```

> 该模式会造成与 infra 栈端口冲突，通常不推荐使用。`docker-compose.data.yml` 与 `docker-compose.milvus.yml` 仅作配置模板保留。

## 备份与恢复

```bash
cd /Users/fanyong/Desktop/code/python/docker_server/my_assistant

# PostgreSQL pg_dump 逻辑备份
python scripts/backup_restore/backup_postgres.py

# Redis RDB 快照
python scripts/backup_restore/backup_redis.py

# Neo4j 离线二进制 dump（推荐，停容器 → neo4j-admin dump → 自动重启）
python scripts/backup_restore/backup_neo4j.py dump

# Neo4j 在线 Cypher 逻辑导出（不推荐）
python scripts/backup_restore/backup_neo4j.py dump --online

# Milvus 逐 collection JSONL 导出
python scripts/backup_restore/export_milvus.py --host 127.0.0.1 --port 19530

# Milvus 从 JSONL 恢复
python scripts/backup_restore/restore_milvus.py \
  --backup-dir /path/to/backup_root/<timestamp> \
  --skip-existing
```

默认备份根目录：`/Users/fanyong/Desktop/code/python/docker_server/database_backups`

> 注意：Milvus standalone 元数据落在 etcd + minio 两个 volume 中。业务 collection 缺索引时 `query()` 会失败，可改用 volume 物理打包。

## 与 my_assistant 应用源码的对应

`docker-compose.yml` FastAPI 构建上下文指向 `~/Desktop/code/deve/drass/my_assistant`，Dockerfile 在项目根。源码改动后：

```bash
./docker.sh rebuild    # 推荐，等价于 build + restart
```

## 资源建议（应用容器）

| 服务 | 最低 | 推荐（导入大集合） |
|------|------|-------------------|
| FastAPI | 2 GB | 4 GB |
| Milvus (infra) | 8 GB | 16-24 GB（调 `MILVUS_MEMORY_LIMIT`） |
| Neo4j (infra) | 2 GB | 4 GB |
| PostgreSQL (infra) | 512 MB | 2 GB |
| Redis (infra) | 256 MB | 1 GB |

## 与父目录 docker_server 的关系

- 父目录 `docker_server/infra/` 提供 8 个共享数据服务（`infra-*` 前缀，name=infra），运行中
- 父目录 `docker_server/langfuse/` 提供 LLM 可观测性栈（langfuse-*），运行中
- 本目录仅编排 `my-assistant` 应用容器，连入 infra 栈（通过主机端口）
