# Docker Services Connection Info

## PostgreSQL
- **Host**: 192.168.124.49
- **Port**: 5432
- **Username**: root
- **Password**: 123456
- **Database**: postgres
- **Connection String**: `postgresql://root:123456@192.168.124.49:5432/postgres`
- **Status**: ✅ 已测试连接正常

## Redis
- **Host**: 192.168.124.49
- **Port**: 6379
- **Username**: (无需用户名)
- **Password**: root
- **Connection String**: `redis://:root@192.168.124.49:6379`
- **Status**: ✅ 已测试连接正常

## Neo4j
- **Host**: 192.168.124.49
- **HTTP Port**: 7474
- **Bolt Port**: 7687
- **Username**: neo4j
- **Password**: 12345678
- **Browser URL**: http://192.168.124.49:7474
- **Bolt Connection**: `bolt://neo4j:12345678@192.168.124.49:7687`
- **Status**: ✅ 已测试连接正常

## Milvus
- **Host**: 192.168.124.49
- **Port**: 19530 (gRPC)
- **Web UI Port**: 9091
- **Username**: root (已启用认证)
- **Password**: Milvus
- **Connection**: `192.168.124.49:19530`
- **Version**: 2.6.1
- **Authentication**: ✅ 已启用 (authorizationEnabled=true)
- **Collections**: chat_memory_local, langgraph_workflow
- **Status**: ✅ 已测试连接正常

### Milvus 连接方式

**Python连接示例 (推荐使用认证)**:
```python
from pymilvus import connections

# 方式1: 带认证连接 (推荐,更安全)
connections.connect(
    host='192.168.124.49',
    port='19530',
    user='root',
    password='Milvus'
)

# 方式2: 无认证连接 (向后兼容,不推荐)
# 注意: 当前已启用认证,无认证连接会失败
connections.connect(
    host='192.168.124.49',
    port='19530'
)
```

**重要说明**:
- Milvus 已启用认证,必须使用 `root/Milvus` 才能连接
- 默认管理员账号: `root`
- 默认密码: `Milvus`
- 配置文件: `/e/code/fy/docker_server/milvus/user.yaml`
- 生产环境建议修改默认密码

## MinIO (Milvus存储后端)
- **Host**: 192.168.124.49
- **API Port**: 9000
- **Console Port**: 9001
- **Access Key**: minioadmin
- **Secret Key**: minioadmin
- **Console URL**: http://192.168.124.49:9001
- **Status**: ✅ Running

---

## 连接测试汇总

| 服务 | 地址 | 端口 | 认证 | 状态 |
|------|------|------|------|------|
| PostgreSQL | 192.168.124.49 | 5432 | root/123456 | ✅ |
| Redis | 192.168.124.49 | 6379 | root | ✅ |
| Neo4j | 192.168.124.49 | 7687 | neo4j/12345678 | ✅ |
| Milvus | 192.168.124.49 | 19530 | root/Milvus | ✅ |

**最后测试时间**: 2025-12-10

**所有服务连接配置均已验证可用**
