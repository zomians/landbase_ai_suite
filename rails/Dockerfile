# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim AS base

## システムパッケージインストール
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        libyaml-dev \
        libpq-dev \
        postgresql-client \
        ca-certificates \
        curl \
        gnupg \
        vim \
        less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Node.js, Yarn インストール
ARG NODE_VERSION
ARG YARN_VERSION
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$(echo ${NODE_VERSION} | cut -d. -f1).x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable \
    && corepack prepare yarn@${YARN_VERSION} --activate

# 開発環境イメージ
FROM base AS development

## Railsインストール
ARG RAILS_VERSION
RUN gem install rails -v ${RAILS_VERSION} --no-document
