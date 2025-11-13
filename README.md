# LandBase AI Suite

**AIドリブン経営支援プラットフォーム**
沖縄県北部の観光業向けマルチテナント自動化スイート

---

## 📋 目次

- [概要](#概要)
- [ビジネスコンテキスト](#ビジネスコンテキスト)
- [システムアーキテクチャ](#システムアーキテクチャ)
- [技術スタック](#技術スタック)
- [ディレクトリ構成](#ディレクトリ構成)
- [セットアップ手順](#セットアップ手順)
- [クライアント管理](#クライアント管理)
- [開発ワークフロー](#開発ワークフロー)
- [LINE Bot 統合](#line-bot-統合)
- [トラブルシューティング](#トラブルシューティング)
- [今後の開発ロードマップ](#今後の開発ロードマップ)
- [ライセンス](#ライセンス)
- [連絡先](#連絡先)

---

## 概要

LandBase AI Suite は、沖縄県北部の小規模観光業（ホテル、飲食店、ツアー会社など）向けに開発された **SaaS型マルチテナントプラットフォーム** です。各クライアント（法人・個人事業主）に対して、専用の自動化環境とコミュニケーションツールを提供します。

### 主な特徴

- 🏢 **マルチテナントアーキテクチャ**: 1つのプラットフォームで100+クライアントを管理
- 🤖 **n8n自動化**: クライアント毎に独立したn8nコンテナで業務自動化
- 💬 **Mattermost統合**: チームコミュニケーション基盤
- 📊 **PostgreSQL共有**: スキーマ分離によるデータ隔離
- 🚀 **自動プロビジョニング**: makeコマンド1つでクライアント環境を構築

---

## ビジネスコンテキスト

### 企業情報
- **会社名**: 株式会社AI.LandBase
- **事業内容**: AIドリブン経営コンサルティング
- **対象地域**: 沖縄県北部（やんばる地域）
- **対象業種**: 観光業（ホテル、飲食店、ツアー会社）

### 課題と解決策

#### 課題
- 小規模事業者（従業員~10名）が多く、IT投資余力が限定的
- 予約管理、SNS投稿、在庫管理などの手作業が負担
- 個別にシステム導入するとコストが高い

#### 解決策
- **SaaS型提供**: 初期投資を抑えたサブスクリプションモデル
- **業種別テンプレート**: ホテル・飲食店・ツアー向けの事前設定ワークフロー
- **段階的導入**: トライアル → 本格運用へのスムーズな移行

### スケール目標
- **Phase 1**: 5-10クライアント（Proof of Concept）
- **Phase 2**: 50クライアント
- **Phase 3**: 100+クライアント

---

## システムアーキテクチャ

### 全体構成図

```
┌──────────────────────────────────────────────────────────┐
│               LandBase AI Suite (Docker Compose)          │
└──────────────────────────────────────────────────────────┘

[Platform Layer - 内部管理用]
  ┌─────────────────┐
  │ n8n             │ Port: 5678
  │ (Platform)      │ Schema: public
  └─────────────────┘

  ┌─────────────────┐
  │ Mattermost      │ Port: 8065
  └─────────────────┘

[Client Layer - クライアント専用環境]
  ┌─────────────────┐
  │ n8n (Client 1)  │ Port: 5679, Schema: n8n_client1
  └─────────────────┘

  ┌─────────────────┐
  │ n8n (Client 2)  │ Port: 5680, Schema: n8n_client2
  └─────────────────┘

  ┌─────────────────┐
  │ n8n (Client N)  │ Port: 5679+N, Schema: n8n_clientN
  └─────────────────┘

[Database Layer - 共通データベース]
  ┌─────────────────────────────────────────────────────────┐
  │ PostgreSQL (Port 5432)                                   │
  │ Database: landbase_development                           │
  │ Schemas: public, n8n_client1, n8n_client2, ...          │
  └─────────────────────────────────────────────────────────┘
```

### マルチテナント設計

#### ポート方式によるコンテナ分離
- **Platform n8n**: `localhost:5678` (社内管理用)
- **Client n8n**: `localhost:5679+` (クライアント毎に自動割り当て)
  - Shrimp Shells: 5679
  - 次のクライアント: 5680
  - ...

#### データベーススキーマ分離
```sql
-- PostgreSQL スキーマ構成
landbase_development/
  ├── public (Platform n8n)
  ├── n8n_shrimp_shells (Shrimp Shells専用)
  ├── n8n_hotel_a (Hotel A専用)
  └── n8n_tour_b (Tour B専用)
```

**メリット:**
- データ完全分離（セキュリティ）
- PostgreSQL 1インスタンスで管理（運用コスト削減）
- バックアップ・リストアが容易

---

## 技術スタック

### インフラストラクチャ層
| 技術 | バージョン | 用途 |
|------|-----------|------|
| **Docker** | - | コンテナ化 |
| **Docker Compose** | - | マルチコンテナ管理 |
| **PostgreSQL** | 16-alpine | データベース |

### 自動化・コミュニケーション層
| 技術 | バージョン | 用途 |
|------|-----------|------|
| **n8n** | latest | ワークフロー自動化エンジン |
| **Mattermost** | 9.11 | チームコミュニケーション |

### アプリケーション層（将来実装）
| 技術 | バージョン | 用途 |
|------|-----------|------|
| **Ruby on Rails** | 8.0.2.1 | API Backend |
| **Next.js** | 15.1.6 | Marketing Site |
| **Flutter** | 3.32.5 | Mobile/Web App |

### スクリプト・自動化
| 技術 | 用途 |
|------|------|
| **Ruby** | YAML操作、データ処理 (add_client.rb, generate_client_compose.rb) |
| **Bash** | Docker操作、プロビジョニング (provision_client.sh, setup_n8n_owner.sh) |

---

## ディレクトリ構成

```
landbase_ai_suite/
├── .env.development              # 環境変数設定
├── compose.development.yaml      # Platform サービス定義
├── compose.client.*.yaml         # クライアント専用 n8n 定義（自動生成）
├── Makefile                      # 統一コマンドインターフェース
├── README.md                     # プロジェクトドキュメント
│
├── config/                       # 設定ファイル
│   └── client_list.yaml          # クライアントレジストリ（マスターデータ）
│
├── docs/                         # 詳細ドキュメント
│   ├── line-bot-integration.md   # LINE Bot統合ガイド
│   └── roadmap.md                # 開発ロードマップ
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

## セットアップ手順

### 前提条件
- Docker Desktop インストール済み
- Ruby 3.x インストール済み
- macOS または Linux 環境

### 初回セットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/zomians/landbase_ai_suite.git
cd landbase_ai_suite

# 2. プラットフォームサービス起動
make up

# 3. Platform n8n 初期化
make init
```

### アクセス情報

#### Platform n8n (社内管理用)
- URL: http://localhost:5678
- 認証情報: `.env.development` の `N8N_OWNER_*` を参照

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
  - code: shrimp_shells              # 一意識別子（スネークケース）
    name: Shrimp Shells              # 表示名
    industry: restaurant             # 業種 (hotel/restaurant/tour)
    subdomain: shrimp-shells         # 将来のサブドメイン用（ケバブケース）
    contact:
      email: info@shrimpshells.com   # 連絡先
    services:
      n8n:
        enabled: true
        port: 5679                   # 自動割り当て（5679から開始）
        owner_email: admin-shrimp-shells@landbase.ai
        owner_password: KFsegssdUKmx5SAR  # 自動生成
        db_schema: n8n_shrimp_shells
        workflows: []
      mattermost:
        enabled: true
        team_name: Shrimp Shells Team
        admin_username: shrimp_shells_admin
        admin_email: info@shrimpshells.com
        admin_password: KFsegssdUKmx5SAR
    status: trial                    # trial/active/suspended
    created_at: '2025-11-13 14:00:57 +0900'
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

# プラットフォーム初期化
make init                  # n8n オーナー作成 + Mattermost 手動セットアップ案内
```

### スクリプト概要

| スクリプト | 用途 | Makeコマンド |
|-----------|------|-------------|
| `add_client.rb` | クライアント情報を `client_list.yaml` に登録 | `make add-client` |
| `generate_client_compose.rb` | クライアント専用 Docker Compose ファイル生成 | `make provision-client` で自動実行 |
| `provision_client.sh` | クライアント環境の完全自動構築 | `make provision-client` |
| `setup_n8n_owner.sh` | Platform n8n の初回セットアップ | `make init` |

詳細は各スクリプトのコメントを参照してください。

---

## LINE Bot 統合

LINE Bot と n8n を連携して、LINE グループに投稿された画像を自動的に Google Drive に保存するワークフローを実装できます。

**主な機能:**
- LINE グループでの画像自動保存
- マルチグループ対応
- ngrok による Webhook 受信

**詳細な手順:**
→ [LINE Bot 統合ガイド](docs/line-bot-integration.md)

---

## トラブルシューティング

### 問題: n8n コンテナが起動しない

**症状**:
```
Error: ENOTDIR: not a directory
```

**原因**: カスタムファイルマウントの設定ミス

**解決策**:
```bash
# compose ファイルを確認
cat compose.development.yaml | grep -A 5 "n8n:"

# 不要なマウントを削除してから再起動
make down && make up
```

### 問題: ポートが既に使用されている

**症状**:
```
Error: bind: address already in use
```

**解決策**:
```bash
# ポート使用状況確認
lsof -i :5678
lsof -i :5679

# プロセスを停止
kill -9 <PID>

# または Docker コンテナを停止
docker ps
docker stop <container_id>
```

### 問題: client_list.yaml が破損した

**症状**:
```
❌ エラー: YAML parse error
```

**解決策**:
```bash
# Git で元に戻す
git checkout config/client_list.yaml

# または main ブランチから復元
git checkout main -- config/client_list.yaml
```

### 問題: PostgreSQL 接続エラー

**症状**:
```
FATAL: password authentication failed
```

**解決策**:
```bash
# 環境変数確認
grep POSTGRES .env.development

# PostgreSQL ログ確認
make postgres-logs

# 完全リセット（注意: データ消失）
make clean
make up
```

---

## 今後の開発ロードマップ

**開発アプローチ:** 実用機能ファースト - AI機能などの具体的な価値提供機能を作りながら、必要に応じてコア機能を段階的に完成させていくアプローチを採用します。

**計画中の主要機能:**
- 🎯 AIワークフロー自動生成
- 📸 現場報告自動仕分けサービス
- 📱 SNS自動投稿AI
- 📦 在庫最適化アラート
- 🖥️ マルチクライアント管理画面

**詳細なロードマップ:**
→ [開発ロードマップ](docs/roadmap.md)

---

## ライセンス

All rights reserved. © 株式会社AI.LandBase

---

## 連絡先

- **会社**: 株式会社AI.LandBase
- **GitHub**: https://github.com/zomians/landbase_ai_suite
- **Issues**: https://github.com/zomians/landbase_ai_suite/issues
