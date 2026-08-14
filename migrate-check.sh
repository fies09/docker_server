#!/bin/bash
# ============================================
# Docker 基础设施统一化迁移脚本
# ============================================

set -e

DOCKER_SERVER_DIR="/Users/fanyong/Desktop/code/python/docker_server"
PERSONAL_AI_DIR="/Users/fanyong/Desktop/code/python/personal_ai"
MY_ASSISTANT_DIR="/Users/fanyong/Desktop/code/dev /drass/my_assistant(3)/my_assistant"

echo "=========================================="
echo "Docker 基础设施统一化迁移检查"
echo "=========================================="
echo ""

# 检查当前运行的容器
echo "[1/5] 检查当前运行的容器..."
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || echo "  无运行中的容器"
echo ""

# 检查现有数据卷
echo "[2/5] 检查现有数据卷..."
docker volume ls | grep -E "(kb-|infra-)" || echo "  暂无相关数据卷"
echo ""

# 显示建议操作
echo "[3/5] 迁移建议:"
echo ""
echo "  方案A: 保留现有数据，逐步迁移"
echo "  ----------------------------------------"
echo "  1. 备份现有数据:"
echo "     docker-compose -f ${PERSONAL_AI_DIR}/deploy/docker-compose.yml down"
echo "     cp -r ${PERSONAL_AI_DIR}/deploy/volumes ~/backup/volumes_$(date +%Y%m%d)"
echo ""
echo "  2. 复制数据到统一目录:"
echo "     cp -r ${PERSONAL_AI_DIR}/deploy/volumes/* ${DOCKER_SERVER_DIR}/volumes/ 2>/dev/null || true"
echo ""
echo "  3. 启动统一基础设施:"
echo "     cd ${DOCKER_SERVER_DIR}"
echo "     cp .env.infra.example .env"
echo "     docker-compose -f docker-compose.infra.yml up -d"
echo ""

echo "  方案B: 全新部署（会丢失现有数据）"
echo "  ----------------------------------------"
echo "  1. 停止并删除现有服务:"
echo "     docker-compose -f ${PERSONAL_AI_DIR}/deploy/docker-compose.yml down -v"
echo "     docker-compose -f ${MY_ASSISTANT_DIR}/docker-compose.yml down -v 2>/dev/null || true"
echo ""
echo "  2. 启动统一基础设施:"
echo "     cd ${DOCKER_SERVER_DIR}"
echo "     docker-compose -f docker-compose.infra.yml up -d"
echo ""

# 项目配置适配提示
echo "[4/5] 项目配置适配:"
echo ""
echo "  personal_ai 项目 (.env 文件):"
echo "  ----------------------------------------"
echo "  # 改为使用统一基础设施"
echo "  POSTGRES_HOST=infra-postgres"
echo "  POSTGRES_PORT=5432"
echo "  POSTGRES_PASSWORD=postgres123"
echo "  REDIS_HOST=infra-redis"
echo "  REDIS_PORT=6379"
echo "  MILVUS_HOST=infra-milvus"
echo "  MILVUS_PORT=19530"
echo "  NEO4J_URI=bolt://infra-neo4j:7687"
echo "  NEO4J_PASSWORD=neo4j123"
echo "  OLLAMA_BASE_URL=http://infra-ollama:11434"
echo ""
echo "  my_assistant 项目 (.env 文件):"
echo "  ----------------------------------------"
echo "  # 同上，使用 infra-* 作为主机名"
echo ""

# Paraformer ASR 建议
echo "[5/5] Paraformer ASR 部署建议:"
echo ""
echo "  选项1: 保持 DashScope API（推荐，除非高频使用）"
echo "    - 优点: 零运维成本，按需付费"
echo "    - 缺点: 需要网络，有调用延迟"
echo ""
echo "  选项2: 本地部署 FunASR"
echo "    - 在 docker-compose.infra.yml 中取消 paddleocr 注释并改为 FunASR"
echo "    - 或使用独立容器:"
echo "      docker run -d -p 10095:10095 \\"
echo "        registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-cpu-0.4.5"
echo ""

# 资源预估
echo ""
echo "=========================================="
echo "资源使用预估:"
echo "=========================================="
echo "  Redis:      1GB 内存"
echo "  PostgreSQL: 4GB 内存"
echo "  Milvus:     6GB 内存"
echo "  Neo4j:      3GB 内存"
echo "  Ollama:     16GB 内存（模型加载后）"
echo "  ----------------------------------------"
echo "  总计:       ~30GB 内存"
echo "  建议:       32GB 内存的机器可全部运行"
echo ""
