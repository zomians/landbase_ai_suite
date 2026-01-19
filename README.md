# LandBase AI Suite

**AI ドリブン経営支援プラットフォーム**
沖縄県北部の観光業向けマルチテナント自動化スイート

[![Rails](https://img.shields.io/badge/Rails-8.0-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791)](https://www.postgresql.org/)
[![n8n](https://img.shields.io/badge/n8n-2.1.1-6e1e78)](https://n8n.io/)
[![Mattermost](https://img.shields.io/badge/Mattermost-9.11-0058cc)](https://mattermost.com/)
[![License](https://img.shields.io/badge/License-Proprietary-yellow)](#ライセンス)

---

## 📋 目次

- [概要](#概要)
- [主な特徴](#主な特徴)
- [クイックスタート](#クイックスタート)
- [プロジェクト構成](#プロジェクト構成)
- [技術スタック](#技術スタック)
- [サービス一覧](#サービス一覧)
- [ドキュメント](#ドキュメント)
- [開発に参加](#開発に参加)
- [ライセンス](#ライセンス)

---

## 概要

LandBase AI Suite は、沖縄県北部の小規模観光業（ホテル、飲食店、ツアー会社など）向けに開発された **SaaS 型マルチテナントプラットフォーム** です。各クライアント（法人・個人事業主）に対して、専用の自動化環境とコミュニケーションツールを提供します。

### ビジョン

> データドリブン経営を AI ソリューションでサポートする

観光業界の課題（人手不足、データ活用の遅れ、OTA 依存）を、AI とワークフロー自動化で解決します。

---

## 主な特徴

- 🏢 **マルチテナントアーキテクチャ**: 1 つのプラットフォームで 100+クライアントを管理
- 🤖 **n8n ワークフロー自動化**: ノーコード/ローコードで業務自動化（OperationAI）
- 📊 **MarketingAI**: データ分析、価格最適化、レコメンド
- 💬 **Mattermost 統合**: クライアント別チームコミュニケーション
- 🐳 **Docker Compose**: 4 サービス統合環境
- 🔓 **完全 OSS**: すべてのコアコンポーネントがオープンソース

---

## クイックスタート

### 必要な環境

- Docker 20.10+
- Docker Compose 2.0+
- Git 2.30+
- Make

### セットアップ手順

#### 1. リポジトリクローン

```bash
git clone https://github.com/zomians/landbase_ai_suite.git
cd landbase_ai_suite
```

#### 2. 環境変数設定

```bash
cp .env.local.example .env.local
# .env.local を編集（以下の情報を設定）
# - LINE Bot 認証情報（LINE Developers Consoleで取得）
# - 決済関連設定は各フロントサービス側で管理
```

#### 3. 初回セットアップ

```bash
# Platform Railsアプリ生成（初回のみ）
make init
```

#### 4. サービス起動

```bash
# 全サービス起動
make up

# 起動確認
docker compose ps
```

#### 5. 各サービスにアクセス

| サービス             | URL                   | 備考                           |
| -------------------- | --------------------- | ------------------------------ |
| **Platform**         | http://localhost:3000 | プラットフォーム基幹アプリ     |
| **フロントサービス** | - | クライアント別フロントは別リポジトリで管理 |
| **n8n**              | http://localhost:5678 | 初回アクセス時にアカウント作成 |
| **Mattermost**       | http://localhost:8065 | 初回アクセス時にセットアップ   |

### よく使うコマンド

```bash
# 初期セットアップ
make init                  # Platform Railsアプリ生成（初回のみ）

# サービス管理
make up                    # 全サービス起動（PostgreSQL, Platform, Mattermost, n8n）
make down                  # 全サービス停止
make logs                  # 全サービスログ表示
make clean                 # 完全クリーンアップ（注意：データ削除）

# 個別サービスログ
make n8n-logs              # n8nログ表示
make mattermost-logs       # Mattermostログ表示
make postgres-logs         # PostgreSQLログ表示
make postgres-shell        # PostgreSQLシェル接続
```

---

## プロジェクト構成

```
landbase_ai_suite/
├── .claude/                       # Claude Code設定（将来）
├── config/
│   └── client_list.yaml           # クライアントレジストリ
├── docs/
│   ├── adr/                       # Architecture Decision Records
│   ├── guides/                    # セットアップ・技術ガイド
│   │   └── n8n-accounting-automation-setup.md
│   └── business/                  # ビジネス関連ドキュメント
│       ├── company-overview.md
│       └── sns-marketing-trends-2025.md
├── n8n/
│   └── workflows/                 # n8nワークフローテンプレート
├── rails/
│   └── platform/                  # プラットフォーム基幹アプリ（導入済み）
├── nextjs/                        # マーケティングサイト（将来）
├── .env                           # 環境変数設定
├── .env.local.example             # 機密情報テンプレート
├── compose.yaml                   # Docker Compose定義
├── Makefile                       # 開発自動化コマンド
├── README.md                      # このファイル
├── CLAUDE.md                      # Claude向けガイド
├── CONTRIBUTING.md                # 開発者向け実践ガイド
└── ARCHITECTURE.md                # 技術アーキテクチャ詳細
```

---

## 技術スタック

### インフラストラクチャ層

| 技術               | バージョン | 用途               |
| ------------------ | ---------- | ------------------ |
| **Docker**         | 20.10+     | コンテナ化         |
| **Docker Compose** | 2.0+       | マルチコンテナ管理 |
| **PostgreSQL**     | 16-alpine  | データベース       |

### 自動化・コミュニケーション層

| 技術           | バージョン | 用途                                      |
| -------------- | ---------- | ----------------------------------------- |
| **n8n**        | 2.1.1    | ワークフロー自動化エンジン（OperationAI） |
| **Mattermost** | 9.11       | チームコミュニケーション                  |

### アプリケーション層

| 技術                         | バージョン | 用途                            |
| ---------------------------- | ---------- | ------------------------------- |
| **Ruby on Rails**            | 8.0.2.1    | Platform 基幹 |
| **Devise**                   | 2.5        | ユーザー認証                    |
| **PayPal Commerce Platform** | 1.0        | 決済機能                        |
| **Tailwind CSS**             | 3.0        | ユーティリティファースト CSS    |
| **Stimulus**                 | -          | インタラクティブ JS             |
| **Solid Queue**              | -          | バックグラウンドジョブ          |
| **Solid Cache**              | -          | キャッシュレイヤー              |
| **Solid Cable**              | -          | WebSocket                       |

**詳細**: [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## サービス一覧

### バックオフィス（共通基盤）

#### Platform 基幹アプリ

**ポート**: 3000
**責務**:

- クライアント管理（CRUD、サービス設定）
- OperationAI（清掃管理、在庫管理等）
- MarketingAI（データ分析、価格最適化等）
- プラットフォーム API 提供（n8n 連携、フロントサービス連携）

#### n8n（ワークフロー自動化）

**ポート**: 5678
**責務**:

- Projects 機能でクライアント毎のワークフロー管理
- LINE Bot 統合、OCR 処理、AI 判定等

#### Mattermost（チームコミュニケーション）

**ポート**: 8065
**責務**:

- Teams 機能でクライアント毎のチャット環境
- 清掃完了報告、アラート通知等

### フロントサービス（クライアント固有）

#### フロントサービス（クライアント固有）

フロントサービスはクライアント別に独立し、別リポジトリで管理します。
例: Shrimp Shells EC（restaurant 向け冷凍食品 EC）

#### Hotel App（将来）

**ポート**: 3004（予定）
**技術**: Rails 8（予定）
**責務**:

- 公式予約サイト
- 清掃管理（Platform 基幹 API と連携）

---

## ドキュメント

### ドキュメント役割分担

| ドキュメント        | 役割                                                   |
| ------------------- | ------------------------------------------------------ |
| **README.md**       | プロジェクト概要、技術スタック、クイックスタート       |
| **CONTRIBUTING.md** | 開発規約（Issue、Git、コミット、コーディング規約）     |
| **CLAUDE.md**       | AI 向けクイックリファレンス                            |
| **ARCHITECTURE.md** | 技術アーキテクチャ詳細、DB 設計、API 設計              |

### 開発者向け

- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - 開発ガイド（汎用的な開発規約）
  - Issue 作成ガイドライン
  - Git ワークフロー（GitHub Flow）
  - コミット規約（Conventional Commits）
  - コーディング規約
  - テスト方針
  - コードレビュー基準

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - 技術アーキテクチャ詳細
  - システム設計詳細
  - データベース設計
  - 設計パターン（Decorator、Service Object 等）
  - API 設計
  - セキュリティ・パフォーマンス設計

### AI 開発支援

- **[CLAUDE.md](./CLAUDE.md)** - Claude 向けクイックリファレンス
  - よく使うコマンド
  - 開発ワークフロー
  - 重要な設計原則（プロジェクト固有）
  - トラブルシューティング

### docs/ ディレクトリ構成

```
docs/
├── adr/                    # Architecture Decision Records
├── guides/                 # セットアップ・技術ガイド
│   └── n8n-accounting-automation-setup.md
└── business/               # ビジネス関連ドキュメント
    ├── company-overview.md
    └── sns-marketing-trends-2025.md
```

### 設計判断記録（ADR）

- **[docs/adr/](./docs/adr/)** - Architecture Decision Records
  - [0001: n8n + Mattermost + Rails 統合](./docs/adr/0001-n8n-mattermost-rails-integration.md)
  - [0002: フロント/バックオフィス分離](./docs/adr/0002-frontend-backend-separation.md)
  - [0005: マルチテナント戦略](./docs/adr/0005-multitenancy-strategy.md)
  - [0006: Platform 基幹アプリ分離](./docs/adr/0006-platform-app-separation.md)

---

## 開発に参加

プロジェクトへの貢献を歓迎します！

### はじめに

1. **[CONTRIBUTING.md](./CONTRIBUTING.md)** を読む
2. 環境セットアップ
3. Issue 確認
4. ブランチ作成（`feature/XX-description`）
5. 実装・テスト
6. PR 作成

### コミット規約

```
<type>(<scope>): <subject> (issue#<番号>)
```

**例**:

```bash
feat(platform): 清掃基準管理APIを実装 (issue#54)
fix(rails): カート合計金額の計算ロジックを修正 (issue#58)
docs: CONTRIBUTING.mdを追加 (issue#57)
```

**詳細**: [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## ライセンス

All rights reserved. © 株式会社 AI.LandBase

---

## 連絡先

- **会社**: 株式会社 AI.LandBase
- **GitHub**: https://github.com/zomians/landbase_ai_suite
- **Issues**: https://github.com/zomians/landbase_ai_suite/issues

---

## 謝辞

このプロジェクトは、以下のオープンソースソフトウェアを活用しています：

- [Ruby on Rails](https://rubyonrails.org/)
- [n8n](https://n8n.io/)
- [Mattermost](https://mattermost.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [Docker](https://www.docker.com/)

各プロジェクトのメンテナーとコントリビューターに感謝します。

---

**Last Updated**: 2026-01-18
**Version**: 1.0
