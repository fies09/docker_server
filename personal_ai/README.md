# personal_ai 部署资源

docker_server 为 personal_ai 提供独立的部署脚本与 Docker 资源，应用源码位于 `/Users/fanyong/Desktop/code/python/personal_ai/`，本目录存放 personal_ai 专属的镜像构建、站点部署、数据备份脚本。

## 目录结构

```
personal_ai/
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

## 部署

```bash
# 1) 基础设施（一次性，多项目共享）
cd ../infra && ./docker.sh up

# 2) 前端 APK 构建
docker build -f frontend/Dockerfile.apk \
    -t personal-ai-apk \
    /Users/fanyong/Desktop/code/python/personal_ai/frontend

# 3) 进程托管（不依赖 Docker 编排）
bash deploy-pm2.sh
bash deploy-nginx.sh
```

PG 多库初始化（personal_ai_db / my_assistant_db / langfuse_db）由 `../infra/../scripts/init-multiple-dbs.sh` 在 `infra-postgres` 首次启动时执行，无需单独 Dockerfile。

## Neo4j 备份 / 恢复

```bash
python scripts/export_neo4j.py
python scripts/import_neo4j.py nodes_xxx.jsonl relationships_xxx.jsonl
bash scripts/restore_neo4j.sh
```

凭据：`bolt://localhost:7687`，`neo4j / neo4j123`（infra 默认）。