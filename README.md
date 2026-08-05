# 画像投稿機能付き掲示板サービス 構築手順書

本手順書は、初期状態の Amazon Linux サーバー（AWS EC2インスタンス）を想定し、CLI上のコマンド操作のみでWeb掲示板システムをゼロから構築・起動するための完全な手順です。

## 1. 前提条件とディレクトリ構造

本システムは Docker および Docker Compose を使用して構築します。
Gitからリポジトリをクローンした後のファイル構成は以下の状態になることを想定しています。

```text
suiyou3.4gen.kadai/
├── compose.yml
├── Dockerfile
├── README.md
├── init.sql
├── nginx/
│   └── conf.d/
│       └── default.conf
├── public/
│   └── bbsimagetest.php
└── upload/
    └── image/  (※構築手順内で作成します)
2. 環境構築手順
サーバーにSSH接続した直後の状態（ホームディレクトリ）から、以下のコマンドを上から順に実行してください。

ステップ1: パッケージの更新と必須ツールのインストール
まずはシステムを最新状態にし、構築に必要な docker と git をインストールします。

Bash
# パッケージのアップデート
sudo dnf update -y

# Docker と Git のインストール
sudo dnf install -y docker git

# Dockerサービスの起動と、OS再起動時の自動起動設定
sudo systemctl start docker
sudo systemctl enable docker

# 現在のユーザー(ec2-user)をdockerグループに追加し、sudoなしでDockerを操作できるようにする
sudo usermod -aG docker ec2-user
Docker Compose（V2）プラグインを手動でダウンロードしてインストールします。

Bash
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL [https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64](https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64) -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
【重要】 グループ追加の設定を現在のセッションに反映させるため、以下のコマンドを実行します。

Bash
newgrp docker
ステップ2: ソースコードの取得（クローン）
GitHubから本プロジェクトのファイルをダウンロードし、作業ディレクトリに移動します。
※環境依存のエラーを防ぐため、HTTPS経由でクローンします。

Bash
git clone [https://github.com/eita0313/suiyou3.4gen.kadai.git](https://github.com/eita0313/suiyou3.4gen.kadai.git)
cd suiyou3.4gen.kadai
ステップ3: 画像保存用ディレクトリの作成
リポジトリには空のディレクトリが含まれない場合があるため、画像を保存するための upload/image/ ディレクトリを手動で作成し、書き込み権限を付与します。

Bash
mkdir -p upload/image
chmod -R 777 upload/
ステップ4: Dockerコンテナのビルドと起動
用意された compose.yml と Dockerfile を元に、Nginx(Webサーバー)、PHP(アプリケーション)、MySQL(データベース)の3つのコンテナを構築し、バックグラウンドで起動します。

Bash
docker compose up -d --build
起動後、以下のコマンドですべてのコンテナ（web, php, mysql）のステータスが Up または Running になっていることを確認してください。

Bash
docker compose ps
ステップ5: データベースのテーブル作成 (初期化)
MySQLコンテナが完全に起動するまで約10〜15秒ほど待機した後、リポジトリ内の init.sql を使ってデータベース内に掲示板用のテーブル（bbs_entries）を作成します。

Bash
# データベースの初期化用SQLをMySQLコンテナに流し込む
docker compose exec -T mysql mysql -u root example_db < init.sql
ステップ6: アップロードディレクトリのパーミッション最終調整
Dockerのボリュームマウントが完了した後、コンテナ内部のPHPプロセス（www-dataユーザー）が、ホスト側のディレクトリへ確実に画像を書き込めるよう所有権と権限を調整します。

Bash
docker compose exec php chmod -R 777 /var/www/upload
docker compose exec php chown -R www-data:www-data /var/www/upload
構築作業は以上で完了です。
