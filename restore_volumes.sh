#!/bin/bash
set -euo pipefail
BACKUP_DIR="${1:-/Users/fanyong/Desktop/code/python/docker_server/数据库数据备份/20260821_volume_backup}"
COMPOSE="/Users/fanyong/Desktop/code/python/docker_server/docker-compose.unified.yml"

[ -d "$BACKUP_DIR" ] || { echo "backup dir not found: $BACKUP_DIR"; exit 1; }
for f in neo4j_data.tar.gz milvus_etcd_data.tar.gz milvus_minio_data.tar.gz postgres_all_databases.sql.gz; do
  [ -f "$BACKUP_DIR/$f" ] || { echo "missing $f"; exit 1; }
done

echo "[1/5] stop milvus + neo4j"
docker compose -f "$COMPOSE" stop milvus neo4j

echo "[2/5] restore minio + etcd (milvus)"
docker run --rm -v infra_minio-data:/dst -v "$BACKUP_DIR":/src alpine sh -c "rm -rf /dst/* && tar xzf /src/milvus_minio_data.tar.gz -C /dst"
docker run --rm -v infra_etcd-data:/dst -v "$BACKUP_DIR":/src alpine sh -c "rm -rf /dst/* && tar xzf /src/milvus_etcd_data.tar.gz -C /dst"

echo "[3/5] restore neo4j"
docker run --rm -v infra_neo4j-data:/dst -v "$BACKUP_DIR":/src alpine sh -c "rm -rf /dst/* && tar xzf /src/neo4j_data.tar.gz -C /dst"

echo "[4/5] restore postgres"
gunzip -c "$BACKUP_DIR/postgres_all_databases.sql.gz" | docker exec -i -e PGPASSWORD=postgres123 infra-postgres psql -U postgres -d postgres

echo "[5/5] start etcd -> minio -> milvus + neo4j"
docker compose -f "$COMPOSE" up -d etcd minio
docker compose -f "$COMPOSE" up -d milvus neo4j

echo "DONE. verify:"
docker compose -f "$COMPOSE" ps