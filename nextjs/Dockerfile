# syntax=docker/dockerfile:1

# ベースイメージ
ARG NODE_VERSION
FROM node:${NODE_VERSION}-slim AS base

## システムパッケージインストール
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        vim \
        less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 開発環境イメージ
FROM base AS development

## 作業ディレクトリ設定
WORKDIR /app

## グローバルにNext.jsをインストール
ARG NEXTJS_VERSION
RUN npm install -g create-next-app@${NEXTJS_VERSION}
