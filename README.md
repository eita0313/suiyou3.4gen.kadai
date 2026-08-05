# 画像投稿機能付きWeb掲示板システム 構築手順書

本手順書は、初期状態の Amazon Linux（AWS EC2）環境において、CLI操作のみでWeb掲示板を構築・稼働させるための手順書です。

---

## 1. システム構成とディレクトリ構造

本システムは Docker Compose を使用して以下の3つのコンテナで構成されます。

* **web**: Nginx（Webサーバー）
* **php**: PHP-FPM（アプリケーション実行環境）
* **mysql**: MySQL（データベース）

suiyou3.4gen.kadai/
├── compose.yml              # コンテナ構成ファイル
├── Dockerfile               # PHP環境ビルドファイル
├── init.sql                 # データベース初期化SQL
├── README.md                # 本手順書
├── nginx/
│   └── conf.d/
│       └── default.conf     # Nginx設定ファイル
├── public/
│   └── bbsimagetest.php     # 掲示板プログラム
└── upload/
└── image/               # 画像保存ディレクトリ


---

## 2. 環境構築手順

初期状態の EC2 にログインした直後の状態から、以下のコマンドを順番に実行してください。

### ステップ1: パッケージのインストールと初期設定

システムの更新、Docker・Gitのインストール、および権限設定を行います。

```bash
sudo dnf update -y
sudo dnf install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
グループ変更を現在のセッションに反映させます。

Bash
newgrp docker
docker compose プラグインをインストールします。

Bash
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
ステップ2: リポジトリのクローン
ソースコードをサーバーにダウンロードし、ディレクトリへ移動します。

Bash
git clone https://github.com/eita0313/suiyou3.4gen.kadai.git
cd suiyou3.4gen.kadai
ステップ3: 画像保存用ディレクトリの作成
画像を保存するためのディレクトリを作成し、書き込み権限を付与します。

Bash
mkdir -p upload/image
chmod -R 777 upload/
ステップ4: Dockerコンテナの起動
コンテナ群をビルドし、バックグラウンドで起動します。

Bash
docker compose up -d --build
コンテナの起動状態を確認します（すべて Up または Running になればOK）。

Bash
docker compose ps
ステップ5: データベースの初期設定
MySQLの起動完了まで 10秒ほど待機 した後、初期化SQLを実行してテーブルを作成します。

Bash
docker compose exec -T mysql mysql -u root example_db < init.sql
テーブルが作成されたか確認します。

Bash
docker compose exec -T mysql mysql -u root example_db -e "SHOW TABLES;"
ステップ6: コンテナ内の書き込み権限設定
PHPコンテナ側から画像を正常に保存できるよう、最終的なアクセス権限を設定します。

Bash
docker compose exec php chmod -R 777 /var/www/upload
docker compose exec php chown -R www-data:www-data /var/www/upload
構築作業は以上で完了です。
