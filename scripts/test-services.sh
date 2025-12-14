#!/bin/bash

# 服务测试脚本 - 验证服务是否正常运行
# 用法: ./test-services.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "   Docker 服务健康检查"
echo "========================================"
echo ""

# 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

test_service() {
    local service_name=$1
    local container_name=$2
    local test_command=$3

    echo -n "测试 $service_name... "

    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        # 检查健康状态
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")

        if [ "$health_status" = "healthy" ] || [ "$health_status" = "no-healthcheck" ]; then
            # 如果提供了测试命令，执行它
            if [ -n "$test_command" ]; then
                if eval "$test_command" &>/dev/null; then
                    echo -e "${GREEN}✓ 运行正常${NC} (健康状态: $health_status)"
                else
                    echo -e "${YELLOW}⚠ 运行中但测试失败${NC} (健康状态: $health_status)"
                fi
            else
                echo -e "${GREEN}✓ 运行正常${NC} (健康状态: $health_status)"
            fi
        else
            echo -e "${YELLOW}⚠ 运行中${NC} (健康状态: $health_status)"
        fi
    else
        echo -e "${RED}✗ 未运行${NC}"
    fi
}

# 测试各个服务
test_service "MySQL" "mysql" "docker exec mysql mysqladmin ping -h localhost -u root -p\${MYSQL_PASSWORD} --silent"
test_service "PostgreSQL" "postgres" "docker exec postgres pg_isready -U \${POSTGRES_USER}"
test_service "Redis" "redis" "docker exec redis redis-cli ping"
test_service "RabbitMQ" "rabbitmq" "docker exec rabbitmq rabbitmq-diagnostics ping"
test_service "Nginx" "nginx" "curl -f http://localhost:8080 -s"
test_service "Neo4j" "neo4j" "docker exec neo4j cypher-shell -u \${NEO4J_USER:-neo4j} -p \${NEO4J_PASSWORD} 'RETURN 1;'"
test_service "Flask App" "python-app" "curl -f http://localhost:8000/health -s"

echo ""
echo "========================================"
echo "   服务访问地址"
echo "========================================"
echo ""
echo "MySQL:              localhost:3306"
echo "PostgreSQL:         localhost:5432"
echo "Redis:              localhost:6379"
echo "RabbitMQ:           localhost:5672"
echo "RabbitMQ 管理界面:   http://localhost:15672"
echo "Nginx:              http://localhost:8080"
echo "Neo4j Browser:      http://localhost:7474"
echo "Neo4j Bolt:         bolt://localhost:7687"
echo "Flask App:          http://localhost:8000"
echo ""

# 显示 Neo4j 插件信息
if docker ps --format '{{.Names}}' | grep -q "^neo4j$"; then
    echo "========================================"
    echo "   Neo4j 插件信息"
    echo "========================================"
    echo ""
    docker exec neo4j cypher-shell -u ${NEO4J_USER:-neo4j} -p ${NEO4J_PASSWORD} \
        "RETURN 'Neo4j ' + gds.version() as gds, 'APOC ' + apoc.version() as apoc;" 2>/dev/null || echo "无法获取插件信息"
    echo ""
fi

echo "========================================"
echo "完成！"
echo "========================================"
