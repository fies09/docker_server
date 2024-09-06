#!/bin/bash
DATE=$(date +%F)
BACKUP_DIR="docker_backup"

# 备份所有镜像
docker images | grep -v REPOSITORY | awk '{print $1 ":" $2}' | while read image; do
  docker save $image -o $BACKUP_DIR/${image//\//_}_${DATE}.tar
done