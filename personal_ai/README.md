# personal_ai 部署资源

docker_server 为 personal_ai 提供独立的部署脚本与 Docker 资源，应用源码位于 `/Users/fanyong/Desktop/code/python/personal_ai/`，本目录存放 personal_ai 专属的镜像构建、站点部署、数据备份脚本。

## 目录结构

```
personal_ai/
├── docker-compose.yml              # personal_ai 专属栈（Milvus 三件套 + Attu）
├── .env                            # Milvus 三件套环境变量
├── deploy-nginx.sh                 # Nginx 站点部署
├── deploy-pm2.sh                   # PM2 进程托管部署
├── ecosystem.config.js             # PM2 配置
├── nginx.conf                      # Nginx 站点配置（被 deploy-nginx.sh 引用）
├── backend/                        # 后端 Docker 忽略规则
│   └── .dockerignore
├── frontend/                       # 前端 Docker 资源
│   ├── Dockerfile.apk              # RN Android APK 构建镜像
│   └── .dockerignore
└── scripts/
    ├── export_neo4j.py             # Neo4j → JSONL
    ├── import_neo4j.py             # JSONL → Neo4j
    ├── restore_neo4j.sh            # Neo4j volume 级恢复
    └── neo4j_export/               # 导出产物（.gitignore）
```

## 服务拆分

| 栈 | 路径 | 服务 |
|----|------|------|
| 共享基础设施 | `../infra/` | PG / Redis / Neo4j / Ollama / MinIO（个人 KB 库）/ Attu（KB 库） |
| personal_ai 专属 | `./` | Milvus（chat_memory 集合） + Etcd + MinIO + Attu |

Milvus 三件套与 PG/Redis/Neo4j/Ollama 解耦，单独容器命名空间 `personal-ai-*`，与 infra 栈容器名 `infra-*` 隔离，可独立升级/迁移。

## 部署

```bash
# 1) 共享基础设施（一次性，多项目共享）
cd ../infra && ./docker.sh up

# 2) personal_ai 专属栈（Milvus 三件套 + Attu）
cd .   # 当前目录即为 personal_ai/
docker compose --env-file .env -f docker-compose.yml up -d
docker compose -f docker-compose.yml ps

# 3) 前端 APK 构建
docker build -f frontend/Dockerfile.apk \
    -t personal-ai-apk \
    /Users/fanyong/Desktop/code/python/personal_ai/frontend

# 4) 进程托管（不依赖 Docker 编排）
bash deploy-pm2.sh
bash deploy-nginx.sh
```

PG 多库初始化（personal_ai_db / my_assistant_db / langfuse_db）由 `../infra/../scripts/init-multiple-dbs.sh` 在 `infra-postgres` 首次启动时执行，无需单独 Dockerfile。

## Milvus 恢复

Milvus 三件套（etcd/minio/milvus）启动顺序敏感，三件之一崩溃会导致 `localhost:19530`
连接失败。症状：后端日志出现 `Milvus 初始化失败: ...illegal connection params`，
`docker compose ps` 中任一组件显示 `Exited`。

```bash
docker compose ps                                # 查看哪些容器 Exited
docker compose logs milvus                       # 查看崩溃原因（OOM 137、端口占用、磁盘满）
docker compose up -d                             # 重新拉起全部
lsof -nP -iTCP:19530 -sTCP:LISTEN                # 验证端口
```

如需仅启动三件套：`docker compose up -d etcd minio milvus`。

常见根因：

| 现象 | 根因 | 处理 |
|------|------|------|
| `personal-ai-etcd Exited (137)` | OOM killed，1GiB 限制偏低 | compose 中已升至 2GiB，重启即可 |
| `personal-ai-minio Exited (0)` 但 milvus 起不来 | minio volume 权限错乱 | `docker volume rm personal-ai_minio-data` 后重建（**会丢数据**） |
| milvus 起来后秒退 (255) | minio 健康检查未就绪 | 等 30s 后 `docker compose restart milvus` |

## Neo4j 备份 / 恢复

```bash
python scripts/export_neo4j.py
python scripts/import_neo4j.py nodes_xxx.jsonl relationships_xxx.jsonl
bash scripts/restore_neo4j.sh
```

凭据：`bolt://localhost:7687`，`neo4j / neo4j123`（infra 默认）。