#!/bin/bash
set -euo pipefail

# 从rsync硬链接快照恢复
# 用法: restore_from_snapshot.sh snapshot_20260826

PROJECT_DIR="/Users/fanyong/Desktop/code/python/docker_server"
BACKUP_BASE="$PROJECT_DIR/数据库数据备份"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.inified.yml"

SNAPSHOT_DIR="${1:-}"

if [ -z "$SNAPSHOT_DIR" ]; then
  echo "用法: $0 <snapshot_name>"
  echo "可用快照:"
  ls -1 "$BACKUP_BASE" | grep "^snapshot_" || echo "  (无)"
  exit 1
fi

SNAPSHOT_PATH="$BACKUP_BASE/$SNAPSHOT_DIR"
[ -d "$SNAPSHOT_PATH" ] || { echo "快照不存在: $SNAPSHOT_PATH"; exit 1; }

VOLUMES=(
  "infra_minio-data:minio"
  "infra_etcd-data:etcd"
  "infra_neo4j-data:neo4j"
)

echo "[1/4] 停止 milvus + neo4j"
docker compose -f "$COMPOSE_FILE" stop milvus neo4j 2>/dev/null || true

echo "[2/4] 恢复 minio + etcd"
for item in "${VOLUMES[@]}"; do
  volume="${item%%:*}"
  name="${item##*:}"
  if [ -d "$SNAPSHOT_PATH/$name" ]; then
    echo "  恢复 $volume <- $SNAPSHOT_DIR/$name"
    docker run --rm \
      -v "$volume:/dst" \
      -v "$BACKUP_BASE:/backup:ro" \
      alpine:latest \
      sh -c "rm -rf /dst/* && cp -a /backup/$SNAPSHOT_DIR/$name/. /dst/"
  fi
done

echo "[3/4] 恢复 postgres"
if [ -f "$SNAPSHOT_PATH/postgres/all_databases.sql.gz" ]; then
  gunzip -c "$SNAPSHOT_PATH/postgres/all_databases.sql.gz" | \
    docker exec -i -e PGPASSWORD=postgres123 infra-postgres psql -U postgres -d postgres
fi

echo "[4/4] 启动 etcd -> minio -> milvus + neo4j"
docker compose -f "$COMPOSE_FILE" up -d etcd minio
docker compose -f "$COMPOSE_FILE" up -d milvus neo4j

echo "DONE."
docker compose -f "$COMPOSE_FILE" ps