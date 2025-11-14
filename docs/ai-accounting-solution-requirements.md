# AIドリブン管理会計ソリューション 要件定義書

**プロジェクト**: LandBase AI Suite - AI Management Accounting
**対象**: マルチテナントクライアント（小規模EC事業者）
**作成日**: 2025-01-14
**目的**: 経営者が AIアシスタントと対話しながら、リアルタイムで経営数値を把握・意思決定できる管理会計システム

---

## 1. エグゼクティブサマリー

### 1.1 プロジェクト概要

landbase_ai_suite のクライアント（小規模EC事業者、5-10名規模）に対して、**AIドリブン管理会計ソリューション**を提供します。

従来の管理会計ツールとの決定的な違い：

```
従来のツール:
  └─ 経営者が「数字を見に行く」
      └─ Excel、BI ツール、レポート画面
          └─ 複雑、時間がかかる、洞察なし

AIドリブン管理会計:
  └─ AIが「経営者に寄り添う」
      └─ 会話型インターフェース
          └─ 「先月の粗利率は？」
              └─ AIが即答 + 洞察 + 推奨アクション
```

---

### 1.2 市場トレンド（2025年）

**AI会計市場の急成長**:

- **市場規模**: 2025年 75.2億ドル → 2030年 502.9億ドル
- **成長率**: 年43%（2024-2029年）
- **最大の採用層**: 小規模〜中規模ビジネス（SMB）

**主要トレンド**:

1. **会話型AIアシスタント**: 自然言語で財務データをクエリ
2. **リアルタイムダッシュボード**: 売上、在庫、KPIが常に最新
3. **予測分析**: AIが将来のキャッシュフロー、売上トレンドを予測
4. **自動化**: データ入力、レポート生成の85%を自動化

**実例**:
- **Uber の Finch**: Slack 内で「先週の売上は？」と質問するだけ
- **QuickBooks Intuit Assist**: 自然言語でレシート処理、請求書生成
- **Sage Copilot**: AIが異常値を検知、改善提案を自動生成

---

### 1.3 LandBase AI Suite の差別化

| 項目 | 一般的なツール | LandBase AI Suite |
|------|--------------|-------------------|
| **対象** | 大企業、会計専門家 | 小規模EC、非会計専門家 |
| **統合** | 外部ツール連携 | EC（Solidus）と完全統合 |
| **AIレベル** | 基本的なチャットボット | Claude 3.5 Sonnet 会話型分析 |
| **カスタマイズ** | 画一的 | 業種特化（冷凍食品EC等） |
| **価格** | 月額数万円〜 | landbase_ai_suite に含まれる |
| **学習曲線** | 複雑、トレーニング必要 | 日本語会話だけで使える |

---

## 2. ビジネス要件

### 2.1 ユーザーペルソナ

**プライマリユーザー: 経営者兼システム管理者**

```
名前: 田中 太郎
年齢: 35歳
職業: Shrimp Shells 代表取締役
背景: プロの料理人、EC事業を立ち上げ

課題:
  ✗ 会計の専門知識がない
  ✗ Excelでの集計に時間がかかる
  ✗ 「今月黒字？赤字？」を即座に知りたい
  ✗ 広告費の費用対効果が分からない
  ✗ 在庫が適正か判断できない

期待:
  ✓ 朝のコーヒータイムに「今週の売上は？」と聞ける
  ✓ AIが「粗利率が下がってます。原因は○○です」と教えてくれる
  ✓ 「広告費を増やすべき？」と相談できる
  ✓ 月次レポートが自動で生成される
  ✓ 会計用語が分からなくても使える
```

**セカンダリユーザー: 経理担当者（将来的）**

事業成長後、経理専任者が加わった際にも対応可能な設計。

---

### 2.2 コアバリュー（提供価値）

#### Value 1: 会話するだけで数字が分かる

```
経営者: 「先月の売上は？」

AI: 「先月（12月）の売上は 198,000円 でした。

     📊 前月比: +12% (22,000円増)
     📈 目標達成率: 99% (目標 200,000円)

     💡 洞察:
     - 12/15-12/20 の週が特に好調（52,000円）
     - Instagram 経由の購入が +35% 増加
     - リピート率が 28% → 35% に改善

     💬 関連質問:
     「粗利率は？」「広告費対効果は？」「在庫状況は？」
```

#### Value 2: AIが異常を検知、アラート

