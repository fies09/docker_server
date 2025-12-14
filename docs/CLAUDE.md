# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker-based multi-service development environment with a Flask application and supporting infrastructure services. The repository is optimized for development in China with mirror sources configured for faster builds. All services are modularized to support independent deployment.

## Core Architecture

### Flask Application (app.py)
Simple Python 3.11 Flask API with three endpoints:
- `/` - Returns app info, version (1.0.0), and current timestamp
- `/health` - Health check endpoint (used by Docker healthcheck)
- `/info` - Returns Python version, hostname, and environment

Environment variables:
- `PORT` - Server port (default: 8000)
- `DEBUG` - Debug mode (default: False)
- `ENVIRONMENT` - Environment name (default: development)

### Modular Docker Compose Architecture
Services are split into independent compose files for flexible deployment:

**docker-compose.build.yml** - Python application:
- Builds from local Dockerfile
- Pushes to Aliyun container registry: `crpi-srv542vpdq3agniz.cn-chengdu.personal.cr.aliyuncs.com/personal_ai_dev/python-app:python3.11`
- Includes healthcheck using `/health` endpoint
- Uses `restart: unless-stopped` policy

**docker-compose.mysql.yml** - MySQL database:
- Port 3306
- Persistent volume for data
- Backup directory mounted at /backup

**docker-compose.postgresql.yml** - PostgreSQL database:
- Port 5432
- Persistent volume for data

**docker-compose.redis.yml** - Redis cache:
- Port 6379
- Password authentication via redis.conf
- Persistent volume for data

**docker-compose.rabbitmq.yml** - RabbitMQ message queue:
- Ports 5672 (AMQP), 15672 (Management UI)
- Persistent volume for data

**docker-compose.nginx.yml** - Nginx reverse proxy:
- Ports 8080 (HTTP), 8443 (HTTPS)
- SSL certificate support

**docker-compose.neo4j.yml** - Neo4j graph database:
- Ports 7474 (HTTP), 7687 (Bolt)
- Pre-installed plugins: APOC, Graph Data Science
- Memory: 1G pagecache, 2G heap
- Persistent volumes for data, logs, imports, and plugins

**docker-compose.yml** - Legacy all-in-one infrastructure stack (deprecated):
- Contains all infrastructure services in one file
- Recommend using modular files instead for better flexibility

All services share the `app-network` bridge network for inter-service communication.

### Dockerfile Details
- Base image: python:3.11-slim with Chinese mirror sources (Aliyun for apt, Tsinghua for pip)
- Installs system dependencies: gcc, g++, libpq-dev, curl
- Runs as non-root user `app` for security
- Built-in healthcheck at `/health` endpoint
- Exposes port 8000

## Common Commands

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run Flask app locally
python app.py

# Run with debug mode
DEBUG=true python app.py
```

### Modular Service Deployment (推荐使用脚本)

**使用便捷脚本:**
```bash
# 启动单个或多个服务
./start-service.sh neo4j
./start-service.sh mysql redis neo4j
./start-service.sh all

# 停止服务
./stop-service.sh neo4j
./stop-service.sh all
```

**手动使用 docker-compose:**
```bash
# 启动特定服务 (必须使用 --no-build 避免网络问题)
docker-compose -f docker-compose.mysql.yml up -d --no-build
docker-compose -f docker-compose.postgresql.yml up -d --no-build
docker-compose -f docker-compose.redis.yml up -d --no-build
docker-compose -f docker-compose.rabbitmq.yml up -d --no-build
docker-compose -f docker-compose.nginx.yml up -d --no-build
docker-compose -f docker-compose.neo4j.yml up -d --no-build
docker-compose -f docker-compose.build.yml up -d --build

# 停止特定服务
docker-compose -f docker-compose.mysql.yml down
docker-compose -f docker-compose.neo4j.yml down

# 启动多个服务
docker-compose -f docker-compose.mysql.yml -f docker-compose.redis.yml up -d --no-build

# 查看日志
docker-compose -f docker-compose.mysql.yml logs -f

# 重新构建并启动
docker-compose -f docker-compose.build.yml up -d --build --force-recreate
```

### Legacy All-in-One Deployment
```bash
# Start all infrastructure services (not recommended)
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service-name]
```

### Utility Commands
```bash
# View all running containers
docker ps -a

# Check service health
docker inspect --format='{{.State.Health.Status}}' <container-name>

# View networks
docker network ls

# View volumes
docker volume ls

# Clean up unused resources
docker system prune -a --volumes
```

### Building and Pushing Images
```bash
# Build and push to Aliyun registry (ARM64 architecture)
./build-multiplatform-offline.sh

# Login to Aliyun registry first (if needed)
docker login crpi-srv542vpdq3agniz.cn-chengdu.personal.cr.aliyuncs.com
```

## Environment Configuration

Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

Required environment variables:
- `MYSQL_PASSWORD` - MySQL root password
- `MYSQL_DATABASE` - MySQL database name
- `POSTGRES_USER` - PostgreSQL username
- `POSTGRES_PASSWORD` - PostgreSQL password
- `POSTGRES_DB` - PostgreSQL database name
- `RABBITMQ_USER` - RabbitMQ username
- `RABBITMQ_PASSWORD` - RabbitMQ password
- `REDIS_PASSWORD` - Redis password (configured in redis.conf)
- `NEO4J_USER` - Neo4j username (default: neo4j)
- `NEO4J_PASSWORD` - Neo4j password

## Service Access

- Flask Application: http://localhost:8000
- Nginx: http://localhost:8080 (HTTP), https://localhost:8443 (HTTPS)
- MySQL: localhost:3306
- PostgreSQL: localhost:5432
- Redis: localhost:6379 (requires password)
- RabbitMQ AMQP: localhost:5672
- RabbitMQ Management UI: http://localhost:15672
- Neo4j Browser: http://localhost:7474
- Neo4j Bolt: bolt://localhost:7687

## Important Notes

- All services use Chinese mirror sources for faster downloads
- Each service can be deployed independently using its dedicated compose file
- All services share the `app-network` bridge network, enabling communication between containers
- **重要**: 使用 `docker-compose up` 时必须添加 `--no-build` 参数避免网络拉取问题，或使用提供的 `start-service.sh` 脚本
- The nginx.conf contains hardcoded paths for static/media files pointing to a Django project - these need updating if using with this Flask app
- Multi-platform builds require Docker Buildx or building on target architecture
- Current setup assumes ARM64 architecture (M1/M2 Mac)
- Neo4j comes with APOC and Graph Data Science plugins pre-configured (version 5.15.0)
- All services include health checks for monitoring container status
- 便捷脚本 `start-service.sh` 和 `stop-service.sh` 简化了服务管理