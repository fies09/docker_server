# milvus/ 数据目录（编排已合并）

> ⚠️ 旧独立编排 `milvus/docker-compose.yml` 已于 `945fa76` 合并到
> `infra/docker-compose.yml`，本目录仅保留数据卷：
>
> - `volumes/etcd/`   — etcd 元数据（原 standalone 依赖）
> - `volumes/minio/`  — 对象存储 a-bucket（67G，⚠️ 不可删）
> - `volumes/milvus/` — standalone 本地存储
>
> 启动命令：`cd ../infra && bash docker.sh up`（8 服务，含 milvus 三件套 + Attu）
> Attu UI：http://localhost:30000
