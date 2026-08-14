#!/bin/bash
# PostgreSQL 多数据库初始化脚本
# 自动创建 personal_ai_db 和 my_assistant_db

set -e

# 从环境变量获取数据库列表
IFS=',' read -ra DATABASES <<< "$POSTGRES_MULTIPLE_DATABASES"

for db in "${DATABASES[@]}"; do
    db=$(echo "$db" | xargs)  # 去除空格
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE DATABASE "$db";
        GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$POSTGRES_USER";
EOSQL
    echo "Database $db created successfully"
done

echo "All databases created!"
