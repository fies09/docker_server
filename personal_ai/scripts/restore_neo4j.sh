#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="/Users/fanyong/Desktop/data/数据库备份数据/20260310"
NEO4J_BACKUP="${BACKUP_ROOT}/neo4j/neo4j-data-20260310.tar.gz"
NEW_PASSWORD="neo4j123"
EXPECTED_OLD_PASSWORD="12345678"

echo "=== [1/7] Stop neo4j ==="
docker stop infra-neo4j >/dev/null 2>&1 || true

echo "=== [2/7] Backup current state ==="
docker run --rm \
  -v infra_neo4j-data:/data \
  -v "${BACKUP_ROOT}/neo4j":/backup \
  alpine sh -c "tar czf /tmp/neo4j-before.tar.gz -C /data . 2>/dev/null; cp /tmp/neo4j-before.tar.gz /backup/ 2>/dev/null || true"
echo "  saved backup of pre-restore state"

echo "=== [3/7] Clear volume ==="
docker run --rm -v infra_neo4j-data:/data alpine sh -c "rm -rf /data/* /data/.[!.]*"
echo "  volume cleared"

echo "=== [4/7] Extract backup ==="
docker run --rm \
  -v infra_neo4j-data:/data \
  -v "${BACKUP_ROOT}/neo4j":/backup \
  alpine sh -c "tar xzf /backup/neo4j-data-20260310.tar.gz -C /data && echo 'extracted'"
echo "  extraction complete"

echo "=== [5/7] Fix ownership (uid 7474) ==="
docker run --rm -v infra_neo4j-data:/data alpine sh -c "chown -R 7474:7474 /data && echo 'chown done'"

echo "=== [6/7] Start neo4j ==="
docker start infra-neo4j >/dev/null
echo "Waiting for healthy..."
until docker ps --format '{{.Names}} {{.Status}}' | grep -q 'infra-neo4j .*healthy'; do
  sleep 3
done
echo "  neo4j is healthy"

echo "=== [7/7] Probe auth and align password ==="
if docker exec infra-neo4j cypher-shell -u neo4j -p "$EXPECTED_OLD_PASSWORD" "RETURN 1;" >/dev/null 2>&1; then
  echo "  backup password works; rotating to ${NEW_PASSWORD}..."
  docker exec infra-neo4j cypher-shell -u neo4j -p "$EXPECTED_OLD_PASSWORD" \
    "ALTER USER neo4j SET PASSWORD '${NEW_PASSWORD}' CHANGE NOT REQUIRED;"
else
  echo "  backup password NOT ${EXPECTED_OLD_PASSWORD}; trying ${NEW_PASSWORD}..."
  if ! docker exec infra-neo4j cypher-shell -u neo4j -p "$NEW_PASSWORD" "RETURN 1;" >/dev/null 2>&1; then
    echo "ERROR: cannot authenticate with either password"
    exit 1
  fi
fi

echo "=== Verify ==="
docker exec infra-neo4j cypher-shell -u neo4j -p "$NEW_PASSWORD" \
  "SHOW DATABASES YIELD name; MATCH (n) RETURN count(n) AS nodes;"

echo "=== DONE ==="