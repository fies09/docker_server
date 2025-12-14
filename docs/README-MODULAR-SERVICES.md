# 模块化服务部署指南

本项目已经完成模块化改造，每个服务都可以独立部署和管理。

## 快速开始

### 使用便捷脚本（推荐）

```bash
# 启动 Neo4j
./start-service.sh neo4j

# 启动多个服务
./start-service.sh mysql redis neo4j

# 启动所有服务
./start-service.sh all

# 停止服务
./stop-service.sh neo4j
./stop-service.sh all
```

### 手动使用 docker-compose

```bash
# 启动特定服务（重要：必须使用 --no-build）
docker-compose -f docker-compose.neo4j.yml up -d --no-build

# 停止服务
docker-compose -f docker-compose.neo4j.yml down

# 查看日志
docker-compose -f docker-compose.neo4j.yml logs -f

# 查看服务状态
docker ps | grep neo4j
docker inspect neo4j --format='{{.State.Health.Status}}'
```

## 可用服务列表

| 服务 | Compose 文件 | 端口 | 说明 |
|------|-------------|------|------|
| MySQL | docker-compose.mysql.yml | 3306 | MySQL 数据库 |
| PostgreSQL | docker-compose.postgresql.yml | 5432 | PostgreSQL 数据库 |
| Redis | docker-compose.redis.yml | 6379 | Redis 缓存 |
| RabbitMQ | docker-compose.rabbitmq.yml | 5672, 15672 | 消息队列 |
| Nginx | docker-compose.nginx.yml | 8080, 8443 | 反向代理 |
| Neo4j | docker-compose.neo4j.yml | 7474, 7687 | 图数据库 |
| Flask App | docker-compose.build.yml | 8000 | Python 应用 |

## Neo4j 特别说明

### 版本和插件
- **版本**: 5.15.0
- **预装插件**: APOC, Graph Data Science
- **内存配置**: 1G pagecache, 2G heap

### 访问地址
- **Neo4j Browser**: http://localhost:7474
- **Bolt 协议**: bolt://localhost:7687

### 认证信息
在 `.env` 文件中配置：
```bash
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_password
```

### 数据持久化
数据保存在以下 Docker volumes：
- `neo4j-data`: 数据库数据
- `neo4j-logs`: 日志文件
- `neo4j-import`: 导入文件目录
- `neo4j-plugins`: 插件目录

## 网络说明

所有服务连接到 `app-network` 桥接网络，容器之间可以通过服务名互相访问：

```python
# 在 Flask 应用中连接其他服务
MYSQL_HOST = "mysql"
REDIS_HOST = "redis"
NEO4J_URI = "bolt://neo4j:7687"
```

## 故障排查

### 问题：docker-compose 报网络错误

**解决方案**: 使用 `--no-build` 参数
```bash
docker-compose -f docker-compose.neo4j.yml up -d --no-build
```

或使用提供的脚本：
```bash
./start-service.sh neo4j
```

### 问题：需要拉取新镜像

**解决方案**: 手动拉取镜像
```bash
# 直接拉取（会尝试使用配置的镜像源）
docker pull neo4j:5.15.0

# 然后启动服务
./start-service.sh neo4j
```

### 问题：检查服务健康状态

```bash
# 查看健康状态
docker inspect neo4j --format='{{.State.Health.Status}}'

# 查看完整状态
docker ps | grep neo4j

# 查看日志
docker logs neo4j --tail 50
```

## 清理资源

```bash
# 停止并删除特定服务
./stop-service.sh neo4j

# 停止所有服务
./stop-service.sh all

# 删除未使用的卷和网络
docker system prune -a --volumes
```

## 环境配置

复制 `.env.example` 到 `.env` 并配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件，设置所有服务的密码和配置。

## 更多信息

详细文档请查看 `CLAUDE.md` 文件。
