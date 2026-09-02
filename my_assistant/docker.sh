#!/bin/bash
# ============================================
# my_assistant 应用容器一键管理脚本
# 数据服务由 ../infra/docker.sh 管理,本脚本仅控制应用容器
# ============================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_CONTAINER="my-assistant"
PROJECT_NAME="my_assistant"
COMPOSE_FILE="docker-compose.yml"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()    { echo -e "${GREEN}✓ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $1${NC}"; }
err()   { echo -e "${RED}✗ $1${NC}"; }

show_help() {
    echo "my_assistant 应用容器管理脚本"
    echo ""
    echo "用法: ./docker.sh <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  up            构建并后台启动 my-assistant(首次/源码改动后)"
    echo "  build         强制重建镜像(--no-cache,依赖变更或 Dockerfile 改动)"
    echo "  rebuild       增量重建 + 重启(常规源码改动)"
    echo "  down          停止应用容器(保留数据卷)"
    echo "  restart       重启应用容器"
    echo "  ps            应用 + infra 服务状态(合并视图)"
    echo "  logs [N]      查看应用日志(默认 50 行)"
    echo "  status        应用健康检查(/docs)"
    echo "  shell         进入应用容器"
    echo "  clean         删除应用容器 + 镜像(危险,需确认)"
    echo ""
    echo "示例:"
    echo "  ./docker.sh up"
    echo "  ./docker.sh rebuild          # 改完代码后"
    echo "  ./docker.sh logs 100"
}

ensure_compose() {
    if ! command -v docker >/dev/null 2>&1; then
        err "docker 未安装"
        exit 1
    fi
    docker compose version >/dev/null 2>&1 || {
        err "docker compose 不可用"
        exit 1
    }
}

cmd_up() {
    ensure_compose
    echo "构建并启动 my-assistant..."
    docker compose -f "$COMPOSE_FILE" up -d --build
    echo ""
    docker compose -f "$COMPOSE_FILE" ps
    echo ""
    sleep 3
    cmd_status
}

cmd_build() {
    ensure_compose
    echo "强制重建镜像(无缓存)..."
    docker compose -f "$COMPOSE_FILE" build --no-cache
}

cmd_rebuild() {
    ensure_compose
    echo "增量重建 + 重启..."
    docker compose -f "$COMPOSE_FILE" up -d --build
    echo ""
    sleep 2
    docker compose -f "$COMPOSE_FILE" ps
}

cmd_down() {
    ensure_compose
    echo "停止应用容器..."
    docker compose -f "$COMPOSE_FILE" down
    ok "应用容器已停止(数据卷保留)"
}

cmd_restart() {
    ensure_compose
    echo "重启应用容器..."
    docker compose -f "$COMPOSE_FILE" restart assistant
    sleep 2
    docker compose -f "$COMPOSE_FILE" ps assistant
}

cmd_ps() {
    ensure_compose
    echo "=== 应用服务 ==="
    docker compose -f "$COMPOSE_FILE" ps
    echo ""
    echo "=== Infra 数据服务 ==="
    cd "$SCRIPT_DIR/../infra" 2>/dev/null && ./docker.sh ps 2>/dev/null || \
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=infra-"
}

cmd_logs() {
    local n="${1:-50}"
    ensure_compose
    docker logs "$APP_CONTAINER" --tail "$n" --follow
}

cmd_status() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${APP_CONTAINER}$"; then
        warn "应用容器未运行"
        return 1
    fi
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$APP_CONTAINER" 2>/dev/null || echo "no-healthcheck")
    echo "容器状态: $(docker inspect --format='{{.State.Status}}' "$APP_CONTAINER")"
    echo "健康检查: $health"
    if curl -sf http://localhost:8000/docs >/dev/null 2>&1; then
        ok "http://localhost:8000/docs 可访问"
    else
        warn "http://localhost:8000/docs 不可访问"
    fi
}

cmd_shell() {
    ensure_compose
    if ! docker ps --format '{{.Names}}' | grep -q "^${APP_CONTAINER}$"; then
        err "应用容器未运行"
        exit 1
    fi
    docker exec -it "$APP_CONTAINER" bash
}

cmd_clean() {
    warn "将删除: 应用容器 my-assistant + 镜像 my-assistant:latest"
    read -p "确认? [y/N] " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        ensure_compose
        docker compose -f "$COMPOSE_FILE" down --rmi local
        ok "已清理"
    else
        echo "已取消"
    fi
}

case "${1:-}" in
    up)         cmd_up ;;
    build)      cmd_build ;;
    rebuild)    cmd_rebuild ;;
    down)       cmd_down ;;
    restart)    cmd_restart ;;
    ps)         cmd_ps ;;
    logs)       shift; cmd_logs "$@" ;;
    status)     cmd_status ;;
    shell)      cmd_shell ;;
    clean)      cmd_clean ;;
    -h|--help|help|"") show_help ;;
    *)
        err "未知命令: $1"
        show_help
        exit 1
        ;;
esac