# Docker环境检查

1, 检查 docker-compose 是否安装：`docker-compose --version`
2, 启动服务： docker-compose up -d
3, 查看已启动的服务： docker ps -a
4, 访问服务： [访问地址](http://localhost:8080)
5, 访问mysql服务： [http://localhost:8080/mysql](http://localhost:8080/mysql)
6, 停止服务： docker-compose down
7，重启服务： docker-compose restart / 重新启动并应用更改： docker-compose up -d --force-recreate
8，备份服务： docker-compose backup
9，恢复服务： docker-compose restore
10，删除服务： docker-compose rm
11，删除服务并删除数据： docker-compose rm -f
