#!/bin/bash
# ============================================
# Docker 统一基础设施迁移脚本
# 保留数据，停止旧服务，启动统一服务
# ============================================

set -e

DOCKER_SERVER_DIR="/Users/fanyong/Desktop/code/python/docker_server"
PERSONAL_AI_DIR="/Users/fanyong/Desktop/code/python/personal_ai"
MY_ASSISTANT_DIR="/Users/fanyong/Desktop/code/dev /drass/my_assistant(3)/my_assistant"

echo "=========================================="
echo "Docker 统一基础设施迁移"
echo "=========================================="
echo ""

# 1. 备份现有数据
echo "[1/4] 备份现有数据..."
BACKUP_DIR="$DOCKER_SERVER_DIR/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份 personal_ai 数据
if [ -d "$PERSONAL_AI_DIR/deploy/volumes" ]; then
    echo "  备份 personal_ai volumes..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes" "$BACKUP_DIR/personal_ai_volumes"
fi

# 备份 my_assistant 数据 (如果有)
if [ -d "$MY_ASSISTANT_DIR/data" ]; then
    echo "  备份 my_assistant data..."
    cp -r "$MY_ASSISTANT_DIR/data" "$BACKUP_DIR/my_assistant_data"
fi

echo "  备份完成: $BACKUP_DIR"
echo ""

# 2. 停止旧容器
echo "[2/4] 停止旧容器..."
docker stop redis neo4j postgres kb-neo4j kb-postgres kb-redis redis-dev postgres-dev 2>/dev/null || true
docker rm redis neo4j postgres kb-neo4j kb-postgres kb-redis redis-dev postgres-dev 2>/dev/null || true
docker stop kb-milvus kb-minio kb-etcd 2>/dev/null || true
docker rm kb-milvus kb-minio kb-etcd 2>/dev/null || true

echo "  旧容器已停止并移除"
echo ""

# 3. 迁移数据到统一目录
echo "[3/4] 迁移数据..."

# 创建统一数据目录
mkdir -p "$DOCKER_SERVER_DIR/volumes/redis"
mkdir -p "$DOCKER_SERVER_DIR/volumes/postgres"
mkdir -p "$DOCKER_SERVER_DIR/volumes/neo4j"
mkdir -p "$DOCKER_SERVER_DIR/volumes/etcd"
mkdir -p "$DOCKER_SERVER_DIR/volumes/minio"
mkdir -p "$DOCKER_SERVER_DIR/volumes/milvus"
mkdir -p "$DOCKER_SERVER_DIR/volumes/ollama"

# 迁移 personal_ai 的 Neo4j 数据 (如果存在)
if [ -d "$PERSONAL_AI_DIR/deploy/volumes/kb-neo4j-data" ]; then
    echo "  迁移 Neo4j 数据..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes/kb-neo4j-data"/* "$DOCKER_SERVER_DIR/volumes/neo4j/" 2>/dev/null || true
fi

# 迁移 personal_ai 的 Redis 数据 (如果存在)
if [ -d "$PERSONAL_AI_DIR/deploy/volumes/kb-redis-data" ]; then
    echo "  迁移 Redis 数据..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes/kb-redis-data"/* "$DOCKER_SERVER_DIR/volumes/redis/" 2>/dev/null || true
fi

# 迁移 personal_ai 的 Postgres 数据 (如果存在)
if [ -d "$PERSONAL_AI_DIR/deploy/volumes/kb-postgres-data" ]; then
    echo "  迁移 PostgreSQL 数据..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes/kb-postgres-data"/* "$DOCKER_SERVER_DIR/volumes/postgres/" 2>/dev/null || true
fi

# 迁移 Milvus 相关数据
if [ -d "$PERSONAL_AI_DIR/deploy/volumes/kb-milvus-data" ]; then
    echo "  迁移 Milvus 数据..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes/kb-milvus-data"/* "$DOCKER_SERVER_DIR/volumes/milvus/" 2>/dev/null || true
fi
if [ -d "$PERSONAL_AI_DIR/deploy/volumes/kb-etcd-data" ]; then
    echo "  迁移 etcd 数据..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes/kb-etcd-data"/* "$DOCKER_SERVER_DIR/volumes/etcd/" 2>/dev/null || true
fi
if [ -d "$PERSONAL_AI_DIR/deploy/volumes/kb-minio-data" ]; then
    echo "  迁移 minio 数据..."
    cp -r "$PERSONAL_AI_DIR/deploy/volumes/kb-minio-data"/* "$DOCKER_SERVER_DIR/volumes/minio/" 2>/dev/null || true
fi

echo "  数据迁移完成"
echo ""

# 4. 启动统一服务
echo "[4/4] 启动统一服务..."
cd "$DOCKER_SERVER_DIR"

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "  创建 .env 文件..."
    cp .env.infra.example .env
    echo "  ⚠️  请编辑 .env 文件设置密码后重新运行"
    exit 1
fi

# 启动服务
docker-compose -f docker-compose.unified.yml up -d

echo ""
echo "=========================================="
echo "统一基础设施启动完成!"
echo "=========================================="
echo ""
echo "服务状态:"
docker-compose -f docker-compose.unified.yml ps
echo ""
echo "项目配置指南:"
echo "------------------------------------------"
echo "personal_ai/.env:"
echo "  REDIS_HOST=infra-redis"
echo "  REDIS_PORT=6379"
echo "  POSTGRES_HOST=infra-postgres"
echo "  POSTGRES_PORT=5432"
echo "  POSTGRES_DB=personal_ai_db"
echo "  MILVUS_HOST=infra-milvus"
echo "  MILVUS_PORT=19530"
echo "  NEO4J_URI=bolt://infra-neo4j:7687"
echo "  OLLAMA_BASE_URL=http://infra-ollama:11434"
echo ""
echo "my_assistant/configs/.env:"
echo "  REDIS_HOST=infra-redis"
echo "  REDIS_PORT=6379"
echo "  POSTGRES_HOST=infra-postgres"
echo "  POSTGRES_PORT=5432"
echo "  POSTGRES_DB=my_assistant_db"
echo "  NEO4J_URI=bolt://infra-neo4j:7687"
echo "  OLLAMA_BASE_URL=http://infra-ollama:11434"
echo ""
echo "备份位置: $BACKUP_DIR"
echo ""
