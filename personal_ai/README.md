# personal_ai 部署 - 智能知识库服务

docker_server 为 personal_ai 提供独立知识库服务（Milvus / PostgreSQL / Redis / Neo4j / MinIO / Ollama）。本目录存放 personal_ai 专属的部署与数据维护脚本。

## 目录结构

```
personal_ai/
├── deploy-nginx.sh                 # Nginx 部署
├── deploy-pm2.sh                   # PM2 进程托管部署
├── ecosystem.config.js             # PM2 配置
├── nginx.conf                      # Nginx 站点配置
├── redis.conf                      # Redis 自定义配置
├── Dockerfile                      # 应用镜像
├── init.sql                        # 初始化 SQL
└── scripts/
    ├── export_neo4j.py             # Neo4j 节点+关系 JSONL 导出
    ├── import_neo4j.py             # 从 JSONL 导入 Neo4j
    ├── restore_neo4j.sh            # Neo4j volume 级恢复
    └── neo4j_export/               # 导出产物（.gitignore）
```

## Neo4j 备份 / 恢复

```bash
# 导出（节点 + 关系 → neo4j_export/*.jsonl）
python scripts/export_neo4j.py

# 导入（从 JSONL 恢复到本地 Neo4j）
python scripts/import_neo4j.py nodes_xxx.jsonl relationships_xxx.jsonl

# volume 级恢复（停服→替换 volume 数据→启服）
bash scripts/restore_neo4j.sh
```

凭据：`bolt://localhost:7687`，`neo4j / 12345678`（personal_ai 本地默认）。

## 与根目录基础设施的关系

根目录 `docker-compose.unified.yml`（name: infra）提供统一基础设施，personal_ai 通过标准端口接入：

```bash
POSTGRES_HOST=localhost POSTGRES_PORT=5432
REDIS_HOST=localhost    REDIS_PORT=6379
MILVUS_HOST=localhost   MILVUS_PORT=19530
NEO4J_URI=bolt://localhost:7687
```

## 部署方式二选一

- **Docker Compose**：编辑根目录 compose 文件
- **PM2 + Nginx**：`bash deploy-pm2.sh && bash deploy-nginx.sh`