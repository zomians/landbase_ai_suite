# Google Cloud Vision API セットアップガイド

## 📋 目次

- [概要](#概要)
- [前提条件](#前提条件)
- [セットアップ手順](#セットアップ手順)
- [Master_User_Configへの設定](#master_user_configへの設定)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

Amex明細ワークフローでは、Google Cloud Vision APIを使用して明細画像からテキストを抽出します。このガイドでは、Vision APIの有効化とサービスアカウントの作成方法を説明します。

---

## 前提条件

- Googleアカウント
- クレジットカード（GCPの無料枠を使用する場合でも必要）

---

## セットアップ手順

### 1. Google Cloud Projectの作成

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. 画面上部の「プロジェクトを選択」をクリック
3. 「新しいプロジェクト」をクリック
4. プロジェクト名を入力（例: `landbase-ai-suite`）
5. 「作成」をクリック

### 2. Vision APIの有効化

1. Google Cloud Consoleの左メニューから「APIとサービス」→「ライブラリ」を選択
2. 検索ボックスに「Vision API」と入力
3. 「Cloud Vision API」をクリック
4. 「有効にする」ボタンをクリック
5. 数秒待つとAPIが有効化されます

### 3. サービスアカウントの作成

1. 左メニューから「APIとサービス」→「認証情報」を選択
2. 画面上部の「認証情報を作成」→「サービス アカウント」をクリック
3. サービスアカウント名を入力（例: `n8n-vision-api`）
4. 「作成して続行」をクリック
5. ロール選択：
   - 「ロールを選択」をクリック
   - 「Cloud Vision」→「Cloud Vision API ユーザー」を選択
   - 「続行」をクリック
6. 「完了」をクリック

### 4. サービスアカウントキーの作成

1. 作成したサービスアカウントの行の右側にある「︙」（3点リーダー）をクリック
2. 「鍵を管理」を選択
3. 「鍵を追加」→「新しい鍵を作成」をクリック
4. キーのタイプ：**JSON**を選択
5. 「作成」をクリック
6. JSONファイルが自動的にダウンロードされます

**⚠️ 重要：このJSONファイルは安全に保管してください。公開リポジトリにコミットしないでください。**

ダウンロードされたJSONファイルの内容例：
```json
{
  "type": "service_account",
  "project_id": "landbase-ai-suite",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "n8n-vision-api@landbase-ai-suite.iam.gserviceaccount.com",
  "client_id": "123456789...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

---

## Master_User_Configへの設定

### 1. Google Sheetsを開く

1. Master_User_Configスプレッドシートを開く
2. 右端に新しい列を追加（I列など）
3. ヘッダー行（1行目）に列名を入力：`gcp_service_account_json`

### 2. サービスアカウントJSONを貼り付け

1. ダウンロードしたJSONファイルをテキストエディタ（メモ帳、VSCodeなど）で開く
2. **JSON全体**をコピー（`{` から `}` まで）
3. Master_User_Configシートの該当顧客の行のI列に貼り付け

**例：**

| A | B | C | ... | I (gcp_service_account_json) |
|---|---|---|-----|------------------------------|
| line_user_id | customer_name | ... | ... | {"type":"service_account","project_id":"landbase-ai-suite",...} |
| ... | テストクライアント | ... | ... | {"type":"service_account","project_id":"landbase-ai-suite",...} |

**⚠️ 注意事項：**
- JSON全体を1つのセルに貼り付けてください（改行は保持されます）
- すべての顧客が同じサービスアカウントを共有する場合、同じJSONをコピー＆ペーストしてください
- セルの幅が狭いとJSONが見切れますが、データは保存されているので問題ありません

### 3. 動作確認

1. n8nで「アメックス明細→仕訳台帳変換」ワークフローを開く
2. テスト用の明細画像を1枚Google Driveにアップロード
3. ワークフローを手動実行
4. エラーが出ずに取引データが抽出されれば成功

---

## トラブルシューティング

### エラー: "gcp_service_account_jsonが設定されていません"

**原因：** Master_User_ConfigシートにI列（gcp_service_account_json）がないか、値が空

**解決策：**
1. スプレッドシートを開いてI列を確認
2. ヘッダー行に `gcp_service_account_json` があるか確認
3. 該当顧客の行にJSON全体が貼り付けられているか確認

### エラー: "Vision API エラー: PERMISSION_DENIED"

**原因：** サービスアカウントにVision APIの権限がない

**解決策：**
1. GCPコンソールで「APIとサービス」→「認証情報」を開く
2. サービスアカウントを選択
3. 「権限」タブで「Cloud Vision API ユーザー」ロールが付与されているか確認
4. なければ追加

### エラー: "トークン取得失敗"

**原因：** JSONファイルが壊れているか、不完全

**解決策：**
1. JSONファイルを再ダウンロード
2. `{` から `}` まで**完全に**コピーされているか確認
3. 余分な文字（スペース、改行など）が前後に入っていないか確認

### Vision APIの利用料金について

**無料枠：**
- 月1,000リクエストまで無料
- 1枚の明細画像 = 1リクエスト

**有料プラン：**
- 1,001リクエスト以降：1,000リクエストあたり $1.50

**推定コスト：**
- 月100枚の明細処理 = 100リクエスト = **無料**
- 月2,000枚の明細処理 = 2,000リクエスト = 約 $1.50

詳細は[Vision API料金ページ](https://cloud.google.com/vision/pricing)を参照してください。

---

**関連ドキュメント：**
- [n8n経理自動化ワークフロー セットアップガイド](../guides/n8n-accounting-automation-setup.md)
- [OpenAI API セットアップガイド](./openai-api-setup.md)