```
AI からの自動通知（Mattermost）:

「⚠️ 粗利率の低下を検知しました

今月の粗利率: 42% (前月: 48%)
原因分析:
  1. 仕入原価が +8% 上昇
  2. 配送料が +15% 増加（冷凍便料金改定の影響）

推奨アクション:
  - 販売価格の見直し（+300円で粗利率 45% に回復）
  - 配送料の一部を顧客負担に
  - 大口購入割引を設定してロット単価を下げる

詳細を確認 →」
```

#### Value 3: 経営会議資料が自動生成

```
毎月1日 9:00、自動でレポート生成:

━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 2025年12月 月次経営レポート
━━━━━━━━━━━━━━━━━━━━━━━━━━

【サマリー】
✅ 売上: 198,000円 (目標達成率 99%)
✅ 新規顧客: 12名 (前月比 +20%)
⚠️ 粗利率: 42% (目標 45%、要改善)
✅ 在庫回転率: 2.1回 (適正範囲)

【トピックス】
🎉 Instagram 経由の売上が急増
   → SNS マーケティングが奏功
   → 次月も継続投資を推奨

⚠️ 仕入原価の上昇
   → サプライヤーとの価格交渉を検討
   → または販売価格の見直し

【次月のアクション】
1. 価格戦略の見直し（経営会議で決定）
2. Instagram 広告予算 +20,000円
3. 大口購入割引キャンペーン実施

詳細ダッシュボード →
━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 3. 機能要件

### 3.1 機能一覧

| 機能カテゴリ | 機能名 | 優先度 | 説明 |
|------------|--------|--------|------|
| **会話型AI** | 自然言語クエリ | P0 | 「先月の売上は？」で即答 |
| | 多段階対話 | P1 | 「なぜ？」「詳細は？」と深掘り可能 |
| | 音声入力 | P2 | スマホから音声で質問 |
| **ダッシュボード** | リアルタイムKPI | P0 | 売上、粗利率、在庫等が常に最新 |
| | カスタマイズ可能 | P1 | 経営者が重視するKPIを選択 |
| | モバイル対応 | P1 | スマホでも見やすい |
| **データ分析** | トレンド分析 | P0 | 売上推移、顧客動向を可視化 |
| | 異常検知 | P0 | 粗利率低下、在庫過多を自動検知 |
| | 予測分析 | P1 | 来月の売上、キャッシュフロー予測 |
| **レポート** | 月次レポート自動生成 | P0 | 毎月1日に自動作成 |
| | カスタムレポート | P1 | 経営者が必要な項目で作成 |
| | PDF/Excel エクスポート | P1 | 外部共有用 |
| **CRUD管理** | 経費登録 | P0 | 広告費、人件費等の手動入力 |
| | 在庫調整 | P0 | 棚卸、ロス処理 |
| | 予算管理 | P1 | 月次予算設定、実績対比 |
| **統合** | Solidus EC連携 | P0 | 売上、在庫の自動同期 |
| | n8n ワークフロー | P0 | データ同期、通知の自動化 |
| | Mattermost 通知 | P1 | 異常検知、レポート配信 |

**優先度**:
- **P0**: MVP（Minimum Viable Product）必須
- **P1**: 初期リリース後3ヶ月以内
- **P2**: 将来的な拡張

---

### 3.2 詳細機能仕様

#### 3.2.1 会話型AIアシスタント

**コア機能: 自然言語クエリ**

```ruby
# ユーザー入力例

「先月の売上は？」
「粗利率の推移を教えて」
「広告費の費用対効果はどう？」
「在庫が多すぎない？」
「今月黒字になりそう？」
「一番売れてる商品は？」
「リピート率はどのくらい？」
```

**AI応答の構成**:

```
1. 直接的な回答（数値）
2. コンテキスト（前月比、目標比）
3. 洞察（なぜその数値なのか）
4. 推奨アクション（次に何をすべきか）
5. 関連質問（深掘りの提案）
```

**実装アーキテクチャ**:

```
User Input (自然言語)
    ↓
Intent Classification (Claude API)
    ├─ sales_query
    ├─ profit_analysis
    ├─ inventory_check
    ├─ forecast_request
    └─ general_question
    ↓
Data Retrieval (PostgreSQL)
    ├─ SELECT FROM accounting_shrimp_shells.sales_records
    ├─ SELECT FROM accounting_shrimp_shells.kpi_snapshots
    └─ SELECT FROM ec_shrimp_shells.spree_orders
    ↓
