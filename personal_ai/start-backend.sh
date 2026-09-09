#!/usr/bin/env bash
# PM2 启动 personal-ai 后端（personal_ai conda 环境，8008 端口）
# 由 ecosystem.config.js 中的 personal-ai-backend 调用
set -e
cd /Users/fanyong/Desktop/code/python/personal_ai
exec conda run -n personal_ai python -m uvicorn app.main:app --host 0.0.0.0 --port 8008 --reload --reload-dir app --reload-include '*.py'