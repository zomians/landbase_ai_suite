require "rails_helper"

RSpec.describe "Api::V1::CleaningManuals", type: :request do
  let(:client) { create(:client, code: "test_client") }
  let(:client_code) { client.code }
  let(:api_token_record) { create(:api_token) }
  let(:authorization_header) { { "Authorization" => "Bearer #{api_token_record.raw_token}" } }

  describe "GET /api/v1/cleaning_manuals" do
    it "client_code がない場合400を返すこと" do
      get "/api/v1/cleaning_manuals", headers: authorization_header
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to include("client_code")
    end

    it "指定した client_code のマニュアル一覧を返すこと" do
      other_client = create(:client, code: "other_client")
      create(:cleaning_manual, client: client, property_name: "施設A")
      create(:cleaning_manual, client: other_client, property_name: "施設B")

      get "/api/v1/cleaning_manuals", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.length).to eq(1)
      expect(data.first["property_name"]).to eq("施設A")
    end

    it "存在しないクライアントの場合404を返すこと" do
      get "/api/v1/cleaning_manuals", params: { client_code: "nonexistent" }, headers: authorization_header

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/cleaning_manuals/:id" do
    it "マニュアル詳細を返すこと" do
      manual = create(:cleaning_manual, client: client)

      get "/api/v1/cleaning_manuals/#{manual.id}", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["id"]).to eq(manual.id)
      expect(data["property_name"]).to eq(manual.property_name)
      expect(data["manual_data"]).to be_present
    end

    it "他テナントのマニュアルにアクセスできないこと" do
      other_client = create(:client, code: "other_client")
      manual = create(:cleaning_manual, client: other_client)

      get "/api/v1/cleaning_manuals/#{manual.id}", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:not_found)
    end

    it "存在しないIDの場合404を返すこと" do
      get "/api/v1/cleaning_manuals/99999", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/cleaning_manuals/generate" do
    let(:test_image) { fixture_file_upload("test_image.jpg", "image/jpeg") }
    let(:valid_params) do
      {
        client_code: client_code,
        property_name: "テスト施設",
        room_type: "スタンダード",
        images: [test_image]
      }
    end

    before do
      allow(CleaningManualGenerateJob).to receive(:perform_later)
    end

    it "202を返しジョブをエンキューすること" do
      post "/api/v1/cleaning_manuals/generate", params: valid_params, headers: authorization_header

      expect(response).to have_http_status(:accepted)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("processing")
      expect(data["id"]).to be_present
      expect(CleaningManualGenerateJob).to have_received(:perform_later).with(
        anything,
        labels: []
      )
      expect(CleaningManual.count).to eq(1)
      expect(CleaningManual.last.status).to eq("processing")
    end

    it "画像がない場合エラーを返すこと" do
      post "/api/v1/cleaning_manuals/generate", params: {
        client_code: client_code,
        property_name: "テスト施設",
        room_type: "スタンダード"
      }, headers: authorization_header

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("画像")
    end

    it "property_name がない場合エラーを返すこと" do
      post "/api/v1/cleaning_manuals/generate", params: {
        client_code: client_code,
        room_type: "スタンダード",
        images: [test_image]
      }, headers: authorization_header

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("property_name")
    end

    it "room_type がない場合エラーを返すこと" do
      post "/api/v1/cleaning_manuals/generate", params: {
        client_code: client_code,
        property_name: "テスト施設",
        images: [test_image]
      }, headers: authorization_header

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("room_type")
    end
  end

  describe "GET /api/v1/cleaning_manuals/:id/status" do
    it "processing状態のマニュアルのステータスを返すこと" do
      manual = create(:cleaning_manual, :processing, client: client)

      get "/api/v1/cleaning_manuals/#{manual.id}/status", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("processing")
      expect(data).not_to have_key("manual_data")
    end

    it "完了したマニュアルの詳細を返すこと" do
      manual = create(:cleaning_manual, client: client, status: "draft")

      get "/api/v1/cleaning_manuals/#{manual.id}/status", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("draft")
      expect(data["manual_data"]).to be_present
    end

    it "失敗したマニュアルのエラーメッセージを返すこと" do
      manual = create(:cleaning_manual, :failed, client: client)

      get "/api/v1/cleaning_manuals/#{manual.id}/status", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("failed")
      expect(data["error_message"]).to be_present
    end

    it "他テナントのマニュアルにアクセスできないこと" do
      other_client = create(:client, code: "other_client")
      manual = create(:cleaning_manual, client: other_client)

      get "/api/v1/cleaning_manuals/#{manual.id}/status", params: { client_code: client_code }, headers: authorization_header

      expect(response).to have_http_status(:not_found)
    end
  end
end
