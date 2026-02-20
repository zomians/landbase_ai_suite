require "rails_helper"
require "ostruct"

RSpec.describe "Api::V1::CleaningManuals", type: :request do
  let(:client) { create(:client, code: "test_client") }
  let(:client_code) { client.code }

  describe "GET /api/v1/cleaning_manuals" do
    it "client_code がない場合400を返すこと" do
      get "/api/v1/cleaning_manuals"
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to include("client_code")
    end

    it "指定した client_code のマニュアル一覧を返すこと" do
      other_client = create(:client, code: "other_client")
      create(:cleaning_manual, client: client, property_name: "施設A")
      create(:cleaning_manual, client: other_client, property_name: "施設B")

      get "/api/v1/cleaning_manuals", params: { client_code: client_code }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.length).to eq(1)
      expect(data.first["property_name"]).to eq("施設A")
    end

    it "存在しないクライアントの場合404を返すこと" do
      get "/api/v1/cleaning_manuals", params: { client_code: "nonexistent" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/cleaning_manuals/:id" do
    it "マニュアル詳細を返すこと" do
      manual = create(:cleaning_manual, client: client)

      get "/api/v1/cleaning_manuals/#{manual.id}", params: { client_code: client_code }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["id"]).to eq(manual.id)
      expect(data["property_name"]).to eq(manual.property_name)
      expect(data["manual_data"]).to be_present
    end

    it "他テナントのマニュアルにアクセスできないこと" do
      other_client = create(:client, code: "other_client")
      manual = create(:cleaning_manual, client: other_client)

      get "/api/v1/cleaning_manuals/#{manual.id}", params: { client_code: client_code }

      expect(response).to have_http_status(:not_found)
    end

    it "存在しないIDの場合404を返すこと" do
      get "/api/v1/cleaning_manuals/99999", params: { client_code: client_code }

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

    let(:mock_result) do
      OpenStruct.new(
        success?: true,
        data: {
          property_name: "テスト施設",
          room_type: "スタンダード",
          generated_at: Time.current.iso8601,
          areas: [
            {
              area_name: "寝室",
              reference_images: ["test_image.jpg"],
              cleaning_steps: [
                {
                  order: 1,
                  task: "ベッドメイキング",
                  description: "シーツを交換する",
                  checkpoint: "しわがないこと",
                  estimated_minutes: 10
                }
              ],
              quality_standards: ["整っている"]
            }
          ],
          supplies_needed: ["クロス"],
          total_estimated_minutes: 10
        }
      )
    end

    before do
      allow_any_instance_of(CleaningManualGeneratorService).to receive(:call).and_return(mock_result)
    end

    it "マニュアルを生成して保存できること" do
      post "/api/v1/cleaning_manuals/generate", params: valid_params

      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["property_name"]).to eq("テスト施設")
      expect(data["status"]).to eq("draft")
      expect(CleaningManual.count).to eq(1)
    end

    it "画像がない場合エラーを返すこと" do
      post "/api/v1/cleaning_manuals/generate", params: {
        client_code: client_code,
        property_name: "テスト施設",
        room_type: "スタンダード"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("画像")
    end

    it "property_name がない場合エラーを返すこと" do
      post "/api/v1/cleaning_manuals/generate", params: {
        client_code: client_code,
        room_type: "スタンダード",
        images: [test_image]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("property_name")
    end

    it "room_type がない場合エラーを返すこと" do
      post "/api/v1/cleaning_manuals/generate", params: {
        client_code: client_code,
        property_name: "テスト施設",
        images: [test_image]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("room_type")
    end

    context "サービスがエラーを返した場合" do
      let(:mock_result) do
        OpenStruct.new(success?: false, data: {}, error: "API エラーが発生しました")
      end

      it "エラーレスポンスを返すこと" do
        post "/api/v1/cleaning_manuals/generate", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("API エラー")
      end
    end
  end
end
