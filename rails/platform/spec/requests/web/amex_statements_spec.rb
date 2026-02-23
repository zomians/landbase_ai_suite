require 'rails_helper'

RSpec.describe "Web::AmexStatements", type: :request do
  let(:user) { create(:user) }

  describe "GET /amex_statements/new" do
    context "未認証の場合" do
      it "ログイン画面にリダイレクトすること" do
        get new_amex_statement_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "認証済みの場合" do
      before { sign_in user }

      it "200を返すこと" do
        get new_amex_statement_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
