# How to Use the MySQL Images

## Pull database from cloud sql

```
  mysqldump --host=35.202.178.130 -u root -p --opt --single-transaction magestore_db_clone > docker-entrypoint-initdb.d/magestore_db.sql
```

## Build docker image

```
  docker build -t staging_mysql .
```

## Run docker image

With user name: staging, password: 8wCzfkp6DT9Ynt

```
  docker run -d --name staging_mysql \
  -p 3306:3306 -e MYSQL_USER=staging \
  -e MYSQL_PASSWORD=8wCzfkp6DT9Ynt \
  -e MYSQL_RANDOM_ROOT_PASSWORD=1 staging_mysql
```
