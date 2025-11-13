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
- [ブランチ戦略](#ブランチ戦略)
- [業種別ワークフローテンプレート](#業種別ワークフローテンプレート)
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
┌─────────────────────────────────────────────────────────────┐
│                    LandBase AI Suite                         │
│                  (Docker Compose環境)                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐    ┌──────────────────────────────┐   │
│  │  Platform Layer │    │     Client Layer             │   │
│  │  (内部管理用)   │    │  (クライアント専用環境)      │   │
│  ├─────────────────┤    ├──────────────────────────────┤   │
│  │ n8n             │    │ n8n (Client 1) - Port 5679   │   │
│  │ Port: 5678      │    │ Schema: n8n_client1          │   │
│  │ Schema: public  │    ├──────────────────────────────┤   │
│  ├─────────────────┤    │ n8n (Client 2) - Port 5680   │   │
│  │ Mattermost      │    │ Schema: n8n_client2          │   │
│  │ Port: 8065      │    ├──────────────────────────────┤   │
│  └─────────────────┘    │ n8n (Client 3) - Port 5681   │   │
│                          │ Schema: n8n_client3          │   │
│  ┌──────────────────────┴──────────────────────────────┐   │
│  │           PostgreSQL (Port 5432)                     │   │
│  │  - Database: landbase_development                    │   │
│  │  - Schema分離: public, n8n_client1, n8n_client2...  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
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
│
├── config/                       # 設定ファイル
│   ├── clients.yml               # クライアントレジストリ（マスターデータ）
│   └── templates/                # 業種別ワークフローテンプレート
│       ├── hotel.json
│       ├── restaurant.json
│       └── tour.json
│
├── scripts/                      # 自動化スクリプト
│   ├── add_client.rb             # クライアント登録
│   ├── generate_client_compose.rb # Docker Compose生成
│   ├── provision_client.sh       # クライアント環境構築
│   └── setup_n8n_owner.sh        # Platform n8n 初期化
│
├── n8n/                          # n8n関連
│   └── import-workflows.sql      # サンプルワークフロー
│
├── rails/                        # Rails アプリ（将来実装）
├── nextjs/                       # Next.js アプリ（将来実装）
└── postgres/                     # PostgreSQL 設定
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

# 4. サンプルワークフローインポート（オプション）
make n8n-import-workflows
```

### アクセス情報

#### Platform n8n (社内管理用)
- URL: http://localhost:5678
- Email: `admin@landbase.local`
- Password: `Admin123456`

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
# - 業種別ワークフロー導入（hotel.json）
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

# 注意: これは clients.yml からの削除のみ
# Docker コンテナは手動で停止・削除が必要
docker compose -f compose.client.hotel_sunrise.yaml down
```

### クライアントデータ構造

`config/clients.yml` の構造:

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
make n8n-import-workflows  # サンプルワークフローインポート

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

### スクリプト詳細

#### 1. `scripts/add_client.rb`

**目的**: クライアント情報を `clients.yml` に追加

**主要機能**:
- 引数バリデーション
- 重複チェック
- ポート自動割り当て（5679から順次）
- パスワード自動生成（16文字英数字）
- メールアドレス生成（アンダースコアをハイフンに変換）

**使用例**:
```bash
ruby scripts/add_client.rb hotel_sunrise "Sunrise Hotel" hotel info@hotel.com
```

#### 2. `scripts/generate_client_compose.rb`

**目的**: クライアント専用 Docker Compose ファイル生成

**主要機能**:
- `clients.yml` から設定読み込み
- n8n コンテナ定義生成
- 専用ボリューム作成
- プラットフォームネットワークへの接続

**生成例**:
```yaml
name: landbase_ai_suite_development
services:
  n8n-shrimp-shells:
    image: n8nio/n8n:latest
    container_name: n8n_shrimp_shells
    environment:
      - DB_POSTGRESDB_SCHEMA=n8n_shrimp_shells
    ports:
      - "5679:5678"
    volumes:
      - n8n_data_shrimp_shells:/home/node/.n8n
    networks:
      - landbase_ai_suite_development_default
```

#### 3. `scripts/provision_client.sh`

**目的**: クライアント環境の完全自動構築

**実行ステップ**:
1. Docker Compose 生成 (`generate_client_compose.rb` 呼び出し)
2. n8n コンテナ起動
3. ヘルスチェック待機
4. n8n オーナー作成（REST API: `/rest/owner/setup`）
5. 業種別ワークフロー導入（未実装）

**エラーハンドリング**:
- クライアント存在チェック
- n8n API レスポンス検証

#### 4. `scripts/setup_n8n_owner.sh`

**目的**: Platform n8n の初回セットアップ

**実行内容**:
- `.env.development` から認証情報読み込み
- `/rest/owner/setup` API 呼び出し
- セットアップ完了確認

---

## LINE Bot 統合

### 概要

LINE Bot と n8n を連携して、LINE グループに投稿された画像を自動的に Google Drive の `inbox` フォルダに保存するワークフローです。

### アーキテクチャ

```
[LINE Group] → [LINE Bot] → [ngrok] → [ローカルn8n] → [Google Drive]
                             Webhook
```

### セットアップ手順

#### 1. LINE Bot 作成

**LINE Developers Console での設定:**

```bash
# 1. LINE Developers Console にアクセス
https://developers.line.biz/console/

# 2. 新しいプロバイダー作成

# 3. Messaging API チャネル作成

# 4. 以下の情報を取得:
#    - Channel Secret
#    - Channel Access Token (Long-lived)

# 5. 以下の設定を ON にする:
#    - Webhook送信: ON
#    - グループトーク参加: ON
```

#### 2. 環境変数設定

`.env.development` に LINE Bot の認証情報を設定:

```bash
# .env.development を編集
LINE_CHANNEL_SECRET=your_actual_channel_secret
LINE_CHANNEL_ACCESS_TOKEN=your_actual_channel_access_token
```

設定状況を確認:

```bash
make line-bot-info
```

#### 3. ngrok で n8n を公開

ローカルの n8n を外部から Webhook 受信できるように公開:

```bash
# ngrok のインストール (未インストールの場合)
brew install ngrok

# n8n を公開
make ngrok

# 出力例:
# Forwarding https://xxxx-xxxx-xxxx.ngrok-free.app -> http://localhost:5678
```

#### 4. LINE Webhook URL 設定

LINE Developers Console で Webhook URL を設定:

```
https://<ngrok-url>/webhook/line-webhook
```

**確認方法:**

```bash
# Webhook 接続テスト
make line-bot-test
```

#### 5. Google Drive 認証設定

**n8n UI で Google Drive Credential を作成:**

1. n8n にアクセス: http://localhost:5678
2. Credentials → New Credential → Google Drive OAuth2 API
3. OAuth 認証フロー実行
4. Google Drive に `inbox` フォルダを作成

#### 6. n8n ワークフローのインポート

**ワークフローファイル:** `n8n/workflows/line-to-gdrive.json`

**n8n UI でインポート:**

1. n8n UI の Workflows → Import from File
2. `n8n/workflows/line-to-gdrive.json` を選択
3. Credentials を設定:
   - **LINE Bot Auth**: HTTP Header Auth で以下を設定
     - Header Name: `Authorization`
     - Header Value: `Bearer <LINE_CHANNEL_ACCESS_TOKEN>`
   - **Google Drive OAuth2**: 上記で作成した Credential を選択
4. ワークフローを Activate

#### 7. LINE グループで動作確認

```bash
# 1. LINE Bot をグループに招待

# 2. グループで画像を送信

# 3. Google Drive の inbox フォルダを確認
#    ファイル名: YYYY-MM-DD_HHmmss_<groupId>.jpg
```

### ワークフロー詳細

#### ノード構成

```
1. Webhook          : LINE からメッセージ受信
2. IF Image         : 画像メッセージか判定
3. Get LINE Image   : LINE API から画像データ取得
4. Google Drive     : inbox フォルダにアップロード
5. Response Success : 成功レスポンス返却
6. Response Ignored : 画像以外は無視
```

#### ファイル命名規則

```javascript
// Google Drive に保存されるファイル名
{timestamp}_{groupId}.jpg

// 例:
2025-11-13_163000_Cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.jpg
```

#### マルチグループ対応

複数の LINE グループに対応しています。グループ ID でファイルを識別可能です。

### 主要コマンド

```bash
# ngrok 起動
make ngrok

# LINE Bot 設定情報表示
make line-bot-info

# Webhook 接続テスト
make line-bot-test

# n8n ログ確認
make n8n-logs
```

### トラブルシューティング (LINE Bot)

#### 問題: ngrok URL が変更される

**症状:**
```
ngrok の無料版は 8時間で URL が変更される
```

**解決策:**
```bash
# 1. 新しい ngrok URL を取得
make ngrok

# 2. LINE Developers Console で Webhook URL を更新
https://<new-ngrok-url>/webhook/line-webhook
```

**代替案:**
- ngrok 有料プラン (固定 URL)
- localtunnel の使用
- Cloudflare Tunnel の使用

#### 問題: 画像が Google Drive に保存されない

**確認項目:**

```bash
# 1. n8n ログを確認
make n8n-logs

# 2. LINE Webhook が届いているか確認
#    n8n UI の Executions タブで確認

# 3. Google Drive Credential が有効か確認
#    n8n UI の Credentials タブで確認

# 4. inbox フォルダが存在するか確認
#    Google Drive で確認
```

#### 問題: LINE Bot がグループに参加できない

**確認項目:**

```bash
# LINE Developers Console で以下を確認:
# 1. グループトーク参加が ON になっているか
# 2. Bot が Blocked 状態になっていないか
```

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

### 問題: clients.yml が破損した

**症状**:
```
❌ エラー: YAML parse error
```

**解決策**:
```bash
# Git で元に戻す
git checkout config/clients.yml

# または main ブランチから復元
git checkout main -- config/clients.yml
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

## ブランチ戦略

### ブランチ構成

```
main/
  └── テンプレート状態
      - clients.yml は空配列
      - コア機能のみ
      - 本番デプロイ用

feature/shrimp-shells/
  └── 実クライアント環境
      - Shrimp Shells のデータ
      - compose.client.shrimp_shells.yaml
      - 開発・テスト用
```

### ブランチ運用ルール

1. **main ブランチ**: プラットフォームのテンプレート状態を維持
   - `config/clients.yml` は空配列 `clients: []`
   - クライアント固有のデータは含まない
   - コア機能の更新のみコミット

2. **feature/<client_code> ブランチ**: クライアント毎に作成
   - 実クライアントデータを含む
   - Docker Compose ファイルを含む
   - main にマージしない（分離運用）

3. **feature/<feature_name> ブランチ**: 新機能開発
   - 新機能実装用
   - テスト完了後 main にマージ

### ブランチ作成例

#### 1. クライアント用ブランチ（分離運用・PRなし）

```bash
# 新しいクライアント用ブランチ
git checkout -b feature/hotel_sunrise

# クライアント追加
make add-client CODE=hotel_sunrise NAME="Sunrise Hotel" INDUSTRY=hotel

# プロビジョニング
make provision-client CODE=hotel_sunrise

# コミット
git add .
git commit -m "Add Hotel Sunrise client configuration"
git push origin feature/hotel_sunrise
```

**重要:** クライアント用ブランチは **main にマージしない** でください。
- 理由: main はテンプレート状態を維持（clients.yml は空配列）
- 運用: クライアント毎にブランチを分離して管理
- デプロイ: feature/<client_code> ブランチから直接デプロイ

#### 2. 新機能開発ブランチ（PR経由で main にマージ）

新機能やコア機能の改善は、プルリクエスト（PR）経由で main にマージします。

```bash
# main ブランチから最新を取得
git checkout main
git pull origin main

# 新機能ブランチ作成
git checkout -b feature/workflow-auto-import

# 機能実装
# ... コード変更 ...

# コミット
git add .
git commit -m "Add automatic workflow import for clients

- Implement n8n API integration for workflow creation
- Add industry-specific template processing
- Update provision_client.sh to call API endpoints"

# リモートに push
git push origin feature/workflow-auto-import
```

#### 3. プルリクエスト作成

GitHub CLI を使用する場合:

```bash
# PR 作成
gh pr create \
  --title "Add automatic workflow import for clients" \
  --body "$(cat <<'EOF'
## 概要
クライアント環境プロビジョニング時に、業種別ワークフローを自動的にインポートする機能を実装しました。

## 変更内容
- n8n REST API 統合を追加
- `config/templates/*.json` からワークフロー定義を読み込み
- `provision_client.sh` でワークフロー作成 API を呼び出し

## テスト方法
1. `make add-client CODE=test_hotel NAME="Test Hotel" INDUSTRY=hotel`
2. `make provision-client CODE=test_hotel`
3. http://localhost:5680 でワークフローが自動作成されていることを確認

## 影響範囲
- `scripts/provision_client.sh`: Step 4 の実装追加
- `config/templates/*.json`: テンプレート構造の確認

## チェックリスト
- [x] 既存のクライアントプロビジョニングが動作することを確認
- [x] 新規クライアント追加でワークフローが正しく作成されることを確認
- [x] README.md を更新
EOF
)" \
  --base main \
  --head feature/workflow-auto-import
```

Web UI を使用する場合:
1. GitHub リポジトリページにアクセス
2. "Pull requests" タブをクリック
3. "New pull request" ボタンをクリック
4. Base: `main`, Compare: `feature/workflow-auto-import` を選択
5. タイトルと説明を記入
6. "Create pull request" をクリック

#### 4. PR レビューとマージ

```bash
# レビュー後、main にマージされる
# （GitHub UI で Merge ボタンをクリック）

# ローカルの main を更新
git checkout main
git pull origin main

# 作業ブランチを削除
git branch -d feature/workflow-auto-import
git push origin --delete feature/workflow-auto-import
```

#### 5. 全クライアントブランチへの反映

main にマージされた新機能を、各クライアントブランチに反映:

```bash
# Shrimp Shells ブランチに反映
git checkout feature/shrimp-shells
git merge main -m "Merge workflow auto-import feature from main"
git push origin feature/shrimp-shells

# Hotel Sunrise ブランチに反映
git checkout feature/hotel_sunrise
git merge main -m "Merge workflow auto-import feature from main"
git push origin feature/hotel_sunrise
```

### プルリクエストの使い分け

| ブランチタイプ | PR作成 | mainへのマージ | 用途 |
|--------------|--------|---------------|------|
| `feature/<client_code>` | ❌ 不要 | ❌ しない | クライアント固有データ管理 |
| `feature/<feature_name>` | ✅ 必須 | ✅ する | コア機能開発・改善 |
| `bugfix/<issue_name>` | ✅ 必須 | ✅ する | バグ修正 |
| `docs/<topic>` | ✅ 推奨 | ✅ する | ドキュメント更新 |

---

## 業種別ワークフローテンプレート

### hotel.json (ホテル向け)

```json
{
  "name": "ホテル向けワークフローパック",
  "workflows": [
    {
      "name": "予約確認メール",
      "description": "予約時に確認メールを自動送信",
      "trigger": "webhook"
    },
    {
      "name": "チェックイン前日リマインダー",
      "description": "チェックイン前日に案内メール送信",
      "trigger": "schedule"
    },
    {
      "name": "レビュー依頼",
      "description": "チェックアウト後にレビュー依頼",
      "trigger": "webhook"
    }
  ]
}
```

### restaurant.json (飲食店向け)

```json
{
  "name": "飲食店向けワークフローパック",
  "workflows": [
    {
      "name": "予約確認メール",
      "description": "予約時に確認メールを自動送信",
      "trigger": "webhook"
    },
    {
      "name": "SNS自動投稿",
      "description": "本日のメニューを自動投稿",
      "trigger": "schedule"
    },
    {
      "name": "在庫アラート",
      "description": "在庫が少なくなったら通知",
      "trigger": "webhook"
    }
  ]
}
```

### tour.json (ツアー会社向け)

```json
{
  "name": "ツアー会社向けワークフローパック",
  "workflows": [
    {
      "name": "ツアー予約確認",
      "description": "ツアー予約時に確認メール送信",
      "trigger": "webhook"
    },
    {
      "name": "天気情報自動配信",
      "description": "ツアー前日に天気情報を配信",
      "trigger": "schedule"
    },
    {
      "name": "満足度アンケート",
      "description": "ツアー後にアンケート送信",
      "trigger": "webhook"
    }
  ]
}
```

---

## 今後の開発ロードマップ

### 開発アプローチ

**コンセプト: 実用機能ファースト**

AI機能などの具体的な価値提供機能を作りながら、必要に応じてコア機能を段階的に完成させていくアプローチを採用します。

```
従来型アプローチ (X):
  Phase 1 → Phase 2 → Phase 3 → Phase 4
  (完璧なインフラ構築後に機能実装)

採用アプローチ (✓):
  具体機能の開発 → 必要なコア機能の拡充 → 繰り返し
  (実用機能を作りながらインフラを強化)
```

---

### Iteration 1: AIワークフロー自動生成（現在）

**ゴール**: クライアントが日本語で「こういう自動化がしたい」と入力すると、n8nワークフローが自動生成される

#### 実装する具体機能
- 🎯 自然言語からワークフロー生成 (Claude API統合)
- 🎯 業種別プリセットからのカスタマイズ提案
- 🎯 生成されたワークフローの即時デプロイ

#### 必要となるコア機能の拡充
- ⚙️ n8n API 統合強化（ワークフロー CRUD）
- ⚙️ Claude API クライアント実装
- ⚙️ プロンプトエンジニアリング（業種×ユースケース）
- ⚙️ クライアント用ワークフロー自動導入の完成

#### 成果物
- Rails API: `/api/workflows/generate` エンドポイント
- n8n 統合モジュール
- 業種別プロンプトテンプレート

---

### Iteration 2: 現場報告自動仕分けサービス

**ゴール**: 現場スタッフが領収書や清掃完了写真・動画をLINEやメールで送信すると、AIが内容を理解して自動的に仕分け・記録

#### 実装する具体機能
- 📸 マルチチャネル受信（LINE Bot、メール、Mattermost）
- 📸 Claude Vision API による画像・動画分析
  - 領収書: 金額、日付、カテゴリを自動抽出
  - 清掃写真: Before/After 判定、場所特定
  - 作業動画: 作業内容の要約生成
- 📸 自動仕分けルール適用
  - 経費申請データベースへの登録
  - 清掃チェックリストへの記録
  - 異常検知（領収書の重複、未完了作業など）
- 📸 確認通知（Mattermost または LINE で結果送信）

#### ユースケース例

**ホテル業**: 清掃スタッフが各客室の清掃完了写真をLINEで送信
- → AIが部屋番号を認識
- → 清掃状態を判定（OK/要再確認）
- → フロントに自動通知

**飲食店**: スタッフが仕入れ時の領収書をスマホで撮影して送信
- → AIが金額・品目・店名を抽出
- → 経費データベースに自動登録
- → 月次レポートに反映

**ツアー会社**: ガイドがツアー中の写真をメール送信
- → AIがツアー名と参加者数を推測
- → 写真をアルバムに自動整理
- → SNS投稿用に最良の写真を選定

#### 必要となるコア機能の拡充
- ⚙️ LINE Bot SDK 統合
- ⚙️ メール受信サーバー（Postfix + Rails ActionMailbox）
- ⚙️ Mattermost Webhook 双方向連携
- ⚙️ Claude Vision API クライアント実装
- ⚙️ ファイルストレージ（S3 または MinIO）
- ⚙️ 動画サムネイル生成（FFmpeg）
- ⚙️ OCR機能（領収書テキスト抽出）
- ⚙️ データベーススキーマ設計（経費、清掃記録、作業ログ）

#### 成果物
- LINE Bot アプリケーション
- メール受信・解析パイプライン
- Claude Vision 統合 API
- 仕分けルールエンジン
- 管理者向け確認 UI（Rails or Next.js）

---

### Iteration 3: SNS自動投稿AI

**ゴール**: クライアントの商品写真をアップロードすると、AIが魅力的なSNS投稿文を生成して自動投稿

#### 実装する具体機能
- 📸 画像アップロード機能
- 📸 Claude Vision API で画像分析
- 📸 SNS投稿文生成（Instagram、X、Facebook対応）
- 📸 n8n経由での自動投稿

#### 必要となるコア機能の拡充
- ⚙️ ファイルアップロード・ストレージ（S3 または MinIO）
- ⚙️ 画像処理パイプライン
- ⚙️ SNS API 統合（Instagram、X、Facebook）
- ⚙️ クライアント用 Web UI の初期実装

#### 成果物
- 画像分析・投稿生成 API
- SNS 連携 n8n ワークフロー
- シンプルな Web UI

---

### Iteration 4: 在庫最適化アラート

**ゴール**: 飲食店向けに、在庫データから発注最適タイミングをAIが提案

#### 実装する具体機能
- 📦 在庫データ入力 UI
- 📦 消費予測モデル
- 📦 発注タイミング提案
- 📦 Mattermost または LINE 通知

#### 必要となるコア機能の拡充
- ⚙️ Mattermost Webhook 統合
- ⚙️ LINE Bot 実装（オプション）
- ⚙️ データ入力フォーム（Flutter Web or Next.js）
- ⚙️ 定期実行バッチジョブ

#### 成果物
- 在庫管理 Web UI
- 予測アルゴリズム
- 通知システム

---

### Iteration 5: マルチクライアント管理画面

**ゴール**: 社内管理者が全クライアントの状況を一覧で確認・管理できる

#### 実装する具体機能
- 🖥️ クライアント一覧ダッシュボード
- 🖥️ プロビジョニング Web UI（CLI の GUI化）
- 🖥️ 使用状況モニタリング（ワークフロー実行回数、ストレージ使用量）
- 🖥️ 課金ステータス管理

#### 必要となるコア機能の拡充
- ⚙️ Rails Admin または独自管理画面
- ⚙️ メトリクス収集（Prometheus + Grafana or カスタム実装）
- ⚙️ 課金システム基盤（Stripe 統合準備）

#### 成果物
- 管理者ダッシュボード
- モニタリングシステム
- 課金管理基盤

---

### 将来的なスケーラビリティ対応（必要に応じて）

これらは**具体機能の開発中に必要になったタイミング**で実装:

#### インフラ強化
- 🔧 Kubernetes 移行（10+ クライアント時）
- 🔧 サブドメイン方式（SEO/ブランディング要求時）
- 🔧 CDN 統合（大容量画像配信時）
- 🔧 マルチリージョン対応（海外展開時）

#### セキュリティ強化
- 🔒 SSO/SAML対応（大企業クライアント獲得時）
- 🔒 監査ログ（コンプライアンス要求時）
- 🔒 GDPR対応（欧州展開時）

---

### 現在の進捗状況

✅ **完了**
- マルチテナントアーキテクチャ
- n8n 自動プロビジョニング
- クライアント管理 CLI
- 包括的なドキュメント

🚧 **進行中**
- Iteration 1 準備（AIワークフロー自動生成の設計）

📋 **次のアクション**
1. Claude API 統合の実装
2. n8n REST API クライアント作成
3. シンプルなワークフロー生成プロトタイプ

---

## ライセンス

All rights reserved. © 株式会社AI.LandBase

---

## 連絡先

- **会社**: 株式会社AI.LandBase
- **GitHub**: https://github.com/zomians/landbase_ai_suite
- **Issues**: https://github.com/zomians/landbase_ai_suite/issues
