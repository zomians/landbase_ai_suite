require "rails_helper"

RSpec.describe "Api::V1::JournalEntries", type: :request do
  let(:client) { create(:client, code: "test_client") }
  let(:client_code) { client.code }

  describe "GET /api/v1/journal_entries" do
    it "client_codeがない場合400を返すこと" do
      get "/api/v1/journal_entries"
      expect(response).to have_http_status(:bad_request)
    end

    it "指定クライアントの仕訳一覧を返すこと" do
      other_client = create(:client, code: "other_client")
      create(:journal_entry, client: client, debit_account: "旅費交通費", debit_amount: 1000, credit_amount: 1000)
      create(:journal_entry, client: other_client, debit_account: "消耗品費", debit_amount: 2000, credit_amount: 2000)

      get "/api/v1/journal_entries", params: { client_code: client_code }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["entries"].length).to eq(1)
      expect(data["entries"].first["debit_account"]).to eq("旅費交通費")
    end

    it "source_typeでフィルタできること" do
      create(:journal_entry, :amex, client: client, debit_amount: 1000, credit_amount: 1000)
      create(:journal_entry, :bank, client: client, debit_amount: 2000, credit_amount: 2000)

      get "/api/v1/journal_entries", params: { client_code: client_code, source_type: "amex" }

      data = JSON.parse(response.body)
      expect(data["entries"].length).to eq(1)
      expect(data["entries"].first["source_type"]).to eq("amex")
    end

    it "review_requiredでフィルタできること" do
      create(:journal_entry, client: client, status: "ok", debit_amount: 1000, credit_amount: 1000)
      create(:journal_entry, :review_required, client: client, debit_amount: 2000, credit_amount: 2000)

      get "/api/v1/journal_entries", params: { client_code: client_code, review_required: "true" }

      data = JSON.parse(response.body)
      expect(data["entries"].length).to eq(1)
      expect(data["entries"].first["status"]).to eq("review_required")
    end

    it "日付範囲でフィルタできること" do
      create(:journal_entry, client: client, date: Date.new(2026, 1, 15), debit_amount: 1000, credit_amount: 1000)
      create(:journal_entry, client: client, date: Date.new(2025, 12, 1), debit_amount: 2000, credit_amount: 2000)

      get "/api/v1/journal_entries", params: {
        client_code: client_code,
        date_from: "2026-01-01",
        date_to: "2026-01-31"
      }

      data = JSON.parse(response.body)
      expect(data["entries"].length).to eq(1)
    end

    it "ページネーションのメタ情報を返すこと" do
      create(:journal_entry, client: client, debit_amount: 1000, credit_amount: 1000)

      get "/api/v1/journal_entries", params: { client_code: client_code }

      data = JSON.parse(response.body)
      expect(data["meta"]["current_page"]).to eq(1)
      expect(data["meta"]["total_pages"]).to eq(1)
      expect(data["meta"]["total_count"]).to eq(1)
    end

    it "per_pageパラメータでページサイズを変更できること" do
      3.times { create(:journal_entry, client: client, debit_amount: 1000, credit_amount: 1000) }

      get "/api/v1/journal_entries", params: { client_code: client_code, per_page: 2 }

      data = JSON.parse(response.body)
      expect(data["entries"].length).to eq(2)
      expect(data["meta"]["current_page"]).to eq(1)
      expect(data["meta"]["total_pages"]).to eq(2)
      expect(data["meta"]["total_count"]).to eq(3)
    end

    it "pageパラメータで指定ページを取得できること" do
      3.times { create(:journal_entry, client: client, debit_amount: 1000, credit_amount: 1000) }

      get "/api/v1/journal_entries", params: { client_code: client_code, per_page: 2, page: 2 }

      data = JSON.parse(response.body)
      expect(data["entries"].length).to eq(1)
      expect(data["meta"]["current_page"]).to eq(2)
    end
  end

  describe "GET /api/v1/journal_entries/:id" do
    it "仕訳詳細を返すこと" do
      entry = create(:journal_entry, client: client, debit_amount: 5000, credit_amount: 5000)

      get "/api/v1/journal_entries/#{entry.id}", params: { client_code: client_code }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["id"]).to eq(entry.id)
      expect(data["debit_amount"]).to eq(5000)
    end

    it "他テナントの仕訳にアクセスできないこと" do
      other_client = create(:client, code: "other_client")
      entry = create(:journal_entry, client: other_client, debit_amount: 1000, credit_amount: 1000)

      get "/api/v1/journal_entries/#{entry.id}", params: { client_code: client_code }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/journal_entries/:id" do
    it "仕訳を更新できること" do
      entry = create(:journal_entry, client: client, debit_account: "消耗品費",
                     debit_amount: 1000, credit_amount: 1000, status: "review_required")

      patch "/api/v1/journal_entries/#{entry.id}", params: {
        client_code: client_code,
        debit_account: "旅費交通費",
        status: "ok"
      }

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["debit_account"]).to eq("旅費交通費")
      expect(data["status"]).to eq("ok")
    end

    it "他テナントの仕訳を更新できないこと" do
      other_client = create(:client, code: "other_client")
      entry = create(:journal_entry, client: other_client, debit_amount: 1000, credit_amount: 1000)

      patch "/api/v1/journal_entries/#{entry.id}", params: {
        client_code: client_code,
        debit_account: "旅費交通費"
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/journal_entries/export" do
    it "CSV形式でエクスポートできること" do
      create(:journal_entry, client: client, transaction_no: 1, date: Date.new(2026, 1, 15),
             debit_account: "旅費交通費", credit_account: "未払金",
             debit_amount: 5000, credit_amount: 5000)

      get "/api/v1/journal_entries/export", params: { client_code: client_code }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")

      csv = CSV.parse(response.body.sub("\uFEFF", ""), headers: true)
      expect(csv.headers).to eq(JournalEntry::CSV_HEADERS)
      expect(csv.size).to eq(1)
    end

    it "source_typeでフィルタしてエクスポートできること" do
      create(:journal_entry, :amex, client: client, debit_amount: 1000, credit_amount: 1000)
      create(:journal_entry, :bank, client: client, debit_amount: 2000, credit_amount: 2000)

      get "/api/v1/journal_entries/export", params: { client_code: client_code, source_type: "amex" }

      csv = CSV.parse(response.body, headers: true)
      expect(csv.size).to eq(1)
    end
  end
end