Context Building (Ruby Service)
    ├─ 現在のデータ
    ├─ 過去のトレンド
    ├─ 業界ベンチマーク
    └─ 既知の問題
    ↓
AI Analysis (Claude API)
    ├─ データ解釈
    ├─ 洞察生成
    ├─ アクション推奨
    └─ 自然な日本語で応答
    ↓
Response to User
```

---

#### 3.2.2 リアルタイムKPIダッシュボード

**表示するKPI（優先度順）**:

| KPIカテゴリ | 指標 | 計算式 | 更新頻度 |
|-----------|------|--------|---------|
| **売上** | 今月の売上 | SUM(total_amount) | リアルタイム |
| | 前月比 | (今月 - 前月) / 前月 | リアルタイム |
| | 目標達成率 | 実績 / 目標 | リアルタイム |
| | 日次平均 | 売上 / 経過日数 | リアルタイム |
| **利益** | 粗利益 | 売上 - 原価 | リアルタイム |
| | 粗利率 | 粗利益 / 売上 | リアルタイム |
| | 営業利益 | 粗利益 - 経費 | 日次 |
| **顧客** | 新規顧客数 | COUNT(DISTINCT new customers) | リアルタイム |
| | リピート率 | リピーター / 全顧客 | 日次 |
| | 顧客獲得コスト (CAC) | 広告費 / 新規顧客数 | 週次 |
| | 顧客生涯価値 (LTV) | 平均購入額 × リピート回数 | 週次 |
| **在庫** | 在庫評価額 | SUM(在庫数 × 原価) | リアルタイム |
| | 在庫回転率 | 売上原価 / 平均在庫 | 週次 |
| | 欠品リスク | 在庫数 < 安全在庫 | リアルタイム |
| **経費** | 今月の経費 | SUM(expenses) | 日次 |
| | 広告費 | SUM(ad_expenses) | 日次 |
| | 広告費対効果 (ROAS) | 広告経由売上 / 広告費 | 日次 |

**ダッシュボードUI設計**:

```
┌─────────────────────────────────────────────────────┐
│  Shrimp Shells 管理会計ダッシュボード               │
│  最終更新: 2025-01-14 15:30 (リアルタイム)         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  💬 AIアシスタントに質問                            │
│  ┌─────────────────────────────────────────────┐  │
│  │ 「先月の粗利率は？」                         │  │
│  │ 「広告費対効果を教えて」                     │  │
│  │ 「在庫が多すぎない？」                       │  │
│  └─────────────────────────────────────────────┘  │
│                                                     │
│  📊 今月のサマリー（1/1 - 1/14）                   │
│  ┌────────────┬────────────┬────────────┬────────┐│
│  │ 売上       │ 粗利率     │ 新規顧客   │ 在庫   ││
│  │ ¥98,000    │ 45.2%      │ 5名        │ ¥280K  ││
│  │ ▲ +12%     │ ▼ -2.8%    │ ▲ +25%     │ ⚠️     ││
│  │ 目標: 65%  │ 目標: 48%  │ 目標: 4名  │ 適正   ││
│  └────────────┴────────────┴────────────┴────────┘│
│                                                     │
│  📈 売上推移（過去3ヶ月）                          │
│  [グラフ: 棒グラフ + トレンドライン]                │
│                                                     │
│  ⚠️ AIアラート                                      │
│  • 粗利率が目標を下回っています (-2.8%)            │
│    → 詳細を見る                                     │
│  • 在庫回転率が低下しています (1.8回 → 1.5回)      │
│    → AIに相談する                                   │
│                                                     │
│  🎯 今週のアクション                                │
│  □ 仕入価格の見直し（粗利率改善）                  │
│  □ Instagram広告 +10,000円投入                      │
│  ✓ 月次レポート確認済み                             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

#### 3.2.3 AI異常検知＆アラート

**検知ルール**:

| 異常タイプ | 検知条件 | アラートレベル | 通知先 |
|----------|---------|--------------|--------|
| **粗利率低下** | 前月比 -5% 以上 | ⚠️ Warning | Mattermost |
| **売上急減** | 前週比 -20% 以上 | 🚨 Critical | Mattermost + メール |
| **在庫過多** | 在庫回転率 < 1.0 | ⚠️ Warning | ダッシュボード |
| **欠品リスク** | 在庫数 < 安全在庫 | 🚨 Critical | Mattermost |
| **広告費高騰** | ROAS < 200% | ⚠️ Warning | ダッシュボード |
| **キャッシュ不足予測** | 30日後の残高 < 100万 | 🚨 Critical | Mattermost + メール |

