# ============================================
# FastAPI智能助手服务 Docker镜像
# 单阶段构建，简化配置，加速构建
# ============================================
# 使用官方Python镜像（通过daemon.json配置的镜像源加速）
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOST=0.0.0.0 \
    PORT=5005 \
    LOG_LEVEL=INFO \
    DEBUG=false

# 配置Debian镜像源（使用清华源加速）
RUN sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list

# 安装系统依赖（添加重试机制）
RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
    gcc \
    g++ \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY . /app/

# 安装Python依赖（使用清华镜像加速）
RUN pip install --upgrade pip && \
    pip install -r requirements.txt \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    --trusted-host pypi.tuna.tsinghua.edu.cn

# 创建必要的目录
RUN mkdir -p /app/data /app/logs /app/cache

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT}/docs || exit 1

# 暴露端口
EXPOSE 5005

# 启动命令（使用Python启动，确保PYTHONPATH正确）
CMD ["python", "main.py"]
