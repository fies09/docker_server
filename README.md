# Docker环境检查

1, 检查 docker-compose 是否安装：`docker-compose --version`
2, 启动服务： docker-compose up -d
3, 查看已启动的服务： docker ps -a
4, 访问服务： [访问地址](http://localhost:8080)
5, 访问mysql服务： [http://localhost:8080/mysql](http://localhost:8080/mysql)
6, 以下实现 mysql凌晨 1 点定期备份
docker exec -it mysql-container bash
apt-get update && apt-get install cron
crontab -e
0 1 * * * /path/to/mysql_backup.sh
7, 以下实现每周一凌晨 3 点备份所有 Docker 镜像
crontab -e
0 3 * * 1 /Users/fanyong/Desktop/code/docker_server/docker_backup.sh

.env配置文件信息
MYSQL_PASSWORD="root"
MYSQL_DATABASE="mysql"
POSTGRES_USER="root"
POSTGRES_PASSWORD="root"
POSTGRES_DB="postgres"
RABBITMQ_USER="root"
RABBITMQ_PASSWORD="root"
REDIS_PASSWORD="root"