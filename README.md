# DBDB

```
 ----------------------------------------------
< DBDB, What a great database version manager! >
 ----------------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
## Dependencies
- `nc`
- `wget` or `curl`

## インストール

```
git clone https://github.com/pj8/dbdb.git
cd dbdb
```

<details><summary>MySQL</summary><div>

## MySQL

### MySQL Server関連コマンド

```
./mysql/{create|start|stop|restart|port|status|connect|delete}.sh {name} {mysqlVersion} {port}

# 例: MySQL serverを作成する
./mysql/create.sh mysql1 8.0.41 3306

# そのほかの例
./mysql/start.sh   mysql1
./mysql/stop.sh    mysql1
./mysql/restart.sh mysql1
./mysql/port.sh    mysql1
./mysql/status.sh  mysql1
./mysql/connect.sh mysql1
./mysql/delete.sh  mysql1

# 例: 別のサーバーを作成する
./mysql/create.sh mysql2 9.2.0 13306

# 例: ランダムなポートで作成する
./mysql/create.sh mysql3 8.0.41 random

# 例: なければサーバーを作成してから、サーバーをスタートする
./mysql/create-start.sh mysql4 9.2.0 23306
```

### サポートしているMySQL Versions

- x86_64
  - 5.7.31 (x86_64)
  - 8.0.23 (x86_64)
  - 8.0.30 (x86_64)
- arm64
  - 8.0.28 (arm64)
  - 8.0.41 (arm64)
  - 8.4.4 (arm64)
  - 9.2.0 (arm64)

</div></details>

<details><summary>PostgreSQL</summary><div>

## PostgreSQL

### Commands for PostgreSQL Server

```
./postgresql/{create|start|stop|restart|port|status|connect|delete}.sh {name} {postgresqlVersion} {port}

# e.g.
./postgresql/create.sh  pg1 12.4 5432
./postgresql/start.sh   pg1
./postgresql/stop.sh    pg1
./postgresql/restart.sh pg1
./postgresql/port.sh    pg1
./postgresql/status.sh  pg1
./postgresql/connect.sh pg1
./postgresql/delete.sh  pg1
```

### Supported PostgreSQL Versions

- 12.4
- 12.6
- 13.2

</div></details>

<details><summary>Redis</summary><div>

## Redis

### Commands for Redis Server

```
./redis/{create|start|stop|restart|port|status|connect|delete}.sh {name} {redisVersion} {port}

# e.g.
./redis/create.sh  redis1 6.2.14 6379
./redis/start.sh   redis1
./redis/stop.sh    redis1
./redis/restart.sh redis1
./redis/port.sh    redis1
./redis/status.sh  redis1
./redis/connect.sh redis1
./redis/delete.sh  redis1
```

### Supported Redis Versions

- 6.0.16
- 6.2.14
- 7.0.15
- 7.2.5

</div></details>

<details><summary>MongoDB</summary><div>

## MongoDB

### Commands for MongoDB Server

```
./mongodb/{create|start|stop|restart|port|status|connect|delete}.sh {name} {mongodbVersion} {port}

# e.g.
./mongodb/create.sh  mongo1 8.0.11 27017
./mongodb/start.sh   mongo1
./mongodb/stop.sh    mongo1
./mongodb/restart.sh mongo1
./mongodb/port.sh    mongo1
./mongodb/status.sh  mongo1
./mongodb/connect.sh mongo1
./mongodb/delete.sh  mongo1
```

### Supported MongoDB Versions

- 6.0.24
- 7.0.21

</div></details>

<details><summary>Memcached</summary><div>

## Memcached

### Commands for Memcached Server

```
./memcached/{create|start|stop|restart|port|status|connect|delete}.sh {name} {memcachedVersion} {port}

# e.g.
./memcached/create.sh  memcached1 1.6.31 11211
./memcached/start.sh   memcached1
./memcached/stop.sh    memcached1
./memcached/restart.sh memcached1
./memcached/port.sh    memcached1
./memcached/status.sh  memcached1
./memcached/connect.sh memcached1
./memcached/delete.sh  memcached1
```

### Supported Memcached Versions

- 1.6.31

</div></details>

## Tips

### ランダムなポートで作成する

```
/path/to/dbdb/mysql/create.sh mysql5-foo 5.7.31 random
```

### ポートナンバーを表示する

```
/path/to/dbdb/mysql/port.sh mysql5-foo
```

### なければサーバーを作成してから、サーバーをスタートする

```
# Create and start
/path/to/dbdb/mysql/create-start.sh mysql5-foo 5.7.31 3306
```

### すべてのデータベースを表示するには？

- You can use `dbdb.sh` for that.

```
./dbdb.sh
```

### マシン起動時に自動でサーバを起動するには？

- [`crontab -e` with @reboot](https://man7.org/linux/man-pages/man5/crontab.5.html#EXTENSIONS)

```
# Start mysql5
@reboot /path/to/dbdb/mysql/start.sh mysql5-foo

# Start mysql8 with port 13306
@reboot /path/to/dbdb/mysql/start.sh mysql8-bar

# Create and start
@reboot /path/to/dbdb/redis/create-start.sh redis1 6.0.10 6379
```
