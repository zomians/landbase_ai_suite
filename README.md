# LandBase AI Suite

**AI ドリブン経営支援プラットフォーム**
沖縄県北部の観光業向けマルチテナント自動化スイート

---

## 📋 目次

- [概要](#概要)
- [ビジネスコンテキスト](#ビジネスコンテキスト)
- [技術スタック](#技術スタック)
- [セットアップ手順](#セットアップ手順)
- [クライアント管理](#クライアント管理)
- [開発ワークフロー](#開発ワークフロー)
- [プロジェクト構成](#プロジェクト構成)
- [ライセンス](#ライセンス)

---

## 概要

LandBase AI Suite は、沖縄県北部の小規模観光業（ホテル、飲食店、ツアー会社など）向けに開発された **SaaS 型マルチテナントプラットフォーム** です。各クライアント（法人・個人事業主）に対して、専用の自動化環境とコミュニケーションツールを提供します。

### 主な特徴

- 🏢 **マルチテナントアーキテクチャ**: 1 つのプラットフォームで 100+クライアントを管理
- 🤖 **n8n 自動化**: クライアント毎に独立した n8n コンテナで業務自動化
- 💬 **Mattermost 統合**: チームコミュニケーション基盤
- 📊 **PostgreSQL 共有**: スキーマ分離によるデータ隔離
- 🚀 **コマンドベースの自動構築**: 標準化されたコマンドでクライアント環境を迅速にプロビジョニング

---

## ビジネスコンテキスト

### 企業情報

- **会社名**: 株式会社 AI.LandBase
- **事業内容**: AI ドリブン経営コンサルティング
- **対象地域**: 沖縄県北部（やんばる地域）
- **対象業種**: 観光業（ホテル、飲食店、ツアー会社）

### 課題と解決策

#### 課題

- 小規模事業者（従業員~10 名）が多く、IT 投資余力が限定的
- 予約管理、SNS 投稿、在庫管理などの手作業が負担
- 個別にシステム導入するとコストが高い

#### 解決策

- **SaaS 型提供**: 初期投資を抑えたサブスクリプションモデル
- **業種別テンプレート**: ホテル・飲食店・ツアー向けの事前設定ワークフロー
- **段階的導入**: トライアル → 本格運用へのスムーズな移行

### スケール目標

- **Phase 1**: 5-10 クライアント（Proof of Concept）
- **Phase 2**: 50 クライアント
- **Phase 3**: 100+クライアント

---

## 技術スタック

### インフラストラクチャ層

| 技術               | バージョン | 用途               |
| ------------------ | ---------- | ------------------ |
| **Docker**         | -          | コンテナ化         |
| **Docker Compose** | -          | マルチコンテナ管理 |
| **PostgreSQL**     | 16-alpine  | データベース       |

### 自動化・コミュニケーション層

| 技術           | バージョン | 用途                       |
| -------------- | ---------- | -------------------------- |
| **n8n**        | 1.119.2    | ワークフロー自動化エンジン |
| **Mattermost** | 9.11       | チームコミュニケーション   |

### アプリケーション層（将来実装）

| 技術              | バージョン | 用途           |
| ----------------- | ---------- | -------------- |
| **Ruby on Rails** | 8.0.2.1    | API Backend    |
| **Next.js**       | 15.1.6     | Marketing Site |
| **Flutter**       | 3.32.5     | Mobile/Web App |

### スクリプト・自動化

| 技術     | 用途                                                                    |
| -------- | ----------------------------------------------------------------------- |
| **Ruby** | YAML 操作、データ処理 (add_client.rb, generate_client_compose.rb)       |
| **Bash** | Docker 操作、プロビジョニング (provision_client.sh) |

---

## ディレクトリ構成

```
landbase_ai_suite/
├── .env                          # 環境変数設定（共通）
├── .env.local.example            # 機密情報テンプレート
├── compose.yaml                  # Platform サービス定義
├── compose.client.*.yaml         # クライアント専用 n8n 定義（自動生成）
├── Makefile                      # 統一コマンドインターフェース
├── README.md                     # プロジェクトドキュメント
│
├── config/                       # 設定ファイル
│   └── client_list.yaml          # クライアントレジストリ（マスターデータ）
│
├── docs/                         # 詳細ドキュメント
│
├── scripts/                      # 自動化スクリプト
│   ├── add_client.rb             # クライアント登録
│   ├── generate_client_compose.rb # Docker Compose生成
│   ├── provision_client.sh       # クライアント環境構築
│
├── n8n/                          # n8n関連
│   └── workflows/                # ワークフロー定義
│       └── line-to-gdrive.json   # LINE Bot → Google Drive
│
├── rails/                        # Rails 開発環境
│   └── Dockerfile                # Rails 用 Dockerfile
│
└── nextjs/                       # Next.js 開発環境
    └── Dockerfile                # Next.js 用 Dockerfile
```

---

## セットアップ手順

### 前提条件

- Docker Desktop インストール済み
- Ruby 3.x インストール済み
- macOS または Linux 環境

### アクセス情報

#### Platform n8n (社内管理用)

- URL: http://localhost:5678
- 初回アクセス時に管理者アカウントを作成

#### Mattermost

- URL: http://localhost:8065
- 初回アクセス時に管理者アカウントを作成

---

## クライアント管理

### クライアント追加フロー

```bash
# 1. クライアント登録
make add-client \
  CODE=hotel_sunrise \
  NAME="Sunrise Beach Hotel" \
  INDUSTRY=hotel \
  EMAIL=info@sunrise-hotel.com

# 出力例:
# ✅ クライアント追加成功!
# 📋 クライアント情報:
#   コード: hotel_sunrise
#   名前: Sunrise Beach Hotel
#   業種: hotel
#   n8n Port: 5680
#   n8n Email: admin-hotel-sunrise@landbase.ai
#   パスワード: Xyz9Abc3Def7Ghi2

# 2. 環境プロビジョニング
make provision-client CODE=hotel_sunrise

# 自動実行される処理:
# - Docker Compose ファイル生成
# - n8n コンテナ起動 (Port 5680)
# - n8n オーナー作成
```

### クライアント一覧表示

```bash
make list-clients

# 出力例:
# ========================================
# 📋 登録クライアント一覧
# ========================================
#
# 1. shrimp_shells
#    名前: Shrimp Shells
#    業種: restaurant
#    状態: trial
#    Email: info@shrimpshells.com
#    n8n Port: 5679
#    n8n URL: http://localhost:5679
#
# 2. hotel_sunrise
#    名前: Sunrise Beach Hotel
#    業種: hotel
#    状態: trial
#    Email: info@sunrise-hotel.com
#    n8n Port: 5680
#    n8n URL: http://localhost:5680
```

### クライアント削除

```bash
make remove-client CODE=hotel_sunrise
```

**自動実行される処理:**

1. Docker コンテナの停止・削除（ボリュームも含む）
2. 生成された Docker Compose ファイルの削除
3. `client_list.yaml` からクライアント情報の削除

**注意:** この操作により、クライアントの n8n ワークフローデータも完全に削除されます。

### クライアントデータ構造

`config/client_list.yaml` の構造:

```yaml
clients:
  - code: shrimp_shells # 一意識別子（スネークケース）
    name: Shrimp Shells # 表示名
    industry: restaurant # 業種 (hotel/restaurant/tour)
    subdomain: shrimp-shells # 将来のサブドメイン用（ケバブケース）
    contact:
      email: info@shrimpshells.com # 連絡先
    services:
      n8n:
        enabled: true
        port: 5679 # 自動割り当て（5679から開始）
        owner_email: admin-shrimp-shells@landbase.ai
        owner_password: KFsegssdUKmx5SAR # 自動生成
        db_schema: n8n_shrimp_shells
        workflows: []
      mattermost:
        enabled: true
        team_name: Shrimp Shells Team
        admin_username: shrimp_shells_admin
        admin_email: info@shrimpshells.com
        admin_password: KFsegssdUKmx5SAR
    status: trial # trial/active/suspended
    created_at: "2025-11-13 14:00:57 +0900"
```

---

## 開発ワークフロー

### 主要コマンド一覧

```bash
# サービス管理
make up                    # サービス起動
make down                  # サービス停止
make logs                  # 全サービスログ表示
make clean                 # 完全クリーンアップ（Docker イメージ・ボリューム削除）

# n8n 管理
make n8n-logs              # n8n ログ表示

# Mattermost 管理
make mattermost-logs       # Mattermost ログ表示

# PostgreSQL 管理
make postgres-logs         # PostgreSQL ログ表示
make postgres-shell        # PostgreSQL シェル接続

# クライアント管理
make add-client            # クライアント追加
make provision-client      # クライアント環境構築
make list-clients          # クライアント一覧
make remove-client         # クライアント削除


```

### スクリプト概要

| スクリプト                   | 用途                                         | Make コマンド                      |
| ---------------------------- | -------------------------------------------- | ---------------------------------- |
| `add_client.rb`              | クライアント情報を `client_list.yaml` に登録 | `make add-client`                  |
| `generate_client_compose.rb` | クライアント専用 Docker Compose ファイル生成 | `make provision-client` で自動実行 |
| `provision_client.sh`        | クライアント環境の完全自動構築               | `make provision-client`            |
 

詳細は各スクリプトのコメントを参照してください。

---

## プロジェクト構成

```
landbase_ai_suite/
├── .env                          # 環境変数設定（共通）
├── .env.local.example            # 機密情報テンプレート
├── compose.yaml                  # Platform サービス定義
├── compose.client.*.yaml         # クライアント専用 n8n 定義（自動生成）
├── Makefile                      # 統一コマンドインターフェース
├── README.md                     # プロジェクトドキュメント
│
├── config/                       # 設定ファイル
│   └── client_list.yaml          # クライアントレジストリ（マスターデータ）
│
├── docs/                         # 詳細ドキュメント
│   └── sns-marketing-trends-2025.md
│
├── scripts/                      # 自動化スクリプト
│   ├── add_client.rb             # クライアント登録
│   ├── generate_client_compose.rb # Docker Compose生成
│   ├── provision_client.sh       # クライアント環境構築
│   └── setup_n8n_owner.sh        # Platform n8n 初期化
│
├── n8n/                          # n8n関連
│   └── workflows/                # ワークフロー定義
│       └── line-to-gdrive.json   # LINE Bot → Google Drive
│
├── rails/                        # Rails 開発環境
│   └── Dockerfile                # Rails 用 Dockerfile
│
└── nextjs/                       # Next.js 開発環境
    └── Dockerfile                # Next.js 用 Dockerfile
```

---

## ライセンス

All rights reserved. © 株式会社 AI.LandBase

---

## 連絡先

- **会社**: 株式会社 AI.LandBase
- **GitHub**: https://github.com/zomians/landbase_ai_suite
- **Issues**: https://github.com/zomians/landbase_ai_suite/issues
