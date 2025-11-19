# LandBase AI Suite

**AI ドリブン経営支援プラットフォーム**
沖縄県北部の観光業向けマルチテナント自動化スイート

---

## 📋 目次

- [概要](#概要)
- [プロジェクト構成](#プロジェクト構成)
- [技術スタック](#技術スタック)
- [クライアント管理](#クライアント管理)
- [開発ワークフロー](#開発ワークフロー)
- [ライセンス](#ライセンス)

---

## 概要

LandBase AI Suite は、沖縄県北部の小規模観光業（ホテル、飲食店、ツアー会社など）向けに開発された **SaaS 型マルチテナントプラットフォーム** です。各クライアント（法人・個人事業主）に対して、専用の自動化環境とコミュニケーションツールを提供します。

### 主な特徴

- 🏢 **マルチテナントアーキテクチャ**: 1 つのプラットフォームで 100+クライアントを管理
- 🤖 **n8n 自動化**: 単一のn8nインスタンスでプロジェクト機能を使用して業務自動化
- 💬 **Mattermost 統合**: チームコミュニケーション基盤
- 📊 **PostgreSQL 共有**: 効率的なデータ管理

---

## プロジェクト構成

```
landbase_ai_suite/
├── config/
│   └── client_list.yaml          # クライアントレジストリ
├── docs/
│   ├── company-overview.md       # 会社概要
│   └── sns-marketing-trends-2025.md
├── n8n/
│   └── workflows/                # n8nワークフローテンプレート
├── nextjs/
│   └── Dockerfile
├── rails/
│   └── Dockerfile
├── .env                          # 環境変数設定
├── .env.local.example            # 機密情報テンプレート
├── compose.yaml                  # Platform サービス定義
├── Makefile
└── README.md
```

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

### アプリケーション層

| 技術              | バージョン | 用途           |
| ----------------- | ---------- | -------------- |
| **Ruby on Rails** | 8.0.2.1    | API Backend    |
| **Next.js**       | 15.1.6     | Marketing Site |
| **Flutter**       | 3.32.5     | Mobile/Web App |

---

## クライアント管理

### n8nプロジェクト機能によるクライアント管理

LandBase AI Suiteでは、単一のn8nインスタンス（Platform n8n）で全クライアントを管理します。クライアント毎の分離には、n8nの**プロジェクト機能**を使用します。

**運用フロー:**

1. Platform n8n（`http://localhost:5678`）にアクセス
2. 新規プロジェクトを作成（例: "Shrimp Shells"）
3. プロジェクト内でクライアント専用のワークフローを作成
4. クレデンシャルもプロジェクト単位で管理

### クライアントデータ構造

`config/client_list.yaml` でクライアント情報を管理します:

```yaml
clients:
  - code: shrimp_shells          # 一意識別子（スネークケース）
    name: Shrimp Shells          # 表示名
    industry: restaurant         # 業種 (hotel/restaurant/tour)
    subdomain: shrimp-shells     # 将来のサブドメイン用（ケバブケース）
    contact:
      email: info@shrimpshells.com
    services:
      mattermost:
        enabled: true
        team_name: Shrimp Shells Team
        admin_username: shrimp_shells_admin
        admin_email: info@shrimpshells.com
    status: trial                # trial/active/suspended
    created_at: "2025-11-13 14:00:57 +0900"
    # n8nはPlatformインスタンスでプロジェクト機能を使用して管理
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
```

---

## ライセンス

All rights reserved. © 株式会社 AI.LandBase

---

## 連絡先

- **会社**: 株式会社 AI.LandBase
- **GitHub**: https://github.com/zomians/landbase_ai_suite
- **Issues**: https://github.com/zomians/landbase_ai_suite/issues
