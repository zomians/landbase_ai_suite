# n8n × Perplexity AI 連携ワークフロー セットアップガイド

## 📋 目次

- [概要](#概要)
- [前提条件](#前提条件)
- [セットアップ手順](#セットアップ手順)
- [テスト方法](#テスト方法)
- [使用例](#使用例)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

このワークフローは、LINE公式アカウント経由でユーザーからの質問を受け取り、Perplexity AIを使ってリアルタイムWeb検索に基づく回答を生成し、LINE返信する観光コンシェルジュシステムです。

```
LINEテキスト受信
    ↓
Perplexity API
  - リアルタイムWeb検索
  - 引用元付き回答生成
    ↓
LINE返信
  - 回答本文
  - 参考URL
```

**ファイル:** `n8n/workflows/line-perplexity-qa.json`

---

## 前提条件

### 1. 必要なサービス

- ✅ n8n (Self-hosted: `http://localhost:5678`)
- ✅ LINE Developers アカウント（Messaging API）
- ✅ Perplexity API アカウント

### 2. APIキー取得

#### Perplexity API

1. [Perplexity AI](https://www.perplexity.ai/) にアクセス
2. Settings → API → Generate New API Key
3. APIキーをコピー（後で使用）

#### LINE Messaging API

1. [LINE Developers Console](https://developers.line.biz/console/) にアクセス
2. Channel Settings → Messaging API
3. **Channel Access Token** を発行・コピー

---

## セットアップ手順

### Step 1: n8n Credentials設定（15分）

#### 1-1. Perplexity API認証情報

n8nで以下を設定：

| 項目 | 値 |
|------|-----|
| **Credential Type** | Header Auth |
| **Name** | `Perplexity API Auth` |
| **Header Name** | `Authorization` |
| **Header Value** | `Bearer YOUR_PERPLEXITY_API_KEY` |

> **注意**: `Bearer ` の後にスペースを入れてAPIキーを貼り付けてください。

#### 1-2. LINE Bot認証情報

既存の `LINE Bot Auth` credentialを使用（設定済みの場合はスキップ）

| 項目 | 値 |
|------|-----|
| **Credential Type** | Header Auth |
| **Name** | `LINE Bot Auth` |
| **Header Name** | `Authorization` |
| **Header Value** | `Bearer YOUR_LINE_CHANNEL_ACCESS_TOKEN` |

### Step 2: ワークフローインポート（5分）

1. n8n管理画面（`http://localhost:5678`）にアクセス
2. **Workflows** → **Import from File**
3. `n8n/workflows/line-perplexity-qa.json` を選択
4. インポート完了

### Step 3: Credentialsマッピング（5分）

インポート後、各ノードにcredentialsを設定：

#### Perplexity APIノード

1. **Perplexity API** ノードをクリック
2. **Credentials** → `Perplexity API Auth` を選択

#### LINE Replyノード

1. **LINE Reply** ノードをクリック
2. **Credentials** → `LINE Bot Auth` を選択

### Step 4: Webhook URL取得・設定（10分）

#### 4-1. n8nでWebhook URL取得

1. **Webhook** ノードをクリック
2. **Production URL** をコピー
   - 例: `https://your-n8n-instance.com/webhook/line-perplexity-webhook`

#### 4-2. LINE Developers Consoleで設定

1. [LINE Developers Console](https://developers.line.biz/console/) にアクセス
2. 該当のChannel → **Messaging API**
3. **Webhook URL** に先ほどのURLを貼り付け
4. **Use webhook** を `Enabled` に変更
5. **Verify** をクリックして疎通確認

### Step 5: ワークフロー有効化（1分）

1. n8nのワークフロー画面で **Active** トグルをONにする
2. 保存

---

## テスト方法

### 基本動作テスト

#### 1. LINEで質問送信

LINEアプリで公式アカウントに以下のメッセージを送信：

```
今帰仁村の美ら海水族館の営業時間は？
```

#### 2. 期待される応答

```
美ら海水族館の営業時間は以下の通りです：

通常期（10月～2月）: 8:30～18:30（入館締切 17:30）
繁忙期（3月～9月）: 8:30～20:00（入館締切 19:00）

年中無休で営業しています。

📚 参考:
https://churaumi.okinawa/guide/...
```

---

## 使用例

### 観光案内

**質問:**
```
古宇利島への行き方を教えて
```

**回答例:**
```
古宇利島への主なアクセス方法をご案内します：

🚗 **車でのアクセス**
- 那覇空港から約1時間30分
- 沖縄自動車道 → 許田IC → 国道58号・県道110号経由
- 古宇利大橋（無料）を渡って到着

🚌 **バスでのアクセス**
- やんばる急行バス or 路線バス65番・66番
- 運天原バス停下車、タクシーで約10分

📚 参考:
https://www.kourijima.info/access/
```

### 天気・イベント情報

**質問:**
```
明日の名護市の天気は？
```

**回答例:**
```
明日（12月13日）の名護市の天気予報：

🌤️ 晴れ時々曇り
🌡️ 最高気温: 23℃ / 最低気温: 18℃
💨 風: 北東の風、やや強い
☔ 降水確率: 20%

観光には良い天候です。

📚 参考:
https://weather.yahoo.co.jp/weather/jp/47/9210/47209.html
```

### レストラン検索

**質問:**
```
今帰仁村でおすすめの海鮮料理店は？
```

---

## トラブルシューティング

### 1. LINE返信がない

#### 症状
質問を送っても何も返ってこない

#### 確認ポイント

✅ **n8nワークフローがActive**
- n8n管理画面でワークフローが有効化されているか

✅ **Webhook URLが正しい**
- LINE Developers ConsoleのWebhook URLとn8nのProduction URLが一致しているか

✅ **Credentialsが設定されている**
- Perplexity APIノードとLINE Replyノードにcredentialsが設定されているか

✅ **n8nの実行ログを確認**
- n8n管理画面 → Executions → エラー内容を確認

### 2. Perplexity APIエラー

#### 症状
```
401 Unauthorized
```

#### 解決策
- Perplexity API Keyが正しいか確認
- `Bearer ` の後にスペースがあるか確認
- APIキーの有効期限が切れていないか確認

#### 症状
```
429 Too Many Requests
```

#### 解決策
- APIリクエスト制限に達しています
- Perplexity APIの利用プランを確認
- 時間をおいて再試行

### 3. テキスト以外のメッセージ（画像、スタンプ等）

#### 症状
画像やスタンプを送っても反応しない

#### 説明
このワークフローは **テキストメッセージのみ** に対応しています。`IF Text Message` ノードでフィルタリングしているため、意図的な動作です。

画像対応が必要な場合は、別のワークフローを使用してください：
- `line-to-gdrive.json` （画像 → Google Drive保存）
- `line-accounting-automation.json` （領収書OCR処理）

### 4. 日本語以外の質問

#### 症状
英語や中国語で質問しても日本語で返ってくる

#### 説明
System Promptで「日本語で提供してください」と指定しているためです。

#### 多言語対応方法

Perplexity APIノードの `jsonBody` を以下に変更：

```json
{
  "model": "sonar-pro",
  "messages": [
    {
      "role": "system",
      "content": "You are a tourism concierge in northern Okinawa. Respond in the same language as the user's question with accurate, up-to-date information from web searches."
    },
    {
      "role": "user",
      "content": "{{ $json.body.events[0].message.text }}"
    }
  ],
  "temperature": 0.2,
  "return_citations": true,
  "max_tokens": 500
}
```

---

## 📊 パフォーマンス

### レスポンス時間

- 平均: **3～5秒**
  - LINE受信 → Perplexity検索 → LINE返信

### コスト

#### Perplexity API料金（2025年12月時点）

- **sonar-pro**: ~$0.001/リクエスト
- **sonar**: ~$0.0005/リクエスト

#### 月間コスト試算

| 月間質問数 | sonar-pro | sonar |
|-----------|-----------|-------|
| 100       | $0.10     | $0.05 |
| 1,000     | $1.00     | $0.50 |
| 10,000    | $10.00    | $5.00 |

---

## 🚀 次のステップ

### Phase 2: マルチテナント対応

- [ ] 顧客マスター参照（Google Sheets）
- [ ] クライアント別System Prompt設定
- [ ] 質問履歴保存

### Phase 3: 回答品質向上

- [ ] プロンプトエンジニアリング最適化
- [ ] 引用元の見やすい表示（LINE Flex Message）
- [ ] 関連情報の提案

### Phase 4: 拡張機能

- [ ] エラーハンドリング強化
- [ ] 不適切な質問フィルタ
- [ ] 質問カテゴリ分類（観光/天気/グルメ等）

---

## 📚 参考資料

- [Perplexity API Documentation](https://docs.perplexity.ai/)
- [LINE Messaging API Reference](https://developers.line.biz/ja/reference/messaging-api/)
- [n8n Documentation](https://docs.n8n.io/)

---

**最終更新:** 2025-12-12
**バージョン:** 1.0
**担当者:** @zomians
