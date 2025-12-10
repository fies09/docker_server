#!/bin/bash

# 服务启动脚本 - 支持单独启动各个服务
# 用法: ./start-service.sh [service-name]
# 示例: ./start-service.sh neo4j
#       ./start-service.sh mysql redis

set -e

SERVICES=("mysql" "postgresql" "redis" "rabbitmq" "nginx" "neo4j" "app")

print_usage() {
    echo "用法: $0 [service1] [service2] ..."
    echo ""
    echo "可用服务:"
    echo "  mysql       - MySQL 数据库"
    echo "  postgresql  - PostgreSQL 数据库"
    echo "  redis       - Redis 缓存"
    echo "  rabbitmq    - RabbitMQ 消息队列"
    echo "  nginx       - Nginx 反向代理"
    echo "  neo4j       - Neo4j 图数据库"
    echo "  app         - Flask 应用"
    echo "  all         - 启动所有服务"
    echo ""
    echo "示例:"
    echo "  $0 neo4j              # 启动 Neo4j"
    echo "  $0 mysql redis        # 启动 MySQL 和 Redis"
    echo "  $0 all                # 启动所有服务"
}

start_service() {
    local service=$1
    case $service in
        mysql)
            echo "启动 MySQL..."
            docker-compose -f docker-compose.mysql.yml up -d --no-build
            ;;
        postgresql)
            echo "启动 PostgreSQL..."
            docker-compose -f docker-compose.postgresql.yml up -d --no-build
            ;;
        redis)
            echo "启动 Redis..."
            docker-compose -f docker-compose.redis.yml up -d --no-build
            ;;
        rabbitmq)
            echo "启动 RabbitMQ..."
            docker-compose -f docker-compose.rabbitmq.yml up -d --no-build
            ;;
        nginx)
            echo "启动 Nginx..."
            docker-compose -f docker-compose.nginx.yml up -d --no-build
            ;;
        neo4j)
            echo "启动 Neo4j..."
            docker-compose -f docker-compose.neo4j.yml up -d --no-build
            ;;
        app)
            echo "启动 Flask 应用..."
            docker-compose -f docker-compose.build.yml up -d --build
            ;;
        all)
            echo "启动所有服务..."
            start_service mysql
            start_service postgresql
            start_service redis
            start_service rabbitmq
            start_service nginx
            start_service neo4j
            start_service app
            ;;
        *)
            echo "错误: 未知服务 '$service'"
            print_usage
            exit 1
            ;;
    esac
}

# 检查参数
if [ $# -eq 0 ]; then
    print_usage
    exit 1
fi

# 启动指定的服务
for service in "$@"; do
    start_service "$service"
done

echo ""
echo "✅ 服务启动完成！"
echo ""
echo "查看运行中的容器:"
echo "  docker ps"
echo ""
echo "查看服务日志:"
echo "  docker-compose -f docker-compose.[service].yml logs -f"
