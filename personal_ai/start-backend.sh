#!/usr/bin/env bash
# PM2 启动 personal-ai 后端（personal_ai conda 环境，8008 端口）
# 由 ecosystem.config.js 中的 personal-ai-backend 调用
# 直跑 /Users/fanyong/miniforge3/envs/personal_ai/bin/python -u 避免 conda run wrapper
# 吃掉 stdout（PM2 fork 模式下无法把 wrapper 孙进程的 fd 透到 out_file）。
set -e
cd /Users/fanyong/Desktop/code/python/personal_ai
exec /Users/fanyong/miniforge3/envs/personal_ai/bin/python -u -m uvicorn app.main:app --host 0.0.0.0 --port 8008 --reload --reload-dir app --reload-include '*.py'