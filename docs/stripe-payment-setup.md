# Stripe決済セットアップガイド

Shrimp Shells ECでStripe決済を有効化する手順

## 前提条件

- Stripeアカウントの作成完了
- テストモードのAPIキーを取得済み
- `.env.local`にStripe APIキーを設定済み

## 1. Stripe APIキーの取得

### 1.1 Stripeアカウント作成

1. [Stripe](https://stripe.com/jp)にアクセス
2. 「今すぐ始める」をクリックしてアカウント作成
3. メールアドレス確認

### 1.2 テストモードAPIキーの取得

1. [Stripe Dashboard](https://dashboard.stripe.com/)にログイン
2. 右上の「テストモード」トグルをONにする
3. 左メニュー「開発者」→「APIキー」をクリック
4. 以下のキーをコピー:
   - **公開可能キー** (pk_test_xxx)
   - **シークレットキー** (sk_test_xxx)

### 1.3 Webhook署名シークレットの取得（オプション）

1. 左メニュー「開発者」→「Webhook」をクリック
2. 「エンドポイントを追加」をクリック
3. エンドポイントURL: `http://localhost:3002/solidus_stripe/webhook`
4. リッスンするイベント: `payment_intent.succeeded`等を選択
5. 作成後、「署名シークレット」(whsec_xxx)をコピー

## 2. 環境変数設定

`.env.local`に以下を追加:

```bash
# Stripe決済設定
SOLIDUS_STRIPE_API_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxx
SOLIDUS_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxxxxxxx
SOLIDUS_STRIPE_WEBHOOK_SIGNING_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxx
```

## 3. サービス再起動

```bash
# Shrimp Shells ECを再起動
docker compose restart shrimpshells-ec

# または全体再起動
make down
make up
```

## 4. 管理画面で決済方法を設定

### 4.1 管理画面にログイン

1. http://localhost:3002/admin にアクセス
2. デフォルト管理者でログイン:
   - Email: `admin@example.com`
   - Password: `test123`

### 4.2 Stripe決済方法を追加

1. 左メニュー「設定」→「決済方法」をクリック
2. 「新しい決済方法」ボタンをクリック
3. 以下を入力:
   - **名前**: `Stripe Credit Card`
   - **タイプ**: `SolidusStripe::PaymentMethod`を選択
   - **プリファレンス**: `solidus_stripe_env_credentials`を選択
   - **表示**: 「ストアフロント」「管理画面」両方にチェック
   - **アクティブ**: チェック
4. 「作成」ボタンをクリック

### 4.3 設定確認

1. 作成した決済方法の編集画面で以下を確認:
   - API Key: `sk_test_xxx`（環境変数から自動設定）
   - Publishable Key: `pk_test_xxx`（環境変数から自動設定）
   - Test Mode: チェック済み
   - Webhook Endpoint Signing Secret: `whsec_xxx`（環境変数から自動設定）

## 5. テスト購入

### 5.1 ストアフロントで商品購入

1. http://localhost:3002 にアクセス
2. 商品をカートに追加
3. チェックアウトに進む
4. 配送先情報を入力
5. 決済方法で「Stripe Credit Card」を選択

### 5.2 Stripeテストカード情報

以下のテストカード番号を使用:

| カード番号           | 結果         | CVC | 有効期限     |
| -------------------- | ------------ | --- | ------------ |
| 4242 4242 4242 4242 | 成功         | 任意 | 将来の日付   |
| 4000 0000 0000 0002 | カード拒否   | 任意 | 将来の日付   |
| 4000 0000 0000 9995 | 残高不足     | 任意 | 将来の日付   |

詳細: [Stripe テストカード](https://stripe.com/docs/testing#cards)

### 5.3 決済確認

1. 決済完了後、注文確認メールが送信される
2. 管理画面「注文」で注文状態を確認
3. Stripe Dashboardで決済を確認

## 6. 本番環境設定

### 6.1 本番モードAPIキーの取得

1. Stripe Dashboardで「テストモード」トグルをOFFにする
2. 「開発者」→「APIキー」で本番キーを取得:
   - 公開可能キー (pk_live_xxx)
   - シークレットキー (sk_live_xxx)

### 6.2 本番環境変数設定

本番環境の`.env`または環境変数に設定:

```bash
SOLIDUS_STRIPE_API_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxx
SOLIDUS_STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxx
SOLIDUS_STRIPE_WEBHOOK_SIGNING_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxx
```

### 6.3 Webhook URLの更新

1. Stripe Dashboard「開発者」→「Webhook」
2. 本番環境のエンドポイントURLを追加:
   - `https://yourdomain.com/solidus_stripe/webhook`
3. 署名シークレットを取得して環境変数に設定

## 7. トラブルシューティング

### 決済方法が表示されない

- 管理画面で決済方法が「アクティブ」かつ「ストアフロント」表示になっているか確認
- 環境変数が正しく設定されているか確認: `docker compose config | grep STRIPE`

### 決済が失敗する

- Stripe Dashboardの「ログ」で詳細なエラーを確認
- テストカード番号を確認
- APIキーが正しく設定されているか確認

### Webhook が動作しない

- Webhook URLが正しく設定されているか確認
- 署名シークレットが正しいか確認
- ローカル開発の場合、ngrokなどでトンネルを使用

## 参考リンク

- [Solidus Stripe 公式ドキュメント](https://github.com/solidusio/solidus_stripe)
- [Stripe API ドキュメント](https://stripe.com/docs/api)
- [Stripe テストモード](https://stripe.com/docs/testing)
