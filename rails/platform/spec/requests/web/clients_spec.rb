require 'rails_helper'

RSpec.describe "Web::Clients", type: :request do
  let(:user) { create(:user) }

  describe "GET /clients (index)" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get clients_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get clients_path
        expect(response).to have_http_status(:ok)
      end

      it "activeとtrialのクライアントが表示されること" do
        active = create(:client, status: "active", name: "アクティブ社")
        trial = create(:client, status: "trial", name: "トライアル社")
        create(:client, status: "inactive", name: "非アクティブ社")

        get clients_path
        expect(response.body).to include("アクティブ社")
        expect(response.body).to include("トライアル社")
        expect(response.body).not_to include("非アクティブ社")
      end

      it "検索でフィルタできること" do
        create(:client, code: "ikigai_stay", name: "イキガイステイ")
        create(:client, code: "oku_resort", name: "奥リゾート")

        get clients_path(query: "ikigai")
        expect(response.body).to include("イキガイステイ")
        expect(response.body).not_to include("奥リゾート")
      end

      it "結果が空の場合メッセージが表示されること" do
        get clients_path(query: "存在しない")
        expect(response.body).to include("クライアントが見つかりません")
      end
    end
  end

  describe "GET /clients/:code (show)" do
    let!(:client) { create(:client, code: "test_client", name: "テスト社") }

    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get client_path(client)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get client_path(client)
        expect(response).to have_http_status(:ok)
      end

      it "クライアント情報が表示されること" do
        get client_path(client)
        expect(response.body).to include("テスト社")
        expect(response.body).to include("test_client")
      end

      it "機能カードのリンクが表示されること" do
        get client_path(client)
        expect(response.body).to include("仕訳台帳")
        expect(response.body).to include("Amex明細処理")
        expect(response.body).to include("銀行明細処理")
        expect(response.body).to include("請求書処理")
        expect(response.body).to include("清掃マニュアル")
      end

      it "存在しないコードの場合リダイレクトすること" do
        get client_path(id: "nonexistent")
        expect(response).to redirect_to(clients_path)
        expect(flash[:alert]).to eq("クライアントが見つかりません")
      end
    end
  end

  describe "GET / (root)" do
    context "認証済みの場合" do
      before { sign_in user }

      it "クライアント一覧が表示されること" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("クライアント一覧")
      end
    end
  end
end
