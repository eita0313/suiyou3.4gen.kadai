# 画像投稿機能付きWeb掲示板システム 構築手順書

本手順書は、初期状態の Amazon Linux（AWS EC2インスタンス）環境において、CLI操作のみでDockerコンテナ群を用いた画像投稿機能付きWeb掲示板を再現・構築し、正常にサービスを稼働させるための完全な手順書です。

---

## 1. システム構成とディレクトリ構造

本システムは、保守性およびポータビリティを高めるため、Docker Composeを用いて以下の3つのコンテナを連動させて稼働します。

* **Webコンテナ (`web`)**: Nginx (Webサーバー)  
  HTTPリクエストを受け持ち、PHPファイルへのアクセスを `php` コンテナへルーティングします。また、アップロードされた画像ファイルへの静的アクセスを処理します。
* **Appコンテナ (`php`)**: PHP-FPM (アプリケーションサーバー)  
  掲示板の本体ロジック (`bbsimagetest.php`) を実行します。DB操作、画像の検証および保存処理を担います。
* **DBコンテナ (`mysql`)**: MySQL (データベース)  
  投稿テキスト、投稿日時、画像ファイル名などのデータを保存・管理します。

### リポジトリ構成と各ファイルの役割

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
2. 環境構築手順 (ステップ・バイ・ステップ)
初期状態の Amazon Linux（EC2）にログインした状態から、以下の手順を順番に実行してください。

ステップ1: ホストOSの準備と必要パッケージのインストール
システムを最新化し、コンテナ環境に必要な docker とソースコード取得に必要な git をインストールします。

Bash
# パッケージインデックスの更新
sudo dnf update -y

# Docker および Git のインストール
sudo dnf install -y docker git

# Docker サービスの起動および OS 起動時の自動開始設定
sudo systemctl start docker
sudo systemctl enable docker

# ec2-user に Docker の実行権限を付与 (sudo無しの操作を許可)
sudo usermod aG docker ec2-user
権限変更を再ログインすることなく現在のターミナルセッションに反映させます。

Bash
newgrp docker
次に、複数コンテナを一括管理するための docker compose プラグインをインストールします。

Bash
# プラグインディレクトリの作成
sudo mkdir -p /usr/libexec/docker/cli-plugins

# 最新の Docker Compose バイナリのダウンロード
sudo curl -SL [https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64](https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64) -o /usr/libexec/docker/cli-plugins/docker-compose

# 実行権限の付与
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
ステップ2: ソースコードの取得（リポジトリのクローン）
GitHub上のパブリックリポジトリから、構成ファイル一式をサーバーローカルへ設置します。

Bash
# リポジトリのクローン (HTTPS経由)
git clone [https://github.com/eita0313/suiyou3.4gen.kadai.git](https://github.com/eita0313/suiyou3.4gen.kadai.git)

# 作成されたプロジェクトディレクトリへ移動
cd suiyou3.4gen.kadai
ステップ3: 画像永続化用ディレクトリの作成と権限付与
投稿された画像をコンテナの停止・削除後も保持（永続化）させるため、ホスト側に保存先ディレクトリを作成し、コンテナ内から書き込みができるよう権限を開放します。

Bash
# 保存先ディレクトリの作成
mkdir -p upload/image

# 全ユーザーに対する書き込み権限の付与
chmod -R 777 upload/
ステップ4: Dockerコンテナのビルドおよび起動
compose.yml の定義に従い、Web、PHP、MySQLの各イメージをビルドし、バックグラウンドで起動します。

Bash
docker compose up -d --build
起動確認を行います。

Bash
docker compose ps
web (Nginx)、php (PHP-FPM)、mysql (MySQL) の3つのコンテナ状態がすべて Up または Running になっていることを確認してください。

ステップ5: データベースの初期設定 (テーブル構築)
MySQLコンテナが内部の初期化処理を完了するまで 10〜15秒程度待機 した後、同梱の init.sql を実行して bbs_entries テーブルを作成します。

Bash
# MySQLコンテナに対し init.sql を流し込み、テーブル構造を構築
docker compose exec -T mysql mysql -u root example_db < init.sql
テーブルが作成されていることを確認します。

Bash
docker compose exec -T mysql mysql -u root example_db -e "SHOW TABLES;"
出力結果に bbs_entries が表示されていれば正常です。

ステップ6: コンテナ内パーミッションの確定調整
Dockerボリュームマウントが適用された後、PHPコンテナ内の実行ユーザー (www-data) がアップロードディレクトリへ確実に書き込みを行えるよう、コンテナ内部から最終的なアクセス権限を設定します。

Bash
# コンテナ内部の /var/www/upload に対する所有権とパーミッション設定
docker compose exec php chmod -R 777 /var/www/upload
docker compose exec php chown -R www-data:www-data /var/www/upload
以上ですべての構築作業が完了です。
