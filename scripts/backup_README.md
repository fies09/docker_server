# 备份系统

## 文件
- `backup_volumes_snapshot.sh` - 增量备份主脚本（rsync硬链接快照）
- `restore_from_snapshot.sh` - 从快照恢复

## 工作原理

每次备份创建 `snapshot_YYYYMMDD/` 目录，使用 rsync `--link-dest` 复用上次的未变文件：
- 相同文件不重复存储（硬链接复用）
- 备份空间 = 实际差异数据量
- 保留3个快照 + 2个打包目录

## 备份结构
```
数据库数据备份/
├── snapshot_20260826/          # 硬链接快照（增量）
│   ├── minio/                  # ~变化部分
│   ├── etcd/
│   ├── neo4j/
│   └── postgres/all_databases.sql.gz
├── snapshot_20260827/          # 下次快照（基于上次硬链接）
├── 20260826_incremental/        # 打包的tar.gz
│   ├── minio_data.tar.gz
│   └── ...
└── backup.log
```

## 使用方法

```bash
# 执行备份（建议挂cron每周一次）
cd ~/Desktop/code/python/docker_server
bash scripts/backup_volumes_snapshot.sh

# 列出可用快照
ls -d 数据库数据备份/snapshot_*

# 从快照恢复
bash scripts/infra/restore_from_snapshot.sh snapshot_20260826
```

## 空间节省

旧方案（全量tar）：
- 每次 97GB
- 保留2次 = 194GB

新方案（rsync硬链接）：
- 首次全量 ~95GB
- 后续增量 1-5GB/次
- 保留3次 = ~100GB