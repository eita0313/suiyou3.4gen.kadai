
FROM php:8.2-fpm AS php

# 必要な拡張機能（PDO MySQLなど）をインストール
RUN docker-php-ext-install pdo pdo_mysql

# 画像保存用フォルダを作成して権限を設定
RUN install -o www-data -g www-data -d /var/www/upload/image/

# PHPのアップロード上限を5MBに設定
RUN echo "upload_max_filesize = 5M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 5M" >> /usr/local/etc/php/conf.d/uploads.ini


