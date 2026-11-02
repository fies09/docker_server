# personal_ai 部署资源

docker_server 为 personal_ai 提供站点部署脚本与 Docker 资源，应用源码位于 `/Users/fanyong/Desktop/code/python/personal_ai/`。

## 目录结构

```
personal_ai/
├── deploy-nginx.sh                 # Nginx 站点部署
├── nginx.conf                      # Nginx 站点配置（被 deploy-nginx.sh 引用）
├── frontend/                       # 前端 Docker 资源
│   ├── Dockerfile.apk              # RN Android APK 构建镜像
│   └── .dockerignore
└── scripts/
    ├── export_neo4j.py             # Neo4j → JSONL
    └── import_neo4j.py             # JSONL → Neo4j
```

> PM2 编排（`deploy-pm2.sh` / `ecosystem.config.js`）与 Neo4j volume 级恢复（`restore_neo4j.sh`）随
> 应用源码仓库维护，不在本编排目录内。旧副本已删除 —— 两处副本会导致 `pm2` 指向错误的工作目录。

## 服务拆分

| 栈 | 路径 | 服务 |
|----|------|------|
| 共享基础设施 | `../infra/` | PG / Redis / Neo4j / Ollama / Milvus 三件套（etcd/minio/standalone）/ Attu |

personal_ai 不持有独立 Docker 栈：Milvus 三件套已并入 infra 栈（服务名 `milvus-*`），与 PG/Redis/Neo4j/Ollama
共用同一份数据目录与端口（19530 / 9091 / 9000 / 9001 / 30000）。

## 部署

```bash
# 1) 共享基础设施（含 Milvus 三件套，一次性，多项目共享）
cd ../infra && ./docker.sh up
cd ../infra && ./docker.sh ps

# 2) 前端 APK 构建
docker build -f frontend/Dockerfile.apk \
    -t personal-ai-apk \
    /Users/fanyong/Desktop/code/python/personal_ai/frontend

# 3) 进程托管 + 站点反代（不依赖 Docker 编排）
bash /Users/fanyong/Desktop/code/python/personal_ai/deploy-pm2.sh start
bash deploy-nginx.sh
```

PG 多库初始化（personal_ai_db / my_assistant_db）由 `../scripts/init-multiple-dbs.sh` 在 `infra-postgres` 首次启动时执行。

## Milvus 恢复

Milvus 三件套（`milvus-etcd` / `milvus-minio` / `milvus-standalone`）在 infra 栈内，启动顺序敏感，
三件之一崩溃会导致 `localhost:19530` 连接失败。症状：后端日志出现
`Milvus 初始化失败: ...illegal connection params`，`docker.sh ps` 中任一组件显示 `Exited`。

```bash
cd ../infra
./docker.sh ps                                # 查看哪些容器 Exited
./docker.sh logs milvus-standalone            # 查看崩溃原因（OOM 137、etcd 连接断开、磁盘满）
./docker.sh up                                # 重新拉起全部
lsof -nP -iTCP:19530 -sTCP:LISTEN              # 验证端口
```

如需仅启动三件套：`./docker.sh up milvus-standalone`（依赖 etcd/minio 健康检查自动满足）。

常见根因：

| 现象 | 根因 | 处理 |
|------|------|------|
| `milvus-standalone Exited (1)`，日志 `Data Node disconnected from etcd` | etcd 重启导致会话丢失 | `./docker.sh up`，etcd/minio 数据不动，仅重建会话 |
| `milvus-standalone Exited (137)` | OOM killed | 调高 `../infra/docker-compose.yml` 中该服务的 `memory` limit 后重启 |
| `milvus-standalone Exited (1)` + `milvus-minio Exited (0)` | minio 数据目录权限错乱 | 修复 `../milvus/volumes/minio` 属主后重启（**动数据前先备份 minio 数据**） |
| `milvus-standalone` 起来后秒退 (255) | minio 健康检查未就绪 | 等 30s 后 `./docker.sh restart milvus-standalone` |
| `Bind for 0.0.0.0:9000 failed: port is already allocated` | 有第二份 Milvus 编排在抢端口 | 检查是否存在非 infra 的 compose 副本，已删除的 `personal_ai/docker-compose.yml` 即此类 |

## PM2 启动

前后端通过 PM2 一键编排，无需 Docker（应用源码直跑）。

| 进程名 | 端口 | 启动命令 | 工作目录 |
|--------|------|----------|----------|
| `personal-ai-backend` | 8008 | `uvicorn app.main:app --host 0.0.0.0 --port 8008` | `personal_ai/` |
| `personal-ai-frontend` | 3001（dev）/ 3000（prod） | `next dev -p 3001` / `next start -p 3000` | `personal_ai/frontend/` |

```bash
cd /Users/fanyong/Desktop/code/python/personal_ai

# 一键启动（自动构建前端 + startOrReload）
bash deploy-pm2.sh start

# 日常管理
bash deploy-pm2.sh status    # pm2 status
bash deploy-pm2.sh logs      # pm2 logs（实时）
bash deploy-pm2.sh restart   # 重启
bash deploy-pm2.sh stop      # 停
bash deploy-pm2.sh delete    # 删

# 日志文件（PM2 out_file/error_file 指向源码仓库）
tail -f /Users/fanyong/Desktop/code/python/personal_ai/logs/pm2/personal-ai-backend-out.log
tail -f /Users/fanyong/Desktop/code/python/personal_ai/logs/pm2/personal-ai-frontend-error.log
```

配置位置：`/Users/fanyong/Desktop/code/python/personal_ai/ecosystem.config.js`（两个 app：`personal-ai-backend` / `personal-ai-frontend`）。
为何不用 `docker-compose`：见 `docs/decisions/ADR-016-pm2-orchestration.md`。

### 热重载

- **后端**：dev 模式下 uvicorn 带 `--reload --reload-dir app --reload-include *.py`；PM2 `watch: false`，避免进程级重启与代码级 reload 叠加。
- **前端**：`personal-ai-frontend` 走 `next dev`，Fast Refresh 自带 HMR。

> `nginx.conf` 的 frontend upstream 同时列出 3001（dev，主）与 3000（prod，backup），两种模式都能反代。

## Neo4j 备份 / 恢复

```bash
python scripts/export_neo4j.py
python scripts/import_neo4j.py nodes_xxx.jsonl relationships_xxx.jsonl
```

凭据：`bolt://localhost:7687`，`neo4j / neo4j123`（infra 默认）。
