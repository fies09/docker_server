#!/bin/bash

# 多平台镜像构建脚本（离线方式）
IMAGE_NAME="crpi-srv542vpdq3agniz.cn-chengdu.personal.cr.aliyuncs.com/personal_ai_dev/python-app"
TAG="python3.11"

echo "🚀 开始构建多平台镜像..."

# 使用本地镜像构建当前平台
echo "📦 构建当前平台镜像..."
docker build -t ${IMAGE_NAME}:${TAG} .

if [ $? -eq 0 ]; then
    echo "✅ 当前平台构建成功"
    
    # 推送镜像
    echo "📤 推送镜像到仓库..."
    docker push ${IMAGE_NAME}:${TAG}
    
    if [ $? -eq 0 ]; then
        echo "✅ 镜像推送成功！"
        echo "🔗 镜像地址: ${IMAGE_NAME}:${TAG}"
        
        # 显示镜像信息
        echo "📋 本地镜像信息:"
        docker images ${IMAGE_NAME}:${TAG}
        
        echo ""
        echo "⚠️  重要提示："
        echo "   - 当前镜像基于 ARM64 架构构建"
        echo "   - 需要在 x86_64 机器上重新构建完整的多平台支持"
        echo "   - 或等待网络改善后使用 Docker Buildx 构建"
        
    else
        echo "❌ 推送失败"
        exit 1
    fi
else
    echo "❌ 构建失败"
    exit 1
fi