#!/bin/bash

source .env

DATE=$(date +%F_%T)
BACKUP_DIR="./backup"  # 确保主机上的 ./backup 目录存在并映射到容器中的 /backup

# 在 Docker 容器内执行 mysqldump，并将备份存储在主机的 ./backup 目录中
docker exec mysql-container mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $BACKUP_DIR/mysql_backup_$DATE.sql

# 删除 7 天前的备份
find $BACKUP_DIR -type f -name "*.sql" -mtime +7 -exec rm {} \;