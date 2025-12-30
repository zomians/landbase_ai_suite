# 開発ガイド

LandBase AI Suite プロジェクトへようこそ！このガイドでは、プロジェクトへの貢献方法と開発ワークフローを説明します。

## 目次

- [Issue 作成ガイドライン](#issue-作成ガイドライン)
- [開発環境セットアップ](#開発環境セットアップ)
- [Git ワークフロー](#git-ワークフロー)
- [コミット規約](#コミット規約)
- [PR 作成フロー](#pr作成フロー)
- [コーディング規約](#コーディング規約)
- [テスト方針](#テスト方針)
- [コードレビュー基準](#コードレビュー基準)
- [トラブルシューティング](#トラブルシューティング)

---

## Issue 作成ガイドライン

新機能開発やバグ修正を行う前に、必ず GitHub Issue を作成してください。Issue は実装の設計書であり、レビューの基準となります。

### Issue テンプレート

以下のテンプレートに沿って Issue を作成してください：

```markdown
## 📋 概要

[1-2文で変更内容を簡潔に説明]

**関連issue**: [関連するIssue番号があれば記載]

---

## 🎯 背景・課題

### 現状の問題
- [現在どのような問題があるか]
- [なぜこの変更が必要なのか]

### 課題
- ❌ [具体的な課題1]
- ❌ [具体的な課題2]
- ❌ [具体的な課題3]

---

## 🎯 目的・ゴール

### 主目的
[この変更で達成したいこと]

### 副次的目標
- [追加で達成したいこと1]
- [追加で達成したいこと2]

---

## 📖 要件定義

### 機能要件

#### FR-1: [機能名1]
- [詳細な要件説明]
- [実装内容]

#### FR-2: [機能名2]
- [詳細な要件説明]
- [実装内容]

### 非機能要件

#### NFR-1: パフォーマンス
- [パフォーマンス要件]

#### NFR-2: セキュリティ
- [セキュリティ要件]

#### NFR-3: 保守性
- [保守性要件]

---

## 🛠️ 技術仕様

### アーキテクチャ

[システム構成図、フロー図など]

### 実装詳細

[具体的な実装方法、コード例など]

---

## ✅ 受け入れ基準

### 必須（Must Have）
- [ ] [必須要件1]
- [ ] [必須要件2]

### 推奨（Should Have）
- [ ] [推奨要件1]
- [ ] [推奨要件2]

### オプション（Nice to Have）
- [ ] [オプション要件1]
- [ ] [オプション要件2]

---

## ⏱️ 工数見積

### タスク分解

| タスク | 内容 | 見積工数 |
|--------|------|----------|
| **設計** | [設計内容] | X.Xh |
| **実装** | [実装内容] | X.Xh |
| **テスト** | [テスト内容] | X.Xh |
| **ドキュメント更新** | [ドキュメント更新内容] | X.Xh |

**合計見積: X時間（X営業日）**

---

## 🧪 テスト計画

### テストケース

#### TC-1: [テストケース名1]
- **手順**:
  1. [手順1]
  2. [手順2]
- **期待結果**: [期待される結果]

#### TC-2: [テストケース名2]
- **手順**:
  1. [手順1]
  2. [手順2]
- **期待結果**: [期待される結果]

---

## 📈 次のステップ

[この機能完了後の展開、将来の拡張など]

---

## 📚 関連資料

- [関連ドキュメント、外部リンクなど]

---

## ✅ Definition of Done

- [ ] [完了条件1]
- [ ] [完了条件2]
- [ ] すべてのテストケース合格
- [ ] ドキュメント更新完了
- [ ] コードレビュー承認
- [ ] 本番環境デプロイ・検証完了

---

**工数見積**: X時間（X営業日）
**優先度**: High/Medium/Low
**難易度**: High/Medium/Low
**依存関係**: [依存するIssueや前提条件]
```

### 各セクションの説明

| セクション | 必須 | 説明 |
|-----------|------|------|
| **📋 概要** | ✅ | 変更内容を1-2文で簡潔に説明 |
| **🎯 背景・課題** | ✅ | なぜこの変更が必要か、現状の問題を明確化 |
| **🎯 目的・ゴール** | ✅ | 達成したいことを明確化 |
| **📖 要件定義** | ✅ | 機能要件（FR）と非機能要件（NFR）を定義 |
| **🛠️ 技術仕様** | ✅ | 実装方法、アーキテクチャ、コード例 |
| **✅ 受け入れ基準** | ✅ | Must/Should/Nice to Haveで優先度を明確化 |
| **⏱️ 工数見積** | ✅ | タスク分解と見積工数（後述の見積ガイドライン参照） |
| **🧪 テスト計画** | ✅ | 具体的なテストケースと期待結果 |
| **📈 次のステップ** | | 将来の拡張計画 |
| **📚 関連資料** | | 参考リンク、ドキュメント |
| **✅ Definition of Done** | ✅ | 完了の定義、チェックリスト |

### 優先度と難易度の定義

#### 優先度（Priority）

| レベル | 説明 | 例 |
|--------|------|-----|
| **High** | 本番運用に必須、ブロッカー | セキュリティ修正、重大なバグ修正 |
| **Medium** | 重要だが緊急ではない | 新機能、パフォーマンス改善 |
| **Low** | あると良い、将来的に対応 | UI微調整、ドキュメント追加 |

#### 難易度（Difficulty）

| レベル | 説明 | 見積工数目安 |
|--------|------|-------------|
| **Low** | 単純な変更、影響範囲が小さい | 〜4時間 |
| **Medium** | 複数ファイルの変更、設計が必要 | 4〜16時間 |
| **High** | アーキテクチャ変更、複数サービス横断 | 16時間〜 |

---

## 工数見積ガイドライン

### タスク分解の基本

すべての Issue は以下の標準タスクに分解してください：

| タスク | 内容 | 一般的な割合 |
|--------|------|------------|
| **設計** | 技術仕様の詳細化、アーキテクチャ検討 | 15-20% |
| **実装** | コーディング、リファクタリング | 40-50% |
| **テスト** | テストコード作成、動作確認 | 20-25% |
| **ドキュメント更新** | README、ADR、セットアップガイド更新 | 10-15% |

### 見積単位

- **時間単位**: 0.5時間刻みで見積もる
- **営業日換算**: 1営業日 = 8時間
- **最小単位**: 0.5時間
- **最大単位**: 1つのIssueは16時間（2営業日）を超えないように分割

### 見積精度の基準

#### 確実性レベル

| レベル | 説明 | バッファ |
|--------|------|---------|
| **高確実性** | 過去に類似実装あり、技術スタック熟知 | +10% |
| **中確実性** | 一般的な実装パターン、ドキュメント充実 | +25% |
| **低確実性** | 初めての技術、調査が必要 | +50% |

#### 見積例

**例1: 簡単なAPI追加（Low難易度）**
```
設計: 0.5h
実装: 1.5h
テスト: 0.5h
ドキュメント: 0.5h
---
合計: 3h（0.375営業日）
バッファ（+25%）: 3.75h → 切り上げて 4h
```

**例2: 複雑なワークフロー構築（Medium難易度）**
```
設計: 1.0h
実装: 4.0h
テスト: 2.0h
ドキュメント: 1.0h
---
合計: 8h（1営業日）
バッファ（+25%）: 10h → 切り上げて 10h
```

### 見積時の注意事項

1. **楽観的すぎない**: 最速ケースではなく、現実的な時間を見積もる
2. **テスト時間を忘れない**: 実装時間の50-60%をテストに割く
3. **ドキュメント更新を含める**: 後回しにしがちだが必須
4. **依存関係を考慮**: 他のタスクをブロックする場合は優先度を上げる
5. **レビュー時間は含めない**: レビューアの時間は別途

### バッファの考え方

- **予期しない問題**: 環境構築エラー、依存関係の競合など
- **仕様の曖昧性**: 実装中に発覚する仕様の不明点
- **テスト失敗対応**: バグ修正、リファクタリング

**推奨**: 常に+25%のバッファを含め、0.5時間単位で切り上げ

---

## 開発環境セットアップ

### 必要なツール

以下のツールをインストールしてください：

| ツール              | バージョン | 用途                  |
| ------------------- | ---------- | --------------------- |
| **Docker**          | 20.10+     | コンテナ実行環境      |
| **Docker Compose**  | 2.0+       | マルチコンテナ管理    |
| **Git**             | 2.30+      | バージョン管理        |
| **GitHub CLI (gh)** | 2.0+       | Issue/PR 管理（推奨） |
| **Make**            | -          | タスク自動化          |

### セットアップ手順

#### 1. リポジトリクローン

```bash
git clone https://github.com/zomians/landbase_ai_suite.git
cd landbase_ai_suite
```

#### 2. 環境変数設定

```bash
# .env.local.example をコピー
cp .env.local.example .env.local

# .env.local を編集（機密情報を設定）
# - PostgreSQLパスワード
# - n8n暗号化キー
# - Mattermost設定
# - その他APIキー
```

#### 3. Docker 起動

```bash
# 全サービス起動
make up

# 起動確認
docker compose ps
```

#### 4. 各サービスアクセス確認

| サービス             | URL                   | 備考                                   |
| -------------------- | --------------------- | -------------------------------------- |
| **Platform**         | http://localhost:3001 | プラットフォーム                       |
| **Shrimp Shells EC** | http://localhost:3002 | Rails 8 + Solidus                      |
| **n8n**              | http://localhost:5678 | 初回アクセス時にアカウント作成         |
| **Mattermost**       | http://localhost:8065 | 初回アクセス時にセットアップウィザード |

#### 5. データベース初期化（必要に応じて）

```bash
# Shrimp Shells EC
make shrimpshells-migrate
make shrimpshells-seed

# Platform（実装後）
make platform-migrate
make platform-seed
```

---

## Git ワークフロー

このプロジェクトは **[GitHub Flow](https://docs.github.com/ja/get-started/quickstart/github-flow)** を採用しています。

### 🚨 重要な原則：ブランチを作ってから作業する

**作業を開始する前に、必ず以下の手順を守ってください：**

1. **❌ main ブランチで直接作業しない**
   ```bash
   # ❌ BAD: main ブランチで直接編集
   git checkout main
   vim some_file.rb  # 危険！
   ```

2. **✅ Issue 作成 → ブランチ作成 → 実装の順序を守る**
   ```bash
   # ✅ GOOD: 正しい手順
   # Step 1: Issue 作成（GitHub で実施）
   # Step 2: main を最新化
   git checkout main
   git pull origin main

   # Step 3: 新しいブランチを作成
   git checkout -b feature/76-knowledge-base-implementation

   # Step 4: 実装開始
   vim some_file.rb
   ```

3. **⚠️ 作業中にブランチが間違っていることに気づいた場合**
   ```bash
   # 変更を一時保存
   git stash

   # 正しいブランチに移動（または作成）
   git checkout main
   git pull origin main
   git checkout -b feature/XX-correct-branch

   # 変更を適用
   git stash pop
   ```

**なぜこれが重要か？**

- **main ブランチの保護**: main は常に安定した状態を保つ必要があります
- **変更の追跡**: 各機能・修正が独立したブランチで管理され、レビューが容易
- **ロールバック**: 問題があった場合、ブランチごと削除すれば main は影響を受けない
- **並行作業**: 複数の機能を同時進行できる

### 基本フロー

```
1. Issue作成 → 2. ブランチ作成 → 3. 実装 → 4. PR作成 → 5. レビュー → 6. マージ
```

### ブランチ戦略

#### ブランチ命名規則

```
<type>/<issue番号>-<機能名>
```

**Type 一覧**:

- `feature/` - 新機能開発
- `bugfix/` - バグ修正
- `hotfix/` - 緊急修正
- `refactor/` - リファクタリング
- `docs/` - ドキュメント変更

**例**:

```bash
feature/55-platform-app
feature/57-documentation-system
bugfix/58-fix-cart-calculation
hotfix/59-critical-security-patch
refactor/60-cleanup-decorators
docs/61-update-readme
```

#### 保護ブランチ

- **main**: 本番環境デプロイ用（直接プッシュ禁止、PR 経由のみ）

### ブランチ作成手順

```bash
# 1. main を最新化
git checkout main
git pull origin main

# 2. Issue番号を確認（例: #57）
gh issue view 57

# 3. ブランチ作成
git checkout -b feature/57-documentation-system

# 4. 実装開始
# ...
```

---

## コミット規約

### Conventional Commits 準拠

**フォーマット**:

```
<type>(<scope>): <subject> (issue#<番号>)

<body>（オプション）

<footer>（オプション）
```

### Type 一覧

| Type       | 説明               | 例                                        |
| ---------- | ------------------ | ----------------------------------------- |
| `feat`     | 新機能             | `feat(platform): 清掃基準管理APIを実装`   |
| `fix`      | バグ修正           | `fix(rails): 在庫計算ロジックを修正`      |
| `docs`     | ドキュメント       | `docs: CONTRIBUTING.mdを追加`             |
| `refactor` | リファクタリング   | `refactor(platform): Decorator構造を整理` |
| `test`     | テスト追加・修正   | `test(rails): 商品モデルのテストを追加`   |
| `chore`    | ビルド・ツール設定 | `chore: Dockerfileを更新`                 |
| `perf`     | パフォーマンス改善 | `perf(rails): N+1クエリを解消`            |
| `style`    | コードスタイル     | `style: RuboCop違反を修正`                |

### Scope 一覧（オプション）

- `platform` - Platform 基幹アプリ
- `rails` - Shrimp Shells EC
- `n8n` - n8n ワークフロー
- `docker` - Docker 設定
- `db` - データベース
- `docs` - ドキュメント
- `infra` - インフラ設定

### 良いコミットメッセージの例

```bash
# ✅ GOOD
feat(platform): 清掃基準管理APIを実装 (issue#54)
fix(rails): カート合計金額の計算ロジックを修正 (issue#58)
docs: ARCHITECTURE.mdを追加 (issue#57)
refactor(rails): Product Decoratorを整理 (issue#60)
test(platform): CleaningStandardモデルのテストを追加 (issue#54)
chore(docker): PostgreSQL 16にアップグレード (issue#62)
```

### 悪いコミットメッセージの例

```bash
# ❌ BAD
update
fix bug
WIP
商品追加
🤖 Generated with Claude Code  # ツール署名は不要
```

### コミット時の注意事項

1. **1 コミット 1 機能**: 関連する変更のみを含める
2. **意味のある単位**: 「WIP」コミットは避ける
3. **日本語 OK**: subject は日本語で明確に
4. **Issue 番号必須**: `(issue#XX)` を必ず含める
5. **ツール署名削除**: Claude Code の署名は削除してからコミット

---

## PR 作成フロー

### 1. 実装とコミット

```bash
# 実装
# ...

# ステージング
git add .

# コミット
git commit -m "feat(platform): 清掃基準管理APIを実装 (issue#54)"

# プッシュ
git push origin feature/54-cleaning-standards
```

### 2. PR 作成

````bash
# GitHub CLIでPR作成
gh pr create --title "清掃基準管理APIを実装" --body "$(cat <<'EOF'
## 概要
issue#54の清掃基準管理APIを実装しました。

## 変更内容
- CleaningStandardモデル作成
- API v1エンドポイント実装
- Active Storage統合
- RSpecテスト追加

## テスト方法
```bash
make platform-up
make platform-console
# CleaningStandard.create!(...)
```

## チェックリスト

- [x] テスト追加
- [x] RuboCop 準拠
- [x] マイグレーション作成
- [x] ドキュメント更新

Closes #54
EOF
)"

````

### 3. PR テンプレート

PR には以下を含めてください：

````markdown
## 概要

[変更の概要を 1-2 文で説明]

## 変更内容

- [主要な変更点 1]
- [主要な変更点 2]
- [主要な変更点 3]

## テスト方法

```bash
[動作確認手順]
```

## スクリーンショット（必要に応じて）

[画面変更がある場合]

## チェックリスト

- [ ] テスト追加
- [ ] RuboCop 準拠
- [ ] マイグレーション作成
- [ ] ドキュメント更新
- [ ] セキュリティチェック

Closes #XX
````

### 4. レビュー対応

1. レビューコメントを確認
2. 修正実施
3. 追加コミット
4. レビュアーに通知

### 5. マージ

#### マージ戦略：Squash and Merge 推奨

このプロジェクトでは **Squash and Merge** を推奨します。

**✅ 推奨：Squash and Merge**

```bash
# GitHub UIで PR をマージする際、"Squash and merge" を選択
```

**メリット**:
- **綺麗な履歴**: main ブランチに 1 PR = 1 コミットとして記録される
- **読みやすさ**: WIP コミットや修正コミットが main に残らない
- **Conventional Commits**: PR タイトルがコミットメッセージになる
- **Issue ベース開発**: 1 Issue = 1 PR = 1 コミット

**例**:

```
# PR内のコミット履歴（開発中）
- WIP: 初期実装
- fix: typo修正
- refactor: コードレビュー対応
- test: テスト追加

↓ Squash and Merge

# mainブランチのコミット履歴（綺麗）
- feat(platform): 清掃基準管理APIを実装 (issue#54)
```

**他のマージ戦略を使う場合**:

| 戦略 | 使用ケース | 例 |
|------|----------|-----|
| **Merge commit** | 複数の独立した機能を含む大きなPR | リリースブランチのマージ |
| **Rebase and merge** | コミット履歴を保持したい場合 | 詳細な変更履歴が重要な場合 |

**デフォルト**: Squash and Merge

#### マージ後の作業

```bash
# ローカルブランチを削除
git checkout main
git pull origin main
git branch -d feature/54-cleaning-standards

# リモートブランチは GitHub が自動削除（設定により）
```

---

## コーディング規約

### Rails（Shrimp Shells EC / Platform）

#### 1. Decorator パターン必須

Solidus の拡張は**必ず**Decorator パターンを使用してください。

**✅ DO**: Decorator で拡張

```ruby
# app/models/spree/product_decorator.rb
module Spree
  module ProductDecorator
    def self.prepended(base)
      base.validates :shrimp_size, inclusion: { in: SHRIMP_SIZES.keys.map(&:to_s) }
    end

    def frozen_product?
      storage_temperature.present? && storage_temperature < 0
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
```

**❌ DON'T**: Gem ファイルを直接編集

```ruby
# vendor/bundle/gems/solidus/app/models/spree/product.rb
# 直接編集は絶対禁止！
```

#### 2. RuboCop 準拠

```bash
# チェック
docker compose run --rm shrimpshells-ec rubocop

# 自動修正
docker compose run --rm shrimpshells-ec rubocop -a
```

#### 3. ViewComponent 推奨

再利用可能な UI 部品は ViewComponent で実装：

```ruby
# app/components/product_card_component.rb
class ProductCardComponent < ViewComponent::Base
  def initialize(product:, show_cart: true)
    @product = product
    @show_cart = show_cart
  end
end
```

#### 4. Service Object パターン

複雑なビジネスロジックは Service Object に抽出：

```ruby
# app/services/cleaning_judge_service.rb
class CleaningJudgeService
  def initialize(cleaning_session:)
    @session = cleaning_session
  end

  def call
    # ビジネスロジック
  end
end
```

### JavaScript（Stimulus）

#### 1. Controller 命名規則

```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results"];

  search(event) {
    // ...
  }
}
```

#### 2. data 属性命名

```html
<div data-controller="search" data-search-url-value="<%= search_path %>">
  <input data-search-target="input" data-action="input->search#search" />
</div>
```

### データベース

#### 1. マイグレーション命名規則

```ruby
# タイムスタンプ_動詞_対象_詳細.rb
20251206_add_phone_number_to_spree_users.rb
20251206_create_cleaning_standards.rb
20251206_add_index_to_products_shrimp_size.rb
```

#### 2. ロールバック可能性

すべてのマイグレーションは`down`メソッドを実装：

```ruby
class AddPhoneNumberToSpreeUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :spree_users, :phone_number, :string
  end

  def down
    remove_column :spree_users, :phone_number
  end
end
```

#### 3. カラムコメント必須

```ruby
add_column :spree_products, :shrimp_size, :string, comment: "エビのサイズ（XL/L/M/S）"
add_column :spree_products, :storage_temperature, :decimal, comment: "保管温度（℃）"
```

---

## テスト方針

### RSpec 必須

すべての新機能・修正にはテストを追加してください。

#### モデルテスト

```ruby
# spec/models/spree/product_decorator_spec.rb
require 'rails_helper'

RSpec.describe Spree::Product, type: :model do
  describe '#frozen_product?' do
    it '保管温度が0℃未満の場合trueを返す' do
      product = build(:product, storage_temperature: -18)
      expect(product.frozen_product?).to be true
    end
  end
end
```

#### API テスト（Request Spec）

```ruby
# spec/requests/api/v1/cleaning_standards_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::CleaningStandards', type: :request do
  describe 'GET /api/v1/cleaning_standards' do
    it '清掃基準一覧を返す' do
      get '/api/v1/cleaning_standards'
      expect(response).to have_http_status(:ok)
    end
  end
end
```

#### コンポーネントテスト

```ruby
# spec/components/product_card_component_spec.rb
require 'rails_helper'

RSpec.describe ProductCardComponent, type: :component do
  it 'renders product name' do
    product = build(:product, name: 'ガーリックシュリンプ')
    render_inline(ProductCardComponent.new(product: product))

    expect(page).to have_text('ガーリックシュリンプ')
  end
end
```

### テスト実行

```bash
# 全テスト実行
docker compose run --rm shrimpshells-ec rspec

# 特定ファイルのみ
docker compose run --rm shrimpshells-ec rspec spec/models/spree/product_decorator_spec.rb

# カバレッジ確認
docker compose run --rm shrimpshells-ec rspec --format documentation
```

---

## コードレビュー基準

### 必須チェック項目

- [ ] **機能要件**: Issue の要件を満たしているか
- [ ] **テスト**: 十分なテストが追加されているか
- [ ] **コーディング規約**: RuboCop、ESLint に準拠しているか
- [ ] **命名**: 変数、メソッド、クラス名が適切か
- [ ] **コメント**: 複雑なロジックにコメントがあるか
- [ ] **パフォーマンス**: N+1 クエリなどの問題がないか
- [ ] **セキュリティ**: SQL インジェクション、XSS などの脆弱性がないか
- [ ] **データベース**: マイグレーションがロールバック可能か
- [ ] **ドキュメント**: README、ADR など必要に応じて更新されているか

### セキュリティチェック

#### 1. SQL インジェクション対策

**✅ DO**: パラメータバインディング使用

```ruby
Product.where("name LIKE ?", "%#{params[:query]}%")
```

**❌ DON'T**: 文字列補間

```ruby
Product.where("name LIKE '%#{params[:query]}%'")  # 危険！
```

#### 2. XSS 対策

**✅ DO**: ERB の自動エスケープ活用

```erb
<%= @product.name %>  # 自動エスケープ
```

**❌ DON'T**: raw 使用（必要な場合のみ）

```erb
<%=raw @product.html_description %>  # 要注意
```

#### 3. CSRF 対策

Rails 標準の CSRF 保護を維持：

```ruby
protect_from_forgery with: :exception
```

### パフォーマンスチェック

#### 1. N+1 クエリ回避

```ruby
# ✅ GOOD: eager loading
@products = Product.includes(:images, :variants).all

# ❌ BAD: N+1発生
@products = Product.all
@products.each { |p| p.images.first }  # N+1！
```

#### 2. インデックス追加

頻繁に検索するカラムにはインデックス：

```ruby
add_index :spree_products, :shrimp_size
add_index :spree_orders, [:user_id, :created_at]
```

---

## トラブルシューティング

### よくある問題と解決策

#### 1. Docker ビルドエラー

```bash
# エラー: "cannot find package..."
make clean
make up
```

#### 2. マイグレーションエラー

```bash
# エラー: "PG::DuplicateColumn"
# 解決: マイグレーションをロールバック
make shrimpshells-shell
cd /shrimpshells && bin/rails db:rollback
```

#### 3. ポート競合

```bash
# エラー: "port is already allocated"
# 解決: .envのポート番号を変更
PLATFORM_PORT=3004  # デフォルト: 3001
```

#### 4. Bundle install 失敗

```bash
# エラー: "bundle install failed"
# 解決: ボリューム削除して再ビルド
docker volume rm landbase_ai_suite_platform_bundle
make platform-up
```

#### 5. データベース接続エラー

```bash
# エラー: "could not connect to database"
# 解決: PostgreSQLの起動を確認
docker compose ps postgres
docker compose up -d postgres
```

### ログの見方

```bash
# 全サービスログ
make logs

# 特定サービスのログ
make platform-logs
make shrimpshells-logs
make n8n-logs
make mattermost-logs
make postgres-logs
```

### デバッグ方法

#### Rails Console

```bash
make platform-console
make shrimpshells-console
```

#### コンテナシェル接続

```bash
make platform-shell
make shrimpshells-shell
```

#### データベース直接接続

```bash
make postgres-shell
```

---

## 参考リンク

- [プロジェクトアーキテクチャ](./ARCHITECTURE.md)
- [Claude 向けガイド](./CLAUDE.md)
- [GitHub Flow](https://docs.github.com/ja/get-started/quickstart/github-flow)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [RuboCop](https://docs.rubocop.org/)
- [RSpec](https://rspec.info/)

---

## 質問・サポート

- **Issue**: [GitHub Issues](https://github.com/zomians/landbase_ai_suite/issues)
- **連絡先**: 株式会社 AI.LandBase

開発を楽しんでください！🚀
