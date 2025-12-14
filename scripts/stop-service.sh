#!/bin/bash

# 服务停止脚本 - 支持单独停止各个服务
# 用法: ./stop-service.sh [service-name]
# 示例: ./stop-service.sh neo4j

set -e

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
    echo "  all         - 停止所有服务"
    echo ""
    echo "示例:"
    echo "  $0 neo4j              # 停止 Neo4j"
    echo "  $0 mysql redis        # 停止 MySQL 和 Redis"
    echo "  $0 all                # 停止所有服务"
}

stop_service() {
    local service=$1
    case $service in
        mysql)
            echo "停止 MySQL..."
            docker-compose -f docker-compose.mysql.yml down
            ;;
        postgresql)
            echo "停止 PostgreSQL..."
            docker-compose -f docker-compose.postgresql.yml down
            ;;
        redis)
            echo "停止 Redis..."
            docker-compose -f docker-compose.redis.yml down
            ;;
        rabbitmq)
            echo "停止 RabbitMQ..."
            docker-compose -f docker-compose.rabbitmq.yml down
            ;;
        nginx)
            echo "停止 Nginx..."
            docker-compose -f docker-compose.nginx.yml down
            ;;
        neo4j)
            echo "停止 Neo4j..."
            docker-compose -f docker-compose.neo4j.yml down
            ;;
        app)
            echo "停止 Flask 应用..."
            docker-compose -f docker-compose.build.yml down
            ;;
        all)
            echo "停止所有服务..."
            stop_service mysql
            stop_service postgresql
            stop_service redis
            stop_service rabbitmq
            stop_service nginx
            stop_service neo4j
            stop_service app
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

# 停止指定的服务
for service in "$@"; do
    stop_service "$service"
done

echo ""
echo "✅ 服务停止完成！"
