require "rails_helper"

RSpec.describe "Api::V1::Authentication", type: :request do
  let(:client) { create(:client, code: "test_client") }
  let(:client_code) { client.code }

  describe "Bearer トークン認証" do
    context "トークンなしの場合" do
      it "401を返すこと" do
        get "/api/v1/journal_entries", params: { client_code: client_code }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
      end
    end

    context "無効なトークンの場合" do
      it "401を返すこと" do
        get "/api/v1/journal_entries",
            params: { client_code: client_code },
            headers: { "Authorization" => "Bearer invalid_token_xyz" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "Bearerプレフィックスがない場合" do
      it "401を返すこと" do
        _, raw_token = ApiToken.generate!(name: "test")
        get "/api/v1/journal_entries",
            params: { client_code: client_code },
            headers: { "Authorization" => raw_token }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "期限切れトークンの場合" do
      it "401を返すこと" do
        token_record, raw_token = ApiToken.generate!(name: "expired", expires_at: 1.day.ago)
        expect(token_record).to be_persisted

        get "/api/v1/journal_entries",
            params: { client_code: client_code },
            headers: { "Authorization" => "Bearer #{raw_token}" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "有効なトークンの場合" do
      it "正常レスポンスを返すこと" do
        _, raw_token = ApiToken.generate!(name: "valid")

        get "/api/v1/journal_entries",
            params: { client_code: client_code },
            headers: { "Authorization" => "Bearer #{raw_token}" }
        expect(response).to have_http_status(:ok)
      end

      it "last_used_at が更新されること" do
        token_record, raw_token = ApiToken.generate!(name: "valid")
        expect(token_record.last_used_at).to be_nil

        get "/api/v1/journal_entries",
            params: { client_code: client_code },
            headers: { "Authorization" => "Bearer #{raw_token}" }

        expect(token_record.reload.last_used_at).to be_present
      end
    end
  end
end
