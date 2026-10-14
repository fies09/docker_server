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
    echo "  up [服务...] 启动服务 (省略则全部: postgres/redis/neo4j/ollama/milvus-etcd/milvus-minio/milvus-standalone/milvus-attu)"
    echo "  down        停止所有服务"
    echo "  ps          查看运行状态"
    echo "  logs [服务] 查看日志"
    echo "  restart [服务...] 重启服务 (省略则全部)"
    echo "  clean       清理所有数据 (危险!)"
    echo ""
    echo "示例:"
    echo "  ./docker.sh up"
    echo "  ./docker.sh up milvus-standalone"
    echo "  ./docker.sh logs postgres"
    echo ""
}

# compose 命令统一入口；传入至少 1 个服务名时限定在该服务上
compose() {
    docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/docker-compose.yml" "$@"
}

# 取服务名列表：$1 之后的全部参数（跳过子命令本身）
services_from() {
    shift
    [ $# -gt 0 ] && printf '%s\n' "$@"
}

case "${1:-}" in
    up)
        echo "启动统一基础设施服务..."
        svc=$(services_from "$@")
        if [ -n "$svc" ]; then
            compose up -d --remove-orphans $svc
        else
            compose up -d --remove-orphans
        fi
        echo ""
        compose ps
        ;;
    down)
        compose down
        ;;
    ps)
        compose ps
        ;;
    logs)
        if [ -n "$2" ]; then
            compose logs -f "$2"
        else
            compose logs -f
        fi
        ;;
    restart)
        svc=$(services_from "$@")
        if [ -n "$svc" ]; then
            compose restart $svc
        else
            compose restart
        fi
        ;;
    clean)
        echo "⚠️  警告: 这将删除所有数据卷!"
        read -p "确认删除? [y/N] " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            compose down -v
            echo "数据已清理"
        else
            echo "已取消"
        fi
        ;;
    *)
        show_help
        ;;
esac
