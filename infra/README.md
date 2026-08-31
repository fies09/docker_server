# Infra - 统一基础设施

`personal_ai` / `my_assistant` / 其他项目共享的基础设施栈：`name: infra`。

## 服务

| 服务 | 容器 | 端口 | 用途 |
|------|------|------|------|
| Redis | infra-redis | 6379 | 缓存 / 会话 |
| PostgreSQL + pgvector | infra-postgres | 5432 | 关系库 + 向量 |
| etcd | infra-etcd | 2379 | Milvus 元数据 |
| MinIO | infra-minio | 9000 / 9001 | 对象存储 |
| Milvus | infra-milvus | 19530 / 9091 | 向量数据库 |
| Neo4j | infra-neo4j | 7474 / 7687 | 图数据库 |
| Ollama | infra-ollama | 11434 | 本地大模型 |
| Attu | infra-attu | 8001 | Milvus GUI |

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

## 数据卷 (name: infra 前缀)

`infra_redis-data` / `infra_postgres-data` / `infra_etcd-data` / `infra_minio-data` / `infra_milvus-data` / `infra_neo4j-data` / `infra_neo4j-logs` / `infra_ollama-data`。

网络：`infra_infra-network` (bridge)。

## 集成

各项目通过标准端口连接 `localhost:5432` / `6379` / `19530` / `7687` / `11434` / `8001`，无需进入容器网络。