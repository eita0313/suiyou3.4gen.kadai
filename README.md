# 画像投稿機能付きWeb掲示板システム 構築手順書

本手順書は、初期状態の Amazon Linux（AWS EC2インスタンス）環境において、CLI操作のみでDockerコンテナ群を用いた画像投稿機能付きWeb掲示板を再現・構築し、正常にサービスを稼働させるための手順書です。

---

## 1. システム構成とファイル役割

本システムは、Docker Composeを用いて以下の3つのコンテナを連動させて稼働します。

* **Webコンテナ (`web`)**: Nginx (Webサーバー)  
  HTTPリクエストを受け持ち、PHPファイルへのアクセスを `php` コンテナへルーティングします。また、アップロードされた画像ファイルへの静的アクセスを処理します。
* **Appコンテナ (`php`)**: PHP-FPM (アプリケーションサーバー)  
  掲示板の本体ロジック (`bbsimagetest.php`) を実行します。DB操作、画像の検証および保存処理を担います。
* **DBコンテナ (`mysql`)**: MySQL (データベース)  
  投稿テキスト、投稿日時、画像ファイル名などのデータを保存・管理します。

### ディレクトリ構造

```text
suiyou3.4gen.kadai/
├── compose.yml              # 3つのコンテナ(Web, PHP, DB)の構成・ポート・ボリュームを定義する設定ファイル
├── Dockerfile               # PHPコンテナをビルドするためのファイル(PDO等の拡張機能を有効化)
├── init.sql                 # MySQLコンテナ起動時にデータベースとテーブルを初期化するSQLスクリプト
├── README.md                # 本手順書
├── nginx/
│   └── conf.d/
│       └── default.conf     # NginxのリバースプロキシおよびPHP連携・静的ファイル配信設定
├── public/
│   └── bbsimagetest.php     # 掲示板のフロントエンド(HTML/JS)およびバックエンド(PHP)ロジック
└── upload/
    └── image/               # 投稿された画像が保存されるディレクトリ(ホスト・コンテナ間で共有)
2. 環境構築手順
初期状態の Amazon Linux (EC2) にログインした状態から、以下の手順を順番に実行してください。

ステップ1: パッケージのインストールと初期設定
Bash
# パッケージインデックスの更新
sudo dnf update -y

# Docker および Git のインストール
sudo dnf install -y docker git

# Docker サービスの起動および自動開始設定
sudo systemctl start docker
sudo systemctl enable docker

# ec2-user に Docker の実行権限を付与
sudo usermod -aG docker ec2-user
権限変更を現在のターミナルセッションに反映させます。

Bash
newgrp docker
次に、docker compose プラグインをインストールします。

Bash
# プラグインディレクトリの作成
sudo mkdir -p /usr/libexec/docker/cli-plugins

# 最新の Docker Compose バイナリのダウンロード
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose

# 実行権限の付与
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
ステップ2: ソースコードの取得（リポジトリのクローン）
Bash
# リポジトリのクローン
git clone https://github.com/eita0313/suiyou3.4gen.kadai.git

# プロジェクトディレクトリへ移動
cd suiyou3.4gen.kadai
ステップ3: 保存用ディレクトリの作成と権限設定
Bash
# 保存先ディレクトリの作成
mkdir -p upload/image

# 書き込み権限の付与
chmod -R 777 upload/
ステップ4: Dockerコンテナの起動
Bash
# コンテナのビルドおよびバックグラウンド起動
docker compose up -d --build
起動状態を確認します。

Bash
docker compose ps
web, php, mysql の3つのコンテナが Up または Running になっていることを確認してください。

ステップ5: データベースの初期設定 (テーブル構築)
MySQLコンテナの起動完了まで 10〜15秒程度待機 した後、テーブルを作成します。

Bash
# 初期化SQLの実行
docker compose exec -T mysql mysql -u root example_db < init.sql
テーブルが作成されているか確認します。

Bash
docker compose exec -T mysql mysql -u root example_db -e "SHOW TABLES;"
出力結果に bbs_entries が表示されていれば正常です。

ステップ6: コンテナ内パーミッションの調整
Bash
# コンテナ内部の書き込み権限設定
docker compose exec php chmod -R 777 /var/www/upload
docker compose exec php chown -R www-data:www-data /var/www/upload
以上で構築作業は完了です。
