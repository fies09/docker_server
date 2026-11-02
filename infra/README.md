# Infra - 统一基础设施

`personal_ai` / `my_assistant` / 其他项目共享的基础设施栈：`name: infra`。

## 服务

| 服务 | 容器 | 端口 | 用途 |
|------|------|------|------|
| Redis | infra-redis | 6379 | 缓存 / 会话 |
| PostgreSQL + pgvector | infra-postgres | 5432 | 关系库 + 向量 |
| etcd | milvus-etcd | 2379（仅内网） | Milvus 元数据 |
| MinIO | milvus-minio | 9000 / 9001 | 对象存储 |
| Milvus | milvus-standalone | 19530 / 9091 | 向量数据库 |
| Neo4j | infra-neo4j | 7474 / 7687 | 图数据库 |
| Ollama | infra-ollama | 11434 | 本地大模型 |
| Attu | milvus-attu | 30000 | Milvus GUI |

## 启动

```bash
cd infra/
cp .env.example .env  # 按需改密码
./docker.sh up        # 全部启动
./docker.sh up-milvus # 仅 Milvus 三件套
```

## 维护

```bash
./docker.sh ps       # 查看状态
./docker.sh logs neo4j
./docker.sh restart
./docker.sh down     # 停止 (保留卷)
./docker.sh clean    # 停止 + 删卷 (危险)
```

## 资源配额

按本机实际配置标定（Apple M5 / 10 核 / 32GB，OrbStack VM 内存上限 ~15.7GiB）。
`limits` 是上限而非预留，全栈实测常驻约 4GiB：

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

## 数据卷 (name: infra 前缀)

命名卷：`infra_redis-data` / `infra_postgres-data` / `infra_neo4j-data` / `infra_neo4j-logs` / `infra_ollama-data`。

Milvus 三件套沿用旧独立编排的 bind 目录（数据在 `../milvus/volumes/`，不可改命名，否则 minio 数据会丢）：

| 服务 | bind 目录 |
|------|-----------|
| milvus-etcd | `../milvus/volumes/etcd` |
| milvus-minio | `../milvus/volumes/minio` |
| milvus-standalone | `../milvus/volumes/milvus` |

网络：`infra_infra-network` (bridge)。

## 集成

各项目通过标准端口连接 `localhost:5432` / `6379` / `19530` / `7687` / `11434` / `30000`，无需进入容器网络。
