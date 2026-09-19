#!/usr/bin/env bash
# PM2 启动 personal-ai 后端（personal_ai conda 环境，8008 端口）
# 由 ecosystem.config.js 中的 personal-ai-backend 调用
# 直跑 /Users/fanyong/miniforge3/envs/personal_ai/bin/python -u 避免 conda run wrapper
# 吃掉 stdout（PM2 fork 模式下无法把 wrapper 孙进程的 fd 透到 out_file）。
set -e
cd /Users/fanyong/Desktop/code/python/personal_ai

# 按需拉起 infra 栈（PG/Redis/Neo4j/Ollama）
INFRA_DIR="/Users/fanyong/Desktop/code/python/docker_server/infra"
LANGFUSE_DIR="/Users/fanyong/Desktop/code/python/docker_server/langfuse"
missing=()
for c in infra-postgres infra-redis infra-neo4j infra-ollama; do
  docker ps --format '{{.Names}}' 2>/dev/null | grep -qFx "$c" || missing+=("$c")
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "▶️  检测到缺失 infra 容器: ${missing[*]}，自动启动..."
  bash "$INFRA_DIR/docker.sh" up
else
  echo "✅ infra 栈全部运行中"
fi

# 按需拉起 langfuse 栈（LLM trace 可观测平台）
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qFx "langfuse-langfuse-web-1"; then
  echo "▶️  检测到 langfuse 未运行，自动启动（首次可能需 ~30s 等 clickhouse 就绪）..."
  (cd "$LANGFUSE_DIR" && docker compose up -d) || echo "⚠️  langfuse 拉起失败，trace 将走本地 fallback"
else
  echo "✅ langfuse 运行中"
fi

exec /Users/fanyong/miniforge3/envs/personal_ai/bin/python -u -m uvicorn app.main:app --host 0.0.0.0 --port 8008 --reload --reload-dir app --reload-include '*.py'