**アラート通知例**:

```
[Mattermost 通知]

🚨 粗利率が大幅に低下しています

現在の粗利率: 42.3%
前月: 48.1% (-5.8%)
目標: 45.0%

━━━━━━━━━━━━━━━━━━━━
原因分析（AIによる自動分析）:
━━━━━━━━━━━━━━━━━━━━

1. 仕入原価の上昇 (主要因)
   - エビの仕入単価: ¥1,200 → ¥1,350 (+12.5%)
   - 影響額: -¥15,000/月

2. 配送料の増加
   - 冷凍便料金改定: +¥50/個
   - 影響額: -¥2,500/月

━━━━━━━━━━━━━━━━━━━━
推奨アクション:
━━━━━━━━━━━━━━━━━━━━

優先度1: 販売価格の見直し
  → 現在 ¥3,980 を ¥4,280 に (+300円)
  → 粗利率 45.5% に回復（目標達成）
  → 想定売上影響: -5% (価格弾力性考慮)

優先度2: サプライヤー交渉
  → 発注ロットを 100個 → 200個 に
  → 単価 ¥1,350 → ¥1,250 交渉可能性

優先度3: 配送料の一部顧客負担
  → 3,000円未満の注文に +300円
  → 平均購入額の増加も期待

━━━━━━━━━━━━━━━━━━━━
AIとの相談:
━━━━━━━━━━━━━━━━━━━━

💬 「価格を上げたら売上はどうなる？」
💬 「サプライヤー交渉のポイントは？」
💬 「配送料負担の影響をシミュレーションして」

👉 ダッシュボードで詳細を確認
```

---

#### 3.2.4 月次レポート自動生成

**生成タイミング**: 毎月1日 9:00（自動）

**レポート構成**:

