---
name: dbdb
description: ローカル開発用の MySQL / PostgreSQL / MongoDB / Redis / Memcached を立てたい・起動停止したい・削除したいとき、特定バージョンの DB が必要なとき、ローカル DB の一覧・ポート・接続情報を知りたいとき、ローカル DB にクエリを流したいときに使う。「dbdb」「MySQL 8.0 を立てて」「Redis 起動して」「ローカルの DB 一覧」などの依頼が対象。
---

# dbdb

dbdb は、複数バージョンの DB インスタンスをローカルで作成・起動・停止・削除するシェルスクリプト群。使い方はすべて `--help` に書かれているので、この skill では dbdb の場所を特定し、help を読んでから操作する。

## 1. dbdb の場所を決める

1. 環境変数 `DBDB_HOME` が設定されていて `$DBDB_HOME/dbdb.sh` があれば、それを使う。
2. 無ければ、dbdb を clone 済みのパスをユーザーに尋ねる。未導入なら、clone してよいかと clone 先を確認してから `git clone https://github.com/shueisha-arts-and-digital/dbdb.git <親ディレクトリ>/dbdb` を実行する。ディレクトリ名が `dbdb` でないとスクリプトが DB 種別を判定できず動かない。
3. パスが決まったら、次回から探さずに済むよう、シェル設定に `export DBDB_HOME=<パス>` を追加することをユーザーに案内する。

## 2. help を読んでから操作する

- 最初に `"$DBDB_HOME/dbdb.sh" --help` を読む。コマンド一覧、接続情報、データの置き場所が載っている。
- 個々の操作は `"$DBDB_HOME/<type>/<command>.sh" --help` で引数と挙動を確認してから実行する。対応バージョンは `$DBDB_HOME/README.md` を見る。
- 既存インスタンスの把握には `"$DBDB_HOME/dbdb.sh" -f json` を使う。ユーザーに接続情報を伝えるときは、`port.sh <name>` で実際のポートを確かめ、`dbdb.sh --help` の接続情報と組み合わせる（port に `random` を指定するとポートは実行時に決まる）。
- `connect.sh` に名前だけを渡すと対話シェルが開いて応答が返らなくなる。クエリはクライアント引数を付けて実行する（例: `connect.sh mysql1 -e 'SELECT 1'`）。
- 初回 create はダウンロードやビルドで数分かかることがあるので、コマンドのタイムアウトを長めにする。

## 3. ユーザーに確認すること

- `delete.sh` は確認なしでデータを消し、元に戻せない。実行前に、対象のインスタンス名を示してユーザーの同意を得る。
- 自分がこの会話で作っていないインスタンスを stop / restart する前にも確認する。他の作業で使っている可能性がある。
