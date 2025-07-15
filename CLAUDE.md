# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker-based multi-service environment that includes a simple Flask application along with supporting infrastructure services. The main application is a basic Python Flask API with health check endpoints.

## Core Architecture

### Main Application
- **app.py**: Simple Flask application with three endpoints:
  - `/` - Main endpoint returning app info and timestamp
  - `/health` - Health check endpoint for monitoring
  - `/info` - System information endpoint
- **Runtime**: Python 3.11-slim based Docker container
- **Port**: Configurable via `PORT` environment variable (default: 8000)

### Infrastructure Services
The docker-compose.yml defines a complete development stack:
- **MySQL**: Database service on port 3306
- **PostgreSQL**: Alternative database on port 5432  
- **Redis**: Cache service on port 6379 with password authentication
- **RabbitMQ**: Message queue with management interface (ports 5672, 15672)
- **Nginx**: Reverse proxy with SSL termination on ports 80/443

### Docker Configuration
- **Dockerfile**: Multi-stage build using Python 3.11-slim with Chinese mirror sources for faster builds
- **docker-compose.build.yml**: Builds and runs the Python application container
- **docker-compose.yml**: Full infrastructure stack with persistent volumes

## Common Commands

### Application Development
```bash
# Run the Flask app locally
python app.py

# Install dependencies
pip install -r requirements.txt
```

### Docker Operations
```bash
# Start all infrastructure services
docker-compose up -d

# Build and start just the Python app
docker-compose -f docker-compose.build.yml up -d

# View running containers
docker ps -a

# Check service logs
docker-compose logs [service-name]
```

### Build and Deployment
```bash
# Build and push to Aliyun registry (requires login)
./build-and-push.sh [tag]

# Build with mirror optimization
./build-with-mirrors.sh

# Docker Compose build
./docker-compose-build.sh
```

### Backup Operations
```bash
# Manual MySQL backup
./mysql_backup.sh

# Docker images backup
./docker_backup.sh
```

## Environment Configuration

Create a `.env` file with these variables:
```
MYSQL_PASSWORD=root
MYSQL_DATABASE=mysql
POSTGRES_USER=root
POSTGRES_PASSWORD=root
POSTGRES_DB=postgres
RABBITMQ_USER=root
RABBITMQ_PASSWORD=root
REDIS_PASSWORD=root
```

## Service Access Points

- Flask App: http://localhost:8000
- Nginx Proxy: http://localhost:8080 (redirects to HTTPS)
- MySQL: localhost:3306
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- RabbitMQ Management: http://localhost:15672

## SSL Configuration

The Nginx service includes SSL configuration with:
- Certificate files: nginx.crt, nginx.key
- TLS 1.2/1.3 support
- HTTP to HTTPS redirection
- Static file serving capabilities

## Backup Strategy

- MySQL: Automated daily backups at 1 AM (configurable via cron)
- Docker Images: Weekly backup on Mondays at 3 AM
- Backup retention: 7 days for MySQL dumps