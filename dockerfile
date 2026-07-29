FROM php:8.4-fpm-alpine AS php

RUN apk add -U --no-cache curl-dev
RUN docker-php-ext-install curl

# 必要なビルドツールをインストール
RUN apk add --no-cache $PHPIZE_DEPS

# peclでAPCuをインストール
RUN pecl install apcu

# 拡張を有効化
RUN docker-php-ext-enable apcu
