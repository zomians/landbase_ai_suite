# OpenAI API 設定ガイド

## 1. OpenAI APIキーの取得

### 手順

1. OpenAI Platform にアクセス
   - URL: https://platform.openai.com/api-keys

2. ログイン
   - OpenAIアカウントでログイン（アカウントがない場合は新規作成）

3. APIキーの作成
   - 「+ Create new secret key」をクリック
   - 名前を入力（例: "landbase-ai-suite-n8n"）
   - 権限: "All" または必要な権限のみ選択
   - 「Create secret key」をクリック

4. APIキーをコピー
   - **重要**: 表示されたキーは一度しか表示されません
   - 必ずコピーして安全な場所に保存してください
   - 形式: `sk-proj-...` または `sk-...`

---

## 2. n8nでの設定方法

### 方法A: n8n UI（推奨）

#### ステップ1: Credentials画面を開く

1. n8n UIにアクセス: http://localhost:5678
2. 左メニュー → **Settings**（歯車アイコン）
3. **Credentials** をクリック

#### ステップ2: OpenAI Credentialを作成

1. 右上の **「+ Add Credential」** をクリック
2. 検索: **"OpenAI"**
3. **「OpenAI」** を選択

#### ステップ3: 設定を入力

| 項目 | 入力内容 |
|------|---------|
| **Credential Name** | `openai-api` ← **この名前を必ず使用** |
| **API Key** | 取得したAPIキー（`sk-...`） |
| **Organization ID** | （オプション）組織IDがある場合のみ |

4. **Save** をクリック

---

### 方法B: 環境変数経由（参考）

`.env.local` ファイルにAPIキーを記載する方法もありますが、n8nでは直接 Credential として設定する方が推奨されます。

```bash
# .env.local
OPENAI_API_KEY=sk-proj-your_actual_api_key_here
```

---

## 3. 設定の確認

### n8n UIで確認

1. n8n UI → Settings → Credentials
2. `openai-api` が表示されることを確認
3. ワークフローで使用する際に選択できることを確認

### テストリクエスト

ワークフローで簡単なテストノードを作成：

1. 新しいワークフローを作成
2. 「OpenAI」ノードを追加
3. Credential: `openai-api` を選択
4. Resource: "Text" → Operation: "Message a Model"
5. Model: "gpt-4o-mini" または "gpt-4o"
6. Prompt: "Hello, this is a test"
7. 「Execute Node」をクリック

**期待結果**: AIからのレスポンスが返ってくる

---

## 4. トラブルシューティング

### エラー: "Invalid API Key"

**原因**:
- APIキーが正しくコピーされていない
- APIキーの有効期限が切れている
- OpenAIアカウントの課金設定がされていない

**解決方法**:
1. APIキーを再度コピーして貼り付け
2. OpenAI Platform でAPIキーのステータスを確認
3. 課金設定を確認: https://platform.openai.com/settings/organization/billing

### エラー: "Rate limit exceeded"

**原因**: APIの使用制限を超えた

**解決方法**:
- 少し待ってから再実行
- OpenAI Platform で使用状況を確認
- 必要に応じてプランをアップグレード

### エラー: "Insufficient quota"

**原因**: APIクレジットが不足している

**解決方法**:
1. OpenAI Platform でクレジット残高を確認
2. 課金設定から残高をチャージ

---

## 5. セキュリティのベストプラクティス

### ✅ 推奨

- APIキーは `.env.local` に記載し、Gitにコミットしない
- `.gitignore` に `.env.local` を含める
- APIキーは定期的にローテーション
- 本番環境と開発環境で異なるAPIキーを使用

### ❌ 禁止

- APIキーをソースコードに直接記載しない
- APIキーを公開リポジトリにコミットしない
- APIキーをSlack/メールで共有しない

---

## 6. 使用できるモデル

アメックス明細処理ワークフローで使用されるモデル:

- **PDF解析**: `gpt-4o` または `gpt-4o-mini`（Vision機能必須）
- **AI推論**: `gpt-4o` または `gpt-4o-mini`

### 推奨モデル

| 用途 | 推奨モデル | 理由 |
|------|-----------|------|
| PDF解析（OCR） | `gpt-4o` | Vision機能、高精度 |
| 勘定科目推定 | `gpt-4o-mini` | コスト効率、十分な精度 |

---

## 7. コスト目安

### GPT-4o

- 入力: $2.50 / 1M tokens
- 出力: $10.00 / 1M tokens

### GPT-4o-mini

- 入力: $0.150 / 1M tokens
- 出力: $0.600 / 1M tokens

### 実際のコスト例

**Amex明細1件（5取引）の処理**:
- PDF解析: 約 $0.05
- 勘定科目推定（5回）: 約 $0.01
- **合計**: 約 $0.06 / 明細

**月間30件処理**: 約 $1.80 / 月

---

## 8. 参考リンク

- OpenAI Platform: https://platform.openai.com
- API Keys: https://platform.openai.com/api-keys
- Billing: https://platform.openai.com/settings/organization/billing
- Pricing: https://openai.com/api/pricing/
- n8n OpenAI Integration: https://docs.n8n.io/integrations/builtin/credentials/openai/

---

**更新日**: 2026-01-26
