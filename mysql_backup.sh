#!/bin/bash
DATE=$(date +%F_%T)
BACKUP_DIR="/backup"
MYSQL_USER="root"
MYSQL_PASSWORD="root"
MYSQL_DATABASE="mysql"

# 备份命令
mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $BACKUP_DIR/mysql_backup_$DATE.sql

# 删除 7 天前的备份
find $BACKUP_DIR -type f -name "*.sql" -mtime +7 -exec rm {} \;