```markdown
# 2025年12月 月次経営レポート

**生成日時**: 2025-01-01 09:00
**対象期間**: 2024-12-01 ~ 2024-12-31
**自動生成**: AI Management Accounting System

---

## 📊 エグゼクティブサマリー

### 総合評価: B+ (前月: B)

| 項目 | 実績 | 目標 | 達成率 | 評価 |
|------|------|------|--------|------|
| 売上 | ¥198,000 | ¥200,000 | 99% | ✅ A |
| 粗利率 | 42.3% | 45.0% | 94% | ⚠️ B |
| 新規顧客 | 12名 | 10名 | 120% | ✅ A+ |
| リピート率 | 35% | 30% | 117% | ✅ A+ |

**総評**:
売上は目標にわずかに届かなかったものの、新規顧客獲得とリピート率が
大幅に改善し、顧客基盤の強化に成功しました。一方で、粗利率の低下が
懸念材料であり、来月の最優先課題となります。

---

## 📈 売上分析

### 売上推移

| 週 | 売上 | 前週比 | 備考 |
|----|------|--------|------|
| 第1週 (12/1-12/7) | ¥38,000 | - | 通常 |
| 第2週 (12/8-12/14) | ¥52,000 | +37% | Instagram 投稿効果 |
| 第3週 (12/15-12/21) | ¥48,000 | -8% | 通常 |
| 第4週 (12/22-12/28) | ¥60,000 | +25% | 年末需要 |

**AI洞察**:
- 第2週の急増は 12/10 の Instagram Reels 投稿（シェア数 120）が主因
- 年末需要（第4週）は予想を上回り、ギフト需要の可能性を示唆
- 来年のInstagram戦略継続と、ギフトセット開発を推奨

### チャネル別売上

| チャネル | 売上 | 構成比 | 前月比 |
|---------|------|--------|--------|
| Instagram | ¥89,000 | 45% | +35% |
| Google 検索 | ¥54,000 | 27% | +5% |
| 直接流入 | ¥32,000 | 16% | -10% |
| その他 | ¥23,000 | 12% | +8% |

---

## 💰 利益分析

### 粗利益

| 項目 | 金額 | 割合 |
|------|------|------|
| 売上 | ¥198,000 | 100% |
| 売上原価 | ¥114,000 | 57.6% |
| **粗利益** | **¥84,000** | **42.4%** |

⚠️ **問題点**: 粗利率が目標（45%）を下回る
   - 原因: 仕入原価 +12.5%、配送料 +8%
   - 影響額: -¥5,400/月

### 経費内訳

| カテゴリ | 金額 | 構成比 |
|---------|------|--------|
| 広告費 | ¥28,000 | 42% |
| 配送料 | ¥18,000 | 27% |
| 人件費 | ¥15,000 | 22% |
| その他 | ¥6,000 | 9% |
| **合計** | **¥67,000** | **100%** |

### 営業利益

| 項目 | 金額 |
|------|------|
| 粗利益 | ¥84,000 |
| 経費 | ¥67,000 |
| **営業利益** | **¥17,000** |
| **営業利益率** | **8.6%** |

✅ **好材料**: 営業利益率が前月（6.5%）から改善

---

## 👥 顧客分析

### 新規 vs リピート

| 顧客タイプ | 人数 | 売上 | 平均購入額 |
|-----------|------|------|-----------|
| 新規 | 12名 | ¥47,000 | ¥3,917 |
| リピート | 18名 | ¥151,000 | ¥8,389 |
| **合計** | **30名** | **¥198,000** | **¥6,600** |

**AI洞察**:
- リピーターの平均購入額が新規の2.1倍
- リピーター育成が売上拡大の鍵
- ロイヤルティプログラム導入を検討すべき

### LTV / CAC 分析

| 指標 | 数値 | 評価 |
|------|------|------|
| 顧客獲得コスト (CAC) | ¥2,333 | - |
| 顧客生涯価値 (LTV) | ¥16,800 | - |
| LTV / CAC 比率 | 7.2 | ✅ 健全 (目標: > 3.0) |

---

## 📦 在庫分析

### 在庫状況

| 指標 | 数値 | 評価 |
|------|------|------|
| 在庫評価額 | ¥280,000 | - |
| 在庫回転率 | 1.5回/月 | ⚠️ やや低い (目標: 2.0) |
| 欠品日数 | 0日 | ✅ 良好 |

**AI洞察**:
- 在庫回転率の低下は、年末の仕入増加が主因
- 1月の需要予測（+10%）を考慮すると適正範囲
- 2月は仕入を10%削減して在庫最適化を推奨

---

## 🎯 来月のアクションプラン

### 最優先タスク

1. **粗利率の改善**
   - [ ] 販売価格の見直し（+300円）
   - [ ] サプライヤーとの価格交渉
   - [ ] 目標: 粗利率 45% 達成

2. **Instagram マーケティング強化**
   - [ ] 週2回の Reels 投稿継続
   - [ ] 広告予算 +20% (¥28,000 → ¥33,600)
   - [ ] 目標: Instagram 経由売上 ¥100,000

3. **ギフトセット開発**
   - [ ] 4食セット（化粧箱入り）の企画
   - [ ] 2月のバレンタイン需要に向けて準備
   - [ ] 目標: ギフト売上 ¥30,000

### 予算計画

| 項目 | 予算 | 前月比 |
|------|------|--------|
| 売上目標 | ¥220,000 | +11% |
| 広告費 | ¥33,600 | +20% |
| 仕入 | ¥110,000 | -3% |

---

## 💬 AIとの相談（推奨質問）

- 「価格を ¥4,280 にしたら売上はどうなる？」
- 「Instagram 広告予算の最適額は？」
- 「ギフトセットの価格設定のアドバイスは？」
- 「2月の売上予測は？」

👉 ダッシュボードで AI に質問する

---

**レポート終了**
次回生成: 2025-02-01 09:00
```

---

## 4. 技術要件

### 4.1 システムアーキテクチャ

