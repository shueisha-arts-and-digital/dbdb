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

### Linux（Ubuntu）

MySQL と PostgreSQL は追加のパッケージが必要です。

MySQL（Ubuntu 24.04 以降）: t64 移行で `libaio.so.1` が `libaio.so.1t64` という名前になったため、MySQL が要求する `libaio.so.1` のリンクも作ります。

```
sudo apt-get update
sudo apt-get install -y libaio1t64 libnuma1 libmecab2 libssl3t64 libncurses6 libtinfo6
sudo ln -sf /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1
sudo ldconfig
```

MySQL（Ubuntu 22.04）: リンクは不要です。

```
sudo apt-get update
sudo apt-get install -y libaio1 libnuma1 libmecab2 libssl3 libncurses6 libtinfo6
```

PostgreSQL: Linux ではソースからビルドします。`initdb` は `en_US.UTF-8` ロケールを使うので、無ければ生成します。

```
sudo apt-get update
sudo apt-get install -y build-essential libreadline-dev zlib1g-dev locales
sudo locale-gen en_US.UTF-8
```

## インストール

```
git clone https://github.com/shueisha-arts-and-digital/dbdb.git
cd dbdb
```

clone 先のディレクトリ名は `dbdb` のままにしてください。スクリプトはパスに含まれる `/dbdb/<種別>` で DB の種別を判定します。

## ヘルプ

```
# 全体像（コマンド一覧、接続情報、データの置き場所）
./dbdb.sh --help

# 各コマンドの引数と挙動
./mysql/create.sh --help
```

MySQL / PostgreSQL / MongoDB / Redis の `connect.sh` は、名前の後ろの引数をクライアントにそのまま渡すので、対話シェルを開かずにクエリを実行できます。相対パスは実行したディレクトリを基準に解釈されます（Memcached はクライアントを同梱していないため、接続方法を表示するだけです）。

```
./mysql/connect.sh mysql1 -e 'SHOW DATABASES'
./postgresql/connect.sh pg1 -c 'SELECT version()'
./redis/connect.sh redis1 PING
```

## AI エージェント（Claude Code など）から使う

`skills/dbdb` に Agent Skill を同梱しています。インストールすると、他のプロジェクトで作業中でも「MySQL 8.0 を立てて」のような依頼でエージェントが dbdb を使えるようになります。

```
npx skills add shueisha-arts-and-digital/dbdb

# skill が dbdb の場所を見つけられるよう、clone 先を設定しておく
export DBDB_HOME=/path/to/dbdb
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

- 5.7.31 (macOS x86_64 / Linux x86_64)
- 8.0.23 (macOS x86_64 / Linux x86_64)
- 8.0.28 (macOS arm64 / Linux x86_64)
- 8.0.30 (macOS x86_64 / Linux x86_64)
- 8.0.41 (macOS arm64 / Linux x86_64)
- 8.0.42 (macOS arm64 / Linux x86_64)
- 8.4.4 (macOS arm64 / Linux x86_64)
- 9.2.0 (macOS arm64 / Linux x86_64)

</div></details>

<details><summary>PostgreSQL</summary><div>

## PostgreSQL

### Commands for PostgreSQL Server

```
./postgresql/{create|start|stop|restart|port|status|connect|delete}.sh {name} {postgresqlVersion} {port}

# e.g.
./postgresql/create.sh  pg1 12.6 5432
./postgresql/start.sh   pg1
./postgresql/stop.sh    pg1
./postgresql/restart.sh pg1
./postgresql/port.sh    pg1
./postgresql/status.sh  pg1
./postgresql/connect.sh pg1
./postgresql/delete.sh  pg1
```

### Supported PostgreSQL Versions

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

- 6.2.14
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
