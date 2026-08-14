#!/bin/bash

echo "🌐 Personal AI - 完整部署脚本（PM2 + Nginx）"
echo "========================================"
echo "📋 支持的AI模型: Claude Opus 4.1, Claude Sonnet 4"
echo ""

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   echo "❌ 此脚本需要root权限，请使用 sudo 运行"
   exit 1
fi

# 获取实际用户（避免sudo问题）
REAL_USER=${SUDO_USER:-$USER}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 第一步：部署PM2服务..."
echo "=========================="
# 切换到实际用户运行PM2部署
sudo -u "$REAL_USER" bash "$PROJECT_DIR/deploy-pm2.sh"

if [ $? -ne 0 ]; then
    echo "❌ PM2部署失败，停止脚本执行"
    exit 1
fi

echo ""
echo "🌐 第二步：配置Nginx反向代理..."
echo "==============================="

# 检查nginx是否安装
if ! command -v nginx &> /dev/null; then
    echo "📦 Nginx未安装，正在安装..."
    
    # 检测操作系统类型
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux系统
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            apt-get update
            apt-get install -y nginx
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            yum install -y nginx
        elif command -v dnf &> /dev/null; then
            # Fedora
            dnf install -y nginx
        else
            echo "❌ 不支持的Linux发行版"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install nginx
        else
            echo "❌ 请先安装Homebrew: https://brew.sh"
            exit 1
        fi
    else
        echo "❌ 不支持的操作系统: $OSTYPE"
        exit 1
    fi
fi

# 备份原有nginx配置
echo "💾 备份原有nginx配置..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    NGINX_CONF="/usr/local/etc/nginx/nginx.conf"
    NGINX_SITES_DIR="/usr/local/etc/nginx/servers"
    NGINX_PID="/usr/local/var/run/nginx.pid"
else
    # Linux
    NGINX_CONF="/etc/nginx/nginx.conf"
    NGINX_SITES_DIR="/etc/nginx/sites-available"
    NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
    NGINX_PID="/var/run/nginx.pid"
fi

# 创建必要目录
mkdir -p "$NGINX_SITES_DIR"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    mkdir -p "$NGINX_ENABLED_DIR"
fi

# 备份原配置
if [ -f "$NGINX_CONF" ]; then
    cp "$NGINX_CONF" "$NGINX_CONF.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 复制项目nginx配置
echo "📋 配置Nginx..."
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS配置
    cp "$PROJECT_DIR/nginx.conf" "$NGINX_SITES_DIR/personal-ai.conf"
    
    # 修改主nginx配置以包含站点配置
    cat > "$NGINX_CONF" << 'EOL'
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';

    sendfile        on;
    keepalive_timeout  65;
    
    # 包含站点配置
    include servers/*;
}
EOL
else
    # Linux配置
    cp "$PROJECT_DIR/nginx.conf" "$NGINX_SITES_DIR/personal-ai"
    
    # 创建软链接启用站点
    if [ -L "$NGINX_ENABLED_DIR/personal-ai" ]; then
        rm "$NGINX_ENABLED_DIR/personal-ai"
    fi
    ln -s "$NGINX_SITES_DIR/personal-ai" "$NGINX_ENABLED_DIR/personal-ai"
    
    # 删除默认站点
    if [ -L "$NGINX_ENABLED_DIR/default" ]; then
        rm "$NGINX_ENABLED_DIR/default"
    fi
fi

# 测试nginx配置
echo "🔍 测试Nginx配置..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx配置测试通过"
    
    # 重新加载nginx
    echo "🔄 重新加载Nginx..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if [ -f "$NGINX_PID" ]; then
            nginx -s reload
        else
            nginx
        fi
    else
        # Linux
        systemctl reload nginx || service nginx reload
        systemctl enable nginx || chkconfig nginx on
    fi
    
    echo ""
    echo "✅ Nginx配置完成！"
    echo "================================"
    echo "🌐 访问地址:"
    echo "  http://localhost (前端应用)"
    echo "  http://localhost/api/ (后端API)"
    echo "  http://localhost/docs (API文档)"
    echo ""
    echo "📋 管理命令:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  启动: sudo nginx"
        echo "  停止: sudo nginx -s stop"
        echo "  重启: sudo nginx -s reload"
        echo "  测试: sudo nginx -t"
    else
        echo "  启动: sudo systemctl start nginx"
        echo "  停止: sudo systemctl stop nginx"
        echo "  重启: sudo systemctl restart nginx"
        echo "  状态: sudo systemctl status nginx"
        echo "  测试: sudo nginx -t"
    fi
    echo ""
    echo "📝 注意事项:"
    echo "  1. 确保后端服务运行在端口8000"
    echo "  2. 确保前端服务运行在端口3000"
    echo "  3. 如有防火墙，请开放80端口"
    
else
    echo "❌ Nginx配置测试失败，请检查配置文件"
    exit 1
fi