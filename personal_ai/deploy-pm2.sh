#!/bin/bash

# Personal AI - PM2 编排脚本
# 用法：
#   bash deploy-pm2.sh start    # 一键启动/重载（pm2 startOrReload）
#   bash deploy-pm2.sh status   # 查看进程状态
#   bash deploy-pm2.sh logs     # 实时查看日志（pm2 logs）
#   bash deploy-pm2.sh restart  # 重启所有进程
#   bash deploy-pm2.sh stop     # 停止所有进程
#   bash deploy-pm2.sh delete   # 删除所有进程

set -e

cd "$(dirname "$0")"

ACTION="${1:-start}"

echo "🚀 Personal AI - PM2 部署脚本"
echo "=========================="
echo "动作: $ACTION"

# 获取本机IP地址
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' || echo "127.0.0.1")

# 创建日志目录
echo "📁 创建日志目录..."
mkdir -p logs

# 检查PM2是否安装
if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2未安装，正在安装..."
    npm install -g pm2
fi

case "$ACTION" in
    status)
        echo "📊 PM2 进程状态:"
        pm2 status
        exit 0
        ;;
    logs)
        echo "📝 PM2 实时日志 (Ctrl+C 退出):"
        pm2 logs
        exit 0
        ;;
    restart)
        echo "🔄 重启 PM2 进程..."
        pm2 restart ecosystem.config.js
        pm2 status
        exit 0
        ;;
    stop)
        echo "🛑 停止 PM2 进程..."
        pm2 stop ecosystem.config.js || true
        pm2 status
        exit 0
        ;;
    delete)
        echo "🗑️  删除 PM2 进程..."
        pm2 delete ecosystem.config.js || true
        pm2 status
        exit 0
        ;;
    start)
        echo "▶️  启动 PM2 服务（startOrReload）..."
        ;;
    *)
        echo "❌ 未知动作: $ACTION"
        echo "用法: $0 {start|status|logs|restart|stop|delete}"
        exit 1
        ;;
esac

# --- start 子命令：原有 git pull + build + startOrReload 流程 ---

# 安装Python依赖
echo "🐍 安装Python依赖..."
if command -v poetry &> /dev/null; then
    echo "📝 使用Poetry安装依赖..."
    poetry install
else
    echo "📝 使用pip安装依赖..."
    pip install fastapi uvicorn sqlalchemy aiosqlite pydantic "pydantic[email]" pydantic-settings httpx python-multipart redis PyJWT aiofiles email-validator dnspython
fi

# 安装前端依赖
echo "📦 安装前端依赖..."
cd frontend
if [ ! -f "package.json" ]; then
    echo "❌ 前端package.json不存在，请先创建"
    exit 1
fi
npm install

# 检查是否存在构建错误
echo "🔨 构建前端应用..."
if npm run build; then
    echo "✅ 前端构建成功"
else
    echo "❌ 前端构建失败，请检查错误信息"
    echo "💡 提示: 请确保已正确配置环境变量"
    exit 1
fi
cd ..

# 检查端口占用并提示
echo "🔍 检查端口占用情况..."
BACKEND_PORT_PROCESS=$(lsof -ti:8008 2>/dev/null || echo "")
FRONTEND_PORT_PROCESS=$(lsof -ti:3000 2>/dev/null || echo "")

if [ ! -z "$BACKEND_PORT_PROCESS" ]; then
    echo "⚠️  端口8008被占用 (PID: $BACKEND_PORT_PROCESS)"
    echo "💡 如需停止占用进程: kill -9 $BACKEND_PORT_PROCESS"
fi

if [ ! -z "$FRONTEND_PORT_PROCESS" ]; then
    echo "⚠️  端口3000被占用 (PID: $FRONTEND_PORT_PROCESS)"
    echo "💡 如需停止占用进程: kill -9 $FRONTEND_PORT_PROCESS"
fi

# 启动PM2服务（startOrReload：已存在则 reload，不存在则 start）
echo "▶️  启动PM2服务（startOrReload）..."
pm2 startOrReload ecosystem.config.js --env production

# 保存PM2配置
echo "💾 保存PM2配置..."
pm2 save

# 设置PM2开机自启
echo "🔄 设置PM2开机自启..."
pm2 startup

echo ""
echo "✅ PM2部署完成！"
echo "================================"
echo "📱 本地访问地址:"
echo "  前端应用: http://localhost:3000"
echo "  后端API: http://localhost:8008"
echo "  API文档: http://localhost:8008/docs"
echo ""
echo "🌐 局域网访问地址:"
echo "  前端应用: http://$LOCAL_IP:3000"
echo "  后端API: http://$LOCAL_IP:8008"
echo "  API文档: http://$LOCAL_IP:8008/docs"
echo ""
echo "🔧 配置Nginx反向代理 (可选):"
echo "  sudo ./deploy-nginx.sh"
echo "  配置后访问: http://$LOCAL_IP"
echo ""
echo "📊 PM2管理命令:"
echo "  查看状态:    bash deploy-pm2.sh status"
echo "  查看日志:    bash deploy-pm2.sh logs"
echo "  重启服务:    bash deploy-pm2.sh restart"
echo "  停止服务:    bash deploy-pm2.sh stop"
echo "  删除服务:    bash deploy-pm2.sh delete"
echo "  一键启动:    bash deploy-pm2.sh start"
echo ""
echo "📝 注意事项:"
echo "  1. 确保已配置app/.env文件中的API密钥"
echo "  2. 如需要Redis，请先启动Redis服务"
echo "  3. 本机IP: $LOCAL_IP"
echo "  4. 首次运行请检查 pm2 logs 确认服务正常"
echo "  5. 当前模型支持: Claude Opus 4.1, Claude Sonnet 4"
echo "  6. 如有端口冲突，请先停止相关服务"