```
┌──────────────────────────────────────────────────────────┐
│                    User Interface                         │
├──────────────────────────────────────────────────────────┤
│  Web Dashboard (Rails Views + Hotwire)                   │
│  └─ Responsive Design (Desktop / Mobile)                 │
│                                                            │
│  Conversational UI (Chat Interface)                       │
│  └─ Real-time messaging with Action Cable                 │
└──────────────────────────────────────────────────────────┘
                         ↕
┌──────────────────────────────────────────────────────────┐
│                  Application Layer                        │
├──────────────────────────────────────────────────────────┤
│  Rails 8.0 Application                                   │
│  ├─ Controllers                                           │
│  │   ├─ AccountingDashboardController                    │
│  │   ├─ AiAssistantController                            │
│  │   ├─ SalesController (CRUD)                           │
│  │   ├─ InventoryController (CRUD)                       │
│  │   └─ ExpensesController (CRUD)                        │
│  │                                                         │
│  ├─ Services                                              │
│  │   ├─ AiAssistantService (Claude API Integration)      │
│  │   ├─ KpiCalculatorService                             │
│  │   ├─ AnomalyDetectionService                          │
│  │   ├─ ReportGeneratorService                           │
│  │   └─ AccountingSyncService (Solidus → Accounting)     │
│  │                                                         │
│  └─ Jobs (Sidekiq)                                        │
│      ├─ GenerateDailyKpiJob                               │
│      ├─ AnomalyDetectionJob                               │
│      ├─ MonthlyReportGeneratorJob                         │
│      └─ DataSyncJob                                        │
└──────────────────────────────────────────────────────────┘
                         ↕
┌──────────────────────────────────────────────────────────┐
│                    Data Layer                             │
├──────────────────────────────────────────────────────────┤
│  PostgreSQL (Multi-Schema)                               │
│  ├─ accounting_shrimp_shells                             │
│  │   ├─ sales_records                                     │
│  │   ├─ inventory_logs                                    │
│  │   ├─ expense_records                                   │
│  │   ├─ kpi_snapshots                                     │
│  │   ├─ ai_insights                                       │
│  │   ├─ budgets                                           │
│  │   └─ conversation_history (AI chat log)               │
│  │                                                         │
│  └─ ec_shrimp_shells (Solidus tables)                    │
│      ├─ spree_orders                                      │
│      ├─ spree_line_items                                  │
│      ├─ spree_stock_items                                 │
│      └─ ...                                                │
└──────────────────────────────────────────────────────────┘
                         ↕
┌──────────────────────────────────────────────────────────┐
│                  External Services                        │
├──────────────────────────────────────────────────────────┤
│  Claude API (Anthropic)                                  │
│  └─ Model: claude-3-5-sonnet-20250514                    │
│      ├─ Intent Classification                             │
│      ├─ Data Analysis                                     │
│      ├─ Insight Generation                                │
│      └─ Report Generation                                 │
│                                                            │
│  n8n (Workflow Automation)                                │
│  └─ Scheduled Jobs                                        │
│      ├─ Daily KPI Calculation                             │
│      ├─ Anomaly Detection                                 │
│      └─ Report Distribution                               │
│                                                            │
│  Mattermost (Notifications)                               │
│  └─ Alerts, Reports                                       │
└──────────────────────────────────────────────────────────┘
```

---

### 4.2 データベース設計（詳細）

既に `solidus-ec-architecture.md` で設計済みのテーブルに加えて、以下を追加：

```sql
-- accounting_shrimp_shells.budgets
CREATE TABLE budgets (
  id BIGSERIAL PRIMARY KEY,
  period_type VARCHAR(20) NOT NULL,      -- monthly, quarterly, yearly
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  category VARCHAR(50) NOT NULL,         -- revenue, cogs, expenses, profit
  subcategory VARCHAR(100),              -- 詳細カテゴリ
  budgeted_amount DECIMAL(12,2) NOT NULL,
  actual_amount DECIMAL(12,2),
  variance DECIMAL(12,2),                -- actual - budgeted
  variance_pct DECIMAL(5,2),             -- (actual - budgeted) / budgeted
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_period (period_start, period_end),
  INDEX idx_category (category)
);

-- accounting_shrimp_shells.conversation_history
CREATE TABLE conversation_history (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  session_id VARCHAR(100),               -- 会話セッションID
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  intent VARCHAR(50),                    -- sales_query, profit_analysis, etc.
  query_context JSONB,                   -- クエリ実行時のコンテキスト
  execution_time_ms INTEGER,             -- AI応答時間
  user_rating INTEGER,                   -- 1-5 (ユーザー評価、オプション)
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_user (user_id),
  INDEX idx_session (session_id),
  INDEX idx_intent (intent),
  INDEX idx_created_at (created_at)
);

-- accounting_shrimp_shells.alerts
CREATE TABLE alerts (
  id BIGSERIAL PRIMARY KEY,
  alert_type VARCHAR(50) NOT NULL,       -- anomaly, threshold, forecast
  severity VARCHAR(20) NOT NULL,         -- info, warning, critical
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  detected_value DECIMAL(12,2),
  threshold_value DECIMAL(12,2),
  related_metric VARCHAR(100),
  recommended_actions JSONB,             -- [{action: "...", priority: 1}, ...]
  status VARCHAR(20) DEFAULT 'active',   -- active, acknowledged, resolved
  acknowledged_at TIMESTAMP,
  acknowledged_by BIGINT,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_status (status),
  INDEX idx_severity (severity),
  INDEX idx_created_at (created_at)
);
```

