require 'rails_helper'

RSpec.describe "Web::CleaningManuals", type: :request do
  let(:user) { create(:user) }
  let(:client) { create(:client, :hotel, code: "test_client") }

  describe "GET /cleaning_manuals" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get cleaning_manuals_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "hotelクライアントは200を返すこと" do
        get cleaning_manuals_path(client_code: client.code)
        expect(response).to have_http_status(:ok)
      end

      it "非hotelクライアントはリダイレクトすること" do
        restaurant_client = create(:client, code: "restaurant_test", industry: "restaurant")
        get cleaning_manuals_path(client_code: restaurant_client.code)
        expect(response).to redirect_to(client_path(restaurant_client))
      end

      it "クライアント未指定はクライアント一覧にリダイレクトすること" do
        get cleaning_manuals_path
        expect(response).to redirect_to(clients_path)
      end
    end
  end

  describe "GET /cleaning_manuals/new" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get new_cleaning_manual_path(client_code: client.code)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "hotelクライアントは200を返すこと" do
        get new_cleaning_manual_path(client_code: client.code)
        expect(response).to have_http_status(:ok)
      end

      it "非hotelクライアントはリダイレクトすること" do
        restaurant_client = create(:client, code: "restaurant_new", industry: "restaurant")
        get new_cleaning_manual_path(client_code: restaurant_client.code)
        expect(response).to redirect_to(client_path(restaurant_client))
      end
    end
  end

  describe "GET /cleaning_manuals/:id" do
    let(:manual) { create(:cleaning_manual, client: client) }

    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get cleaning_manual_path(manual, client_code: client.code)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "hotelクライアントは200を返すこと" do
        get cleaning_manual_path(manual, client_code: client.code)
        expect(response).to have_http_status(:ok)
      end

      it "非hotelクライアントはリダイレクトすること" do
        restaurant_client = create(:client, code: "restaurant_show", industry: "restaurant")
        get cleaning_manual_path(manual, client_code: restaurant_client.code)
        expect(response).to redirect_to(client_path(restaurant_client))
      end
    end
  end
end
