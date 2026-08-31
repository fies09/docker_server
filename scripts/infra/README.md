# scripts/infra - 基础设施编排脚本

存放 docker_server 根目录级别的统一基础设施维护脚本，与具体项目无关。

## 文件清单

| 脚本 | 用途 |
|------|------|
| `restore_volumes.sh` | 一键恢复 milvus/neo4j/postgres 物理 volume（停服务→解包→启服务） |
| `migrate-to-unified.sh` | 将 personal_ai / my_assistant 旧服务迁移到统一 infra stack（迁移已完成，仅作参考） |
| `migrate-check.sh` | 迁移前环境校验（迁移已完成，仅作参考） |
| `docker.sh` | docker compose 常用命令封装（指向 `infra/docker-compose.yml`） |

## restore_volumes.sh 用法

```bash
bash scripts/infra/restore_volumes.sh
# 默认从 /Users/fanyong/Desktop/code/python/docker_server/数据库数据备份/20260821_volume_backup 恢复
bash scripts/infra/restore_volumes.sh /path/to/backup_dir
```

脚本会：
1. 停 milvus / neo4j
2. 解 tar.gz 到 `infra_minio-data` / `infra_etcd-data` / `infra_neo4j-data`
3. `gunzip | psql` 灌入 postgres
4. 按 etcd → minio → milvus + neo4j 顺序启动

## 依赖

- compose 文件: `infra/docker-compose.yml`（name: infra）
- 备份目录需包含 `neo4j_data.tar.gz` / `milvus_etcd_data.tar.gz` / `milvus_minio_data.tar.gz` / `postgres_all_databases.sql.gz`