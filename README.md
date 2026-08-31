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
├── scripts/infra/               # 基础设施维护脚本（备份恢复/迁移）
│   ├── restore_volumes.sh       # 一键恢复物理 volume 备份
│   ├── migrate-to-unified.sh    # 迁移脚本（已完成，仅参考）
│   ├── migrate-check.sh         # 迁移检查（已完成，仅参考）
│   └── docker.sh                # compose 命令封装（指向 infra/）
├── personal_ai/                 # personal_ai 专属部署脚本（nginx/pm2/neo4j备份）
├── my_assistant/                # my_assistant 自包含栈（ma-* 前缀，默认关闭）
├── langfuse/                    # langfuse submodule
├── milvus/                      # Milvus standalone 配置
├── docs/                        # 归档分析文档
├── backup/                      # 旧备份
└── 数据库数据备份/               # 物理备份归档 (20260821_volume_backup)
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
| Milvus | infra-milvus | 19530 / 9091 | — |
| MinIO | infra-minio | 9000 / 9001 | minioadmin / minioadmin |
| Neo4j | infra-neo4j | 7474 / 7687 | neo4j / neo4j123 |
| Ollama | infra-ollama | 11434 | — |
| Attu | infra-attu | 8001 | — |
| etcd | infra-etcd | 2379（仅内网） | — |

多项目数据隔离：PostgreSQL 多库（personal_ai_db / my_assistant_db / langfuse_db），Redis key 前缀（pa:* / ma:*），Milvus collection 前缀，Neo4j 标签区分。

## 备份与恢复

物理备份归档：`数据库数据备份/20260821_volume_backup/`（minio 2.5G / neo4j 475M / etcd 4.8M / postgres 70M）。

```bash
bash scripts/infra/restore_volumes.sh            # 一键恢复
bash scripts/infra/restore_volumes.sh /path/to/backup_dir
```

## 与各项目的关系

- **personal_ai**: 通过 localhost 标准端口接入 infra 栈；部署脚本在 `personal_ai/`
- **my_assistant**: 默认优先使用 `my_assistant/` 自包含栈（ma-*），infra 栈备用
- **langfuse**: submodule，连接 infra-postgres 的 langfuse_db
