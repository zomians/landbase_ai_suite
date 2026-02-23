require 'rails_helper'

RSpec.describe "Web::CleaningManuals", type: :request do
  let(:user) { create(:user) }
  let(:client) { create(:client, code: "test_client") }

  describe "GET /cleaning_manuals" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get cleaning_manuals_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get cleaning_manuals_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /cleaning_manuals/new" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get new_cleaning_manual_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get new_cleaning_manual_path
        expect(response).to have_http_status(:ok)
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

      it "200を返すこと" do
        get cleaning_manual_path(manual, client_code: client.code)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
