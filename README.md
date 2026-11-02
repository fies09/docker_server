# Docker Server - 多项目基础设施

personal_ai / my_assistant / langfuse 共享的基础设施编排仓库。

## 目录结构

```
docker_server/
├── infra/                       # 统一基础设施栈 (name: infra) — 唯一入口
│   ├── docker-compose.yml       # 8 服务: redis/postgres/etcd/minio/milvus/neo4j/ollama/attu
│   ├── .env / .env.example      # 凭证与端口
│   ├── docker.sh                # 管理脚本 (up/down/ps/logs/restart/clean)
│   └── README.md
├── scripts/init-multiple-dbs.sh # Postgres 初始化脚本（被 infra 栈挂载）
├── personal_ai/                 # personal_ai 专属部署脚本（nginx 反代）
├── my_assistant/                # my_assistant 应用容器栈
├── langfuse/                    # langfuse submodule
├── milvus/                      # Milvus 数据目录（volumes/ 已 gitignore）
├── nginx/                       # 通用 TLS 反代
└── 数据库数据备份/               # 物理备份归档目录（当前为空）
```

## 快速启动

```bash
cd infra/
./docker.sh up          # 全部启动（8 服务）
./docker.sh up-milvus   # 仅 Milvus 三件套
./docker.sh ps          # 状态
./docker.sh down        # 停止（保留数据）
./docker.sh clean       # 停止 + 删除数据卷（危险）
```

## 服务与端口

| 服务 | 容器 | 端口 | 凭证 |
|------|------|------|------|
| Redis | infra-redis | 6379 | redis123 |
| PostgreSQL + pgvector | infra-postgres | 5432 | postgres / postgres123 |
| Milvus | milvus-standalone | 19530 / 9091 | — |
| MinIO | milvus-minio | 9000 / 9001 | minioadmin / minioadmin |
| Neo4j | infra-neo4j | 7474 / 7687 | neo4j / neo4j123 |
| Ollama | infra-ollama | 11434 | — |
| Attu | milvus-attu | 30000 | — |
| etcd | milvus-etcd | 2379（仅内网） | — |

多项目数据隔离：PostgreSQL 多库（personal_ai_db / my_assistant_db），Redis key 前缀（pa:* / ma:*），Milvus collection 前缀，Neo4j 标签区分。

## 资源配额

按本机实际配置标定（Apple M5 / 10 核 / 32GB，OrbStack VM 内存上限 ~15.7GiB）。
`deploy.resources.limits` 是**上限而非预留**，全栈实测常驻约 4GiB：

| 服务 | cpus | memory |
|------|------|--------|
| redis | 1 | 1G |
| postgres | 2 | 2G |
| neo4j | 2 | 3G |
| ollama | 4 | 9G |
| milvus-etcd | 1 | 512M |
| milvus-minio | 1 | 1G |
| milvus-standalone | 4 | 4G |
| milvus-attu | 0.5 | 512M |

ollama 9GiB 承载 `bge-m3`（1.2GB 嵌入）+ `qwen3.5:9b`（~6.6GB 对话）。8B 级以上模型超出 VM 内存预算，本机不部署。

## Ollama 模型

```bash
docker exec infra-ollama ollama list
docker exec infra-ollama ollama pull qwen3.5:9b
```

仅保留 `qwen3.5:9b`（personal_ai `.env` 指定的默认对话模型）与 `bge-m3`（嵌入）。

## 备份与恢复

物理备份归档目录 `数据库数据备份/` 当前为空（历史归档已不在本机）。
如需恢复，请先确认归档实际存放位置；恢复为手动操作：停对应容器 → 把归档目录内容拷回对应 volume / bind 目录 → 重新起容器。

## 与各项目的关系

- **personal_ai**: 通过 localhost 标准端口接入 infra 栈；PM2 托管前后端（源码在 `~/Desktop/code/python/personal_ai`），nginx 反代配置在 `personal_ai/`
- **my_assistant**: 应用容器在 `my_assistant/`，数据服务统一走 infra 栈（`host.docker.internal` 直连）
- **langfuse**: submodule，独立编排；控制台经 personal_ai 的 i18n 中文代理暴露在宿主 `127.0.0.1:3005`
