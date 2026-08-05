# 📌 画像投稿機能付きWeb掲示板システム 構築手順書

> **【概要】**  
> 本手順書は、初期状態の **Amazon Linux (AWS EC2)** 環境において、CLI操作のみでWeb掲示板サービスを再現・構築・稼働させるための完全手順書です。

---

## 1. 📂 システム構成とディレクトリ構造

本システムは **Docker Compose** を使用し、以下の**3つのコンテナ**を連携させて動作します。

* **`web`** : **Nginx**（Webサーバー）
* **`php`** : **PHP-FPM**（アプリケーション実行環境）
* **`mysql`** : **MySQL**（データベース）

### **【プロジェクトのファイル構成】**

```text
suiyou3.4gen.kadai/
├── compose.yml              # コンテナ構成ファイル
├── Dockerfile               # PHP環境ビルドファイル
├── init.sql                 # データベース初期化SQL
├── README.md                # 本手順書
├── nginx/
│   └── conf.d/
│       └── default.conf     # Nginx設定ファイル
├── public/
│   └── bbsimagetest.php     # 掲示板プログラム本体
└── upload/
    └── image/               # 画像保存用ディレクトリ
```

---

## 2. 🛠️ 環境構築手順

> ⚠️ **前提条件**：初期状態の EC2 にSSH接続した直後の状態（ホームディレクトリ）から、順番に実行してください。

### 🔹 **ステップ1: パッケージのインストールと権限設定**

**【操作内容】**  
システムの更新、**Docker** および **Git** のインストールを行い、`ec2-user` でDockerを動かせるように権限を付与します。

```bash
sudo dnf update -y
sudo dnf install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

**【操作内容】**  
設定したグループ権限を**現在のターミナルセッションに即時反映**させます。

```bash
newgrp docker
```

**【操作内容】**  
複数コンテナを一括管理するための **`docker compose` プラグイン** をインストールします。

```bash
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL [https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64](https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64) -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
```

---

### 🔹 **ステップ2: リポジトリのクローン（ファイルの配置）**

**【操作内容】**  
GitHubからソースコード一式をサーバーへダウンロードし、作業ディレクトリへ移動します。

```bash
git clone https://github.com/eita0313/suiyou3.4gen.kadai.git　https://github.com/eita0313/suiyou3.4gen.kadai.git
cd suiyou3.4gen.kadai
```

---

### 🔹 **ステップ3: 画像保存用ディレクトリの準備**

**【操作内容】**  
投稿された画像ファイルを保持するためのディレクトリを作成し、**コンテナ側からの書き込み権限（777）**を付与します。

```bash
mkdir -p upload/image
chmod -R 777 upload/
```

---

### 🔹 **ステップ4: Dockerコンテナのビルドと起動**

**【操作内容】**  
構成ファイル（`compose.yml`）を元に、コンテナ群を**バックグラウンドで一括起動**します。

```bash
docker compose up -d --build
```

**【確認】**  
以下のコマンドを実行し、**3つのコンテナ（`web`, `php`, `mysql`）がすべて `Up` または `Running`** になっていることを確認します。

```bash
docker compose ps
```

---

### 🔹 **ステップ5: データベースの初期化（テーブル作成）**

> ⏳ **注意**：MySQLコンテナが完全に立ち上がるまで **10秒ほど待ってから** 実行してください。

**【操作内容】**  
同梱の `init.sql` を実行し、掲示板データ保存用の **`bbs_entries` テーブル** を作成します。

```bash
docker compose exec -T mysql mysql -u root example_db < init.sql
```

**【確認】**  
テーブルが正しく作成されたか確認します（`bbs_entries` と表示されれば成功です）。

```bash
docker compose exec -T mysql mysql -u root example_db -e "SHOW TABLES;"
```

---

### 🔹 **ステップ6: コンテナ内のアクセス権限の最終調整**

**【操作内容】**  
PHPコンテナ内の実行ユーザー（`www-data`）がアップロード領域に確実にファイルを書き込めるよう、**コンテナ内部の所有権と権限を確定**させます。

```bash
docker compose exec php chmod -R 777 /var/www/upload
docker compose exec php chown -R www-data:www-data /var/www/upload
```

---

## 3. ✅ 動作確認手順

構築完了後、Webブラウザを開き、以下のURLへアクセスしてテストを行います。

* 🌐 **アクセスURL**: `http://<EC2のパブリックIPアドレス>/bbsimagetest.php`

### **【検証チェックリスト】**

| 検証項目 | 操作手順 | **合格基準（期待される動作）** |
| :--- | :--- | :--- |
| **画面表示** | ブラウザでURLにアクセス | **投稿フォームおよび投稿一覧が正常に表示されること** |
| **新規投稿** | テキスト入力 ＋ **5MB以下の画像**を選択して送信 | **送信後、投稿したテキスト・画像・ID連番・日時が表示されること** |
| **サイズ制限** | **5MBを超える画像**を選択して送信を試みる | **警告アラートが表示され、送信が自動ブロックされること** |
