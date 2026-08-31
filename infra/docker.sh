#!/bin/bash
# ============================================
# 统一基础设施管理脚本
# Compose 文件: ./docker-compose.yml (name: infra)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "统一基础设施管理脚本 (infra stack)"
    echo ""
    echo "用法: ./docker.sh [命令]"
    echo ""
    echo "命令:"
    echo "  up          启动所有服务"
    echo "  up-milvus   仅启动 Milvus 三件套 (etcd/minio/milvus)"
    echo "  down        停止所有服务"
    echo "  ps          查看运行状态"
    echo "  logs [服务] 查看日志"
    echo "  restart     重启所有服务"
    echo "  clean       清理所有数据 (危险!)"
    echo ""
    echo "示例:"
    echo "  ./docker.sh up"
    echo "  ./docker.sh logs postgres"
    echo ""
}

case "${1:-}" in
    up)
        echo "启动统一基础设施服务..."
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" up -d
        echo ""
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" ps
        ;;
    up-milvus)
        echo "启动 Milvus 三件套..."
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" up -d etcd minio milvus
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" ps etcd minio milvus
        ;;
    down)
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" down
        ;;
    ps)
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" ps
        ;;
    logs)
        if [ -n "$2" ]; then
            docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" logs -f "$2"
        else
            docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" logs -f
        fi
        ;;
    restart)
        docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" restart "$@"
        ;;
    clean)
        echo "⚠️  警告: 这将删除所有数据卷!"
        read -p "确认删除? [y/N] " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" down -v
            echo "数据已清理"
        else
            echo "已取消"
        fi
        ;;
    *)
        show_help
        ;;
esac
