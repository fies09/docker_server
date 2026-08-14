#!/bin/bash
# ============================================
# Docker 统一管理脚本
# 所有Docker操作只在此目录执行
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "Docker Server 统一管理脚本"
    echo ""
    echo "用法: ./docker.sh [命令]"
    echo ""
    echo "命令:"
    echo "  up          启动所有服务"
    echo "  down        停止所有服务"
    echo "  ps          查看运行状态"
    echo "  logs [服务] 查看日志"
    echo "  restart     重启所有服务"
    echo "  clean       清理所有数据 (危险!)"
    echo "  migrate     执行迁移脚本"
    echo ""
    echo "示例:"
    echo "  ./docker.sh up"
    echo "  ./docker.sh logs postgres"
    echo ""
}

case "${1:-}" in
    up)
        echo "启动统一基础设施服务..."
        docker-compose -f docker-compose.unified.yml up -d
        echo ""
        echo "服务状态:"
        docker-compose -f docker-compose.unified.yml ps
        ;;
    down)
        echo "停止所有服务..."
        docker-compose -f docker-compose.unified.yml down
        ;;
    ps)
        docker-compose -f docker-compose.unified.yml ps
        ;;
    logs)
        if [ -n "$2" ]; then
            docker-compose -f docker-compose.unified.yml logs -f "$2"
        else
            docker-compose -f docker-compose.unified.yml logs -f
        fi
        ;;
    restart)
        echo "重启所有服务..."
        docker-compose -f docker-compose.unified.yml restart
        ;;
    clean)
        echo "⚠️  警告: 这将删除所有数据!"
        read -p "确认删除? [y/N] " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            docker-compose -f docker-compose.unified.yml down -v
            echo "数据已清理"
        else
            echo "已取消"
        fi
        ;;
    migrate)
        ./migrate-to-unified.sh
        ;;
    *)
        show_help
        ;;
esac
