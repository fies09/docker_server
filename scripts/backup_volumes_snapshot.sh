#!/bin/bash
set -euo pipefail

PROJECT_DIR="/Users/fanyong/Desktop/code/python/docker_server"
BACKUP_BASE="$PROJECT_DIR/数据库数据备份"
LOG_FILE="$BACKUP_BASE/backup.log"

DATE=$(date +%Y%m%d)
SNAPSHOT_DIR="$BACKUP_BASE/snapshot_$DATE"
INCREMENTAL_DIR="$BACKUP_BASE/${DATE}_incremental"

# 卷配置：卷名:快照子目录
VOLUMES=(
  "xaga-minio-data:minio"
  "infra_neo4j-data:neo4j"
  "infra_postgres-data:postgres_vol"
)

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

find_last_snapshot() {
  find "$BACKUP_BASE" -maxdepth 1 -type d -name "snapshot_*" | sort | tail -1
}

get_size_bytes() {
  local path=$1
  if [ -d "$path" ]; then
    du -sk "$path" 2>/dev/null | awk '{print $1 * 1024}' || echo 0
  else
    stat -f%z "$path" 2>/dev/null || echo 0
  fi
}

backup_volume() {
  local volume=$1
  local name=$2
  local last_snapshot=$3

  log "备份卷 $volume -> $SNAPSHOT_DIR/$name"

  if ! docker volume inspect "$volume" >/dev/null 2>&1; then
    log "  跳过: 卷不存在"
    return
  fi

  mkdir -p "$SNAPSHOT_DIR"

  # 硬链接基准
  if [ -n "$last_snapshot" ] && [ -d "$last_snapshot/$name" ]; then
    cp -al "$last_snapshot/$name" "$SNAPSHOT_DIR/$name" 2>/dev/null || cp -a "$last_snapshot/$name" "$SNAPSHOT_DIR/$name"
  else
    mkdir -p "$SNAPSHOT_DIR/$name"
  fi

  # 容器内rsync
  docker run --rm \
    -v "$volume:/source:ro" \
    -v "$SNAPSHOT_DIR:/dest" \
    alpine:latest \
    sh -c "apk add --no-cache rsync >/dev/null 2>&1 && rsync -a --delete /source/ /dest/$name/"

  local size=$(du -sh "$SNAPSHOT_DIR/$name" 2>/dev/null | awk '{print $1}')
  log "  完成 ($size)"
}

pack_snapshot() {
  log "打包快照..."
  local count=0

  for dir in "$SNAPSHOT_DIR"/*/; do
    [ -d "$dir" ] || continue
    local name=$(basename "$dir")

    # 跳过小于10KB的
    local size_kb=$(du -sk "$dir" 2>/dev/null | awk '{print $1}')
    if [ -z "$size_kb" ] || [ "$size_kb" -lt 10 ]; then
      log "  跳过 $name (空卷 ${size_kb}KB)"
      continue
    fi

    log "  打包 $name (${size_kb}KB)..."
    tar czf "$INCREMENTAL_DIR/${name}_data.tar.gz" -C "$SNAPSHOT_DIR" "$name"
    count=$((count + 1))
  done

  log "打包完成: $count 个tar.gz"
}

cleanup_old() {
  log "清理旧备份..."
  cd "$BACKUP_BASE"
  ls -1td snapshot_* 2>/dev/null | tail -n +4 | xargs -r rm -rf
  ls -1td *_incremental 2>/dev/null | tail -n +3 | xargs -r rm -rf
  log "完成"
}

main() {
  log "=== 开始增量备份 ==="
  mkdir -p "$INCREMENTAL_DIR"

  local last_snapshot=$(find_last_snapshot)
  [ -n "$last_snapshot" ] && log "基准快照: $(basename $last_snapshot)" || log "无基准快照"

  for item in "${VOLUMES[@]}"; do
    volume="${item%%:*}"
    name="${item##*:}"
    backup_volume "$volume" "$name" "$last_snapshot"
  done

  pack_snapshot
  cleanup_old

  log "=== 备份完成 ==="
  log "  快照: $SNAPSHOT_DIR ($(du -sh "$SNAPSHOT_DIR" | awk '{print $1}'))"
  log "  打包: $INCREMENTAL_DIR ($(du -sh "$INCREMENTAL_DIR" | awk '{print $1}'))"

  if [ -d "$INCREMENTAL_DIR" ]; then
    log "  tar列表:"
    ls -lh "$INCREMENTAL_DIR"/*.tar.gz 2>/dev/null | awk '{print "    "$5" "$9}' | tee -a "$LOG_FILE"
  fi
}

main "$@"