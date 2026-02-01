# Issue #102 実環境テスト チェックリスト

**日付**: 2026-01-26
**対象**: Amex明細処理ワークフロー（amex-statement-processor.json）

## 前提条件の確認

### 1. n8n認証情報（Credentials）

以下の認証情報がn8nに登録されているか確認してください：

- [ ] **gsheet-oauth** - Google Sheets OAuth2 API
  - 確認方法: n8n UI → Settings → Credentials → "gsheet-oauth"を検索

- [ ] **gdrive-oauth** - Google Drive OAuth2 API
  - 確認方法: n8n UI → Settings → Credentials → "gdrive-oauth"を検索

- [ ] **openai-api** - OpenAI API
  - 確認方法: n8n UI → Settings → Credentials → "openai-api"を検索

**n8n UIで確認**: http://localhost:5678/credentials

---

### 2. Google Sheetsの準備

- [ ] **Master_User_Config** シートが存在する
  - 列: client_code, drive_folder_id, sheet_id など
  - テスト用の顧客データが1行以上登録されている

- [ ] **勘定科目マスター** シートが存在する（既存システムと共有）
  - 列: merchant_pattern, account_category, confidence_score など

- [ ] **仕訳台帳** シートが存在する（既存システムと共有）
  - 列: 取引No, 取引日, 借方勘定科目, 金額 など

---

### 3. Google Driveの準備

- [ ] テスト用の顧客フォルダが存在する
  - drive_folder_id が Master_User_Config に登録されている

- [ ] テスト用のAmex PDF明細ファイルを準備
  - ファイル名例: `amex_202501_test.pdf`
  - ファイル内容: 実際のAmex明細、または類似のサンプルPDF

---

## テスト実施手順

### Phase 1: 認証情報確認

```bash
# n8n UIを開く
open http://localhost:5678

# 手順:
# 1. 左メニュー → Settings → Credentials
# 2. 以下を検索して存在を確認:
#    - gsheet-oauth
#    - gdrive-oauth
#    - openai-api
```

**結果**:
- [ ] 全ての認証情報が存在する
- [ ] 欠けている場合は設定が必要

---

### Phase 2: ワークフローの確認

```bash
# n8n UIでワークフローを開く
# 1. Workflows → "アメックス明細→仕訳台帳変換" (または amex-statement-processor)
# 2. 各ノードに認証情報が紐付いているか確認
```

**確認するノード**:
- [ ] 「全クライアント取得」→ gsheet-oauth
- [ ] 「未処理PDFリスト取得」→ gdrive-oauth
- [ ] 「PDFダウンロード」→ gdrive-oauth
- [ ] 「AI-PDF解析（GPT-4o）」→ openai-api
- [ ] 「AI勘定科目推論」→ openai-api
- [ ] 「勘定科目マスター取得」→ gsheet-oauth
- [ ] 「仕訳台帳へ記帳」→ gsheet-oauth
- [ ] 「処理済みマーキング」→ gdrive-oauth

---

### Phase 3: テストデータの準備

#### 3-1. Master_User_Configにテストデータを追加

Google Sheetsで以下のような行を追加:

| client_code | client_name | drive_folder_id | sheet_id | status |
|-------------|-------------|-----------------|----------|--------|
| TEST001 | テスト顧客A | 1A2B3C4D5E... | 1X2Y3Z... | active |

#### 3-2. テスト用PDFをGoogle Driveに配置

1. 上記の `drive_folder_id` のフォルダを開く
2. テスト用のAmex PDF明細をアップロード
3. ファイル名に `_processed` が含まれていないことを確認

---

### Phase 4: Issue #102 テストケース実施

#### TC-1: PDF取得テスト ⚠️ 実環境必須

**手順**:
1. Google Driveフォルダに2つのPDFを配置
   - `amex_202501_test.pdf` (未処理)
   - `amex_202412_processed.pdf` (処理済み)
2. n8nで「Execute Workflow」をクリック
3. 実行ログを確認

**期待結果**:
- [ ] 未処理PDFのみが検出される
- [ ] 処理済みPDFはスキップされる

---

#### TC-2: PDF解析テスト ⚠️ 実環境必須

**手順**:
1. サンプルアメックス明細PDFで手動実行
2. 「取引データ展開」ノードの出力を確認

**期待結果**:
- [ ] 全取引が正しく抽出される
- [ ] 各取引に以下が含まれる:
  - transaction_date
  - merchant
  - amount
  - description

---

#### TC-3: 勘定科目推定テスト ⚠️ 実環境必須

**手順**:
1. 以下の支払先を含むPDFを処理:
   - Amazon
   - セブンイレブン
   - 不明な支払先
2. 仕訳台帳シートを確認

**期待結果**:
- [ ] Amazon → 消耗品費（10%）
- [ ] セブンイレブン → 消耗品費（8%）
- [ ] 不明 → Review_Required で記帳

---

#### TC-4: 処理済みマーキングテスト ⚠️ 実環境必須

**手順**:
1. PDFを処理
2. Google Driveでファイル名を確認

**期待結果**:
- [ ] ファイル名に `_processed` が付与される
- [ ] 例: `amex_202501_test.pdf` → `amex_202501_test_processed.pdf`

---

#### TC-5: エラーハンドリングテスト（今回の修正）⚠️ 実環境必須

**手順**:
1. 正常なPDFで処理を実行
2. 実行ログでエラーハンドリングが動作していることを確認

**期待結果**:
- [ ] JSON解析エラーが発生した場合、詳細なエラーメッセージが表示される
- [ ] 取引Noが一意である（同時刻でも重複しない）
- [ ] 全取引完了後にPDFがリネームされる

---

## 実環境テストが困難な場合の代替案

実環境テスト（本番API使用）が難しい場合、以下の確認で完了とすることもできます：

### 既に完了している検証 ✅

- [x] JSON構文チェック
- [x] ワークフロー構造確認
- [x] n8n UIでのノード確認
- [x] try/catchブロック実装確認
- [x] 取引No一意性確認
- [x] Mergeノード追加確認

### 推奨される次のアクション

1. **本番環境で実施する場合**:
   - 実際の顧客データでテスト（慎重に）

2. **別途テスト環境を用意する場合**:
   - テスト用のGoogle Drive/Sheets/OpenAI APIキーを用意

3. **実装レビューのみで進める場合**:
   - 静的検証完了として PR をマージ
   - 実環境テストは運用開始時に実施

---

## 判断

現在の状況を踏まえて、以下のいずれかを選択してください：

- [ ] **Option A**: 実環境でフルテストを実施する（全TC実施）
- [ ] **Option B**: 静的検証完了として PR をマージし、実環境テストは後日実施
- [ ] **Option C**: テスト環境を別途構築してから実施

**推奨**: 実装は完了しているため、**Option B** を推奨します。
