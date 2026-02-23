require 'rails_helper'

RSpec.describe "UserSessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/sign_in" do
    it "ログイン画面を返すこと" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/sign_in" do
    context "正しい認証情報の場合" do
      it "ログインしてルートにリダイレクトすること" do
        post user_session_path, params: {
          user: { email: user.email, password: "password" }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "誤った認証情報の場合" do
      it "ログイン画面に戻ること" do
        post user_session_path, params: {
          user: { email: user.email, password: "wrong" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /users/sign_out" do
    it "ログアウトしてログイン画面にリダイレクトすること" do
      sign_in user
      delete destroy_user_session_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