---

### 4.3 Claude API 統合設計

#### Intent Classification（意図分類）

```ruby
# app/services/ai_intent_classifier.rb

class AiIntentClassifier
  INTENTS = {
    'sales_query' => '売上に関する質問',
    'profit_analysis' => '利益・粗利率に関する質問',
    'inventory_check' => '在庫に関する質問',
    'expense_inquiry' => '経費に関する質問',
    'customer_analysis' => '顧客に関する質問',
    'forecast_request' => '予測・見通しに関する質問',
    'comparison' => '比較分析（前月比、目標比等）',
    'recommendation' => 'アドバイス・推奨アクションの要求',
    'general_question' => '一般的な質問'
  }.freeze

  def classify(user_message)
    prompt = <<~PROMPT
      以下のユーザーメッセージから、意図を分類してください。

      ユーザーメッセージ: "#{user_message}"

      意図の候補:
      #{INTENTS.map { |k, v| "- #{k}: #{v}" }.join("\n")}

      JSON形式で返してください:
      {
        "intent": "最も適切な意図のキー",
        "confidence": 0.0-1.0,
        "entities": {
          "period": "先月, 今月, 12月 等（あれば）",
          "metric": "売上, 粗利率, 在庫 等（あれば）"
        }
      }
    PROMPT

    response = call_claude(prompt, max_tokens: 500)
    JSON.parse(response)
  end

  private

  def call_claude(prompt, max_tokens: 1000)
    # Claude API 呼び出し（共通メソッド）
    # ...
  end
end
```

---

#### Conversational Query Processing

```ruby
# app/services/ai_assistant_service.rb

class AiAssistantService
  def initialize(user_message, user_id:, session_id: nil)
    @user_message = user_message
    @user_id = user_id
    @session_id = session_id || SecureRandom.uuid
  end

  def process
    # 1. 意図分類
    intent_result = AiIntentClassifier.new.classify(@user_message)

    # 2. データ取得
    context = build_context(intent_result)

    # 3. AI分析
    ai_response = generate_response(intent_result, context)

    # 4. 会話履歴保存
    save_conversation(intent_result, ai_response, context)

    ai_response
  end

  private

  def build_context(intent_result)
    case intent_result['intent']
    when 'sales_query'
      {
        current_month_sales: Accounting::SalesRecord.current_month_total,
        last_month_sales: Accounting::SalesRecord.last_month_total,
        ytd_sales: Accounting::SalesRecord.year_to_date_total,
        daily_average: Accounting::SalesRecord.daily_average,
        target: Budget.find_by(category: 'revenue', period_type: 'monthly')&.budgeted_amount
      }
    when 'profit_analysis'
      {
        gross_profit: Accounting::KpiSnapshot.latest&.gross_profit,
        gross_margin_rate: Accounting::KpiSnapshot.latest&.gross_margin_rate,
        last_month_margin: Accounting::KpiSnapshot.last_month&.gross_margin_rate,
        cogs_breakdown: Accounting::SalesRecord.cogs_breakdown
      }
    # ... 他の intent に応じたコンテキスト構築
    end
  end

  def generate_response(intent_result, context)
    prompt = <<~PROMPT
      あなたは Shrimp Shells のAI管理会計アシスタントです。

      ユーザーの質問: "#{@user_message}"
      意図: #{intent_result['intent']}

      現在のデータ:
      #{JSON.pretty_generate(context)}

      以下の形式で応答してください:

      {
        "answer": "ユーザーへの直接的な回答（簡潔に）",
        "details": {
          "main_metric": "主要な数値",
          "context": "前月比、目標比などのコンテキスト",
          "insights": ["洞察1", "洞察2", ...],
          "recommendations": [
            {"action": "推奨アクション1", "priority": 1},
            {"action": "推奨アクション2", "priority": 2}
          ]
        },
        "follow_up_questions": ["関連質問1", "関連質問2", ...]
      }

      要件:
      - 会計用語を避け、経営者にわかりやすい言葉で
      - 具体的な数値を必ず含める
      - 「なぜそうなのか」を説明する
      - 次にすべきアクションを提案する
      - 日本語で自然な表現
    PROMPT

    response = call_claude(prompt, max_tokens: 2048)
    JSON.parse(response)
  end

  def save_conversation(intent_result, ai_response, context)
    Accounting::ConversationHistory.create!(
      user_id: @user_id,
      session_id: @session_id,
      user_message: @user_message,
      ai_response: ai_response.to_json,
      intent: intent_result['intent'],
      query_context: context.to_json,
      execution_time_ms: 0 # TODO: 実測定
    )
  end

  def call_claude(prompt, max_tokens:)
    # Claude API 呼び出し
  end
end
```

