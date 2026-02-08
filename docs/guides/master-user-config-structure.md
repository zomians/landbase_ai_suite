# Master_User_Config スプレッドシート構造

## 概要

Master_User_Config は、全顧客の設定を一元管理するスプレッドシートです。各顧客は1行で管理され、利用するサービス（領収書処理、Amex明細処理、銀行明細処理）に応じて必要な列を設定します。

## スプレッドシート構造

| 列 | 列名 | 説明 | 必須 | 使用サービス |
|----|------|------|------|------------|
| A | line_user_id | LINE UserID | ○ | 領収書処理 |
| B | customer_name | 顧客名 | ○ | 全サービス |
| C | drive_folder_id | 領収書用Google DriveフォルダID | ○ | 領収書処理 |
| D | sheet_id | 領収書用仕訳台帳スプレッドシートID | ○ | 領収書処理 |
| E | accounting_soft | 会計ソフト名 | - | - |
| F | registration_date | 登録日時 | - | - |
| G | amex_drive_folder_id | Amex明細PNG用Google DriveフォルダID | ○ | Amex明細処理 |
| H | amex_sheet_id | Amex明細用仕訳台帳スプレッドシートID | ○ | Amex明細処理 |
| I | gcp_service_account_json | GCPサービスアカウント認証情報（JSON） | ○ | OCR処理（全サービス） |
| **J** | **bank_drive_folder_id** | **銀行明細PNG用Google DriveフォルダID** | **○** | **銀行明細処理** |
| **K** | **bank_sheet_id** | **銀行明細用仕訳台帳スプレッドシートID** | **○** | **銀行明細処理** |

## 運用パターン

### パターン1: 領収書のみ使用
- C列（drive_folder_id）、D列（sheet_id）を設定
- G列、H列、J列、K列は空欄

### パターン2: Amex明細のみ使用
- G列（amex_drive_folder_id）、H列（amex_sheet_id）を設定
- C列、D列、J列、K列は空欄

### パターン3: 銀行明細のみ使用
- J列（bank_drive_folder_id）、K列（bank_sheet_id）を設定
- C列、D列、G列、H列は空欄

### パターン4: すべて使用（推奨）
- C, D, G, H, J, K列すべてを設定
- 領収書、Amex明細、銀行明細を別々のフォルダ・シートで管理

## 設定例

### 領収書 + Amex明細 + 銀行明細を使用する顧客

| 列 | 値の例 |
|----|--------|
| A | `U1234567890abcdef` |
| B | `顧客A` |
| C | `1A2B3C4D5E6F7G8H9I0J` |
| D | `9I8H7G6F5E4D3C2B1A0` |
| E | `弥生会計` |
| F | `2025-01-01` |
| G | `2B3C4D5E6F7G8H9I0J1K` |
| H | `8H9I0J1K2L3M4N5O6P7Q` |
| I | `{"type":"service_account",...}` |
| **J** | **`3C4D5E6F7G8H9I0J1K2L`** |
| **K** | **`7G8H9I0J1K2L3M4N5O6P`** |

### 銀行明細のみ使用する顧客

| 列 | 値の例 |
|----|--------|
| A | （空欄） |
| B | `顧客B` |
| C | （空欄） |
| D | （空欄） |
| E | `freee` |
| F | `2025-02-01` |
| G | （空欄） |
| H | （空欄） |
| I | `{"type":"service_account",...}` |
| **J** | **`4D5E6F7G8H9I0J1K2L3M`** |
| **K** | **`8H9I0J1K2L3M4N5O6P7Q`** |

## 利点

1. **データ分離**: 領収書、Amex明細、銀行明細を別シートで管理し、混在を防ぐ
2. **柔軟性**: 顧客ごとに運用方法を選択可能
3. **分析容易**: データソース別に集計・分析しやすい
4. **後方互換性**: 既存の領収書処理・Amex明細処理システムは影響を受けない

## 関連ワークフロー

- **領収書処理**: `n8n/workflows/line-image-handler.json`
  - 使用列: A, B, C, D, I
- **Amex明細処理**: `n8n/workflows/amex-statement-processor.json`
  - 使用列: B, G, H, I
- **銀行明細処理**: `n8n/workflows/bank-statement-processor.json`
  - 使用列: B, J, K, I

## 注意事項

- **I列（gcp_service_account_json）**: すべてのOCR処理で共通的に使用されます。Google Cloud Vision APIの認証に必要です。
- **空欄の列**: 使用しないサービスの列は空欄のままにしてください。ワークフローが自動的にフィルタします。
- **フォルダID取得方法**: Google DriveでフォルダのURLを開き、URLの末尾の文字列がフォルダIDです。
  - 例: `https://drive.google.com/drive/folders/1A2B3C4D5E6F7G8H9I0J` → ID: `1A2B3C4D5E6F7G8H9I0J`

---

**最終更新**: 2026-02-08
**バージョン**: 1.0
