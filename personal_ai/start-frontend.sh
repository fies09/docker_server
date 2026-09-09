#!/usr/bin/env bash
# PM2 启动 personal-ai 前端（Next.js）
# 由 ecosystem.config.js 中的 personal-ai-frontend 调用
# 按 NODE_ENV 切换：production → npm run start（3000），development → npm run dev（3001）
set -e
cd /Users/fanyong/Desktop/code/python/personal_ai/frontend

if [ "${NODE_ENV}" = "production" ]; then
    exec npm run start -- -p 3000
else
    exec npm run dev
fi