---

## 5. 実装ロードマップ

### Phase 1: 基盤構築（Week 1-2）

- [ ] データベーステーブル作成
  - budgets, conversation_history, alerts
- [ ] 基本的なCRUD画面
  - 経費登録、在庫調整、予算設定
- [ ] Solidus → Accounting データ同期
  - AccountingSyncService 実装
  - 売上、在庫ログの自動同期

### Phase 2: KPI計算＆ダッシュボード（Week 3-4）

- [ ] KpiCalculatorService 実装
- [ ] リアルタイムダッシュボード構築
- [ ] 基本的なグラフ表示（売上推移、粗利率等）
- [ ] GenerateDailyKpiJob 実装（日次バッチ）

### Phase 3: AIアシスタント（Week 5-6）

- [ ] Claude API 統合
- [ ] AiIntentClassifier 実装
- [ ] AiAssistantService 実装
- [ ] 会話型UI構築（チャットインターフェース）
- [ ] 基本的なクエリ対応
  - 売上、粗利率、在庫の質問応答

### Phase 4: 異常検知＆アラート（Week 7-8）

- [ ] AnomalyDetectionService 実装
- [ ] 検知ルール設定
- [ ] Mattermost 通知連携
- [ ] アラート管理画面

### Phase 5: レポート自動生成（Week 9-10）

- [ ] ReportGeneratorService 実装
- [ ] 月次レポートテンプレート作成
- [ ] MonthlyReportGeneratorJob 実装
- [ ] PDF/Excel エクスポート機能

### Phase 6: 高度な機能（Week 11-12）

- [ ] 予測分析（売上予測、キャッシュフロー予測）
- [ ] カスタムレポート作成機能
- [ ] モバイル最適化
- [ ] パフォーマンスチューニング

---

## 6. 成功指標（KPI）

### 6.1 システムKPI

| 指標 | 目標値 | 測定方法 |
|------|--------|---------|
| **AI応答時間** | < 3秒 | CloudWatch Logs |
| **AI回答精度** | > 90% | ユーザー評価 |
| **ダッシュボード読み込み** | < 2秒 | New Relic |
| **データ同期遅延** | < 5分 | Sidekiq監視 |
| **システム稼働率** | > 99.5% | Pingdom |

### 6.2 ユーザー体験KPI

| 指標 | 目標値 | 測定方法 |
|------|--------|---------|
| **DAU (Daily Active Users)** | 80% (週5日利用) | Google Analytics |
| **AI質問数** | 平均 5回/日 | conversation_history |
| **レポート閲覧率** | 100% (全員が月次レポート確認) | イベントトラッキング |
| **ユーザー満足度** | > 4.5/5.0 | アンケート |

### 6.3 ビジネスKPI

| 指標 | 目標値 | 期待効果 |
|------|--------|---------|
| **意思決定速度** | 50%短縮 | AIによる即時回答 |
| **経理作業時間** | 70%削減 | 自動化 |
| **粗利率改善** | +3% | 異常検知によるアラート |
| **予算達成率** | +15% | データドリブン意思決定 |

---

## 7. リスク＆対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| **Claude API障害** | 高 | キャッシュ機構、フォールバック応答 |
| **データ精度問題** | 高 | データバリデーション強化 |
| **ユーザーの学習曲線** | 中 | オンボーディングガイド、サンプル質問 |
| **コスト超過（API費用）** | 中 | 使用量監視、キャッシュ戦略 |
| **セキュリティ** | 高 | データ暗号化、アクセス制御 |

---

## 8. 次のアクション

1. **要件レビュー**: 本要件定義書のレビュー、承認
2. **技術検証**: Claude API の管理会計ユースケース検証
3. **データベース設計**: テーブル作成、マイグレーション
4. **Phase 1 開始**: 基盤構築（Week 1-2）

---

**Document Version**: 1.0
**Last Updated**: 2025-01-14
**Next Review**: 2025-02-14（Phase 1完了後）
**Owner**: LandBase AI Suite Development Team
