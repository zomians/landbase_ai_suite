require "rails_helper"

RSpec.describe AmexStatementProcessorService do
  let(:client) { create(:client, code: "test_client") }
  let(:pdf_file) do
    path = Rails.root.join("spec/fixtures/files/test_statement.pdf")
    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(path),
      filename: "test_statement.pdf",
      type: "application/pdf"
    )
  end

  let(:valid_response_json) do
    {
      statement_period: "2026年1月",
      card_type: "アメリカン・エキスプレス",
      generated_at: Time.current.iso8601,
      transactions: [
        {
          transaction_no: 1,
          date: "2026-01-05",
          debit_account: "消耗品費",
          debit_sub_account: "",
          debit_department: "",
          debit_partner: "Amazon.co.jp",
          debit_tax_category: "課税仕入10%（非インボイス）",
          debit_invoice: "",
          debit_amount: 3280,
          credit_account: "未払金",
          credit_sub_account: "アメックス",
          credit_department: "",
          credit_partner: "",
          credit_tax_category: "",
          credit_invoice: "",
          credit_amount: 3280,
          description: "Amazon.co.jp 事務用品購入",
          tag: "amex",
          memo: "",
          cardholder: "山田太郎",
          status: "ok"
        }
      ],
      summary: {
        total_transactions: 1,
        total_amount: 3280,
        review_required_count: 0,
        accounts_breakdown: { "消耗品費" => 3280 }
      }
    }.to_json
  end

  let(:mock_response) do
    double("Response",
      content: [
        double("Content", type: "text", text: valid_response_json)
      ]
    )
  end

  let(:mock_client) do
    client = double("Anthropic::Client")
    messages = double("Messages")
    allow(client).to receive(:messages).and_return(messages)
    allow(messages).to receive(:create).and_return(mock_response)
    client
  end

  before do
    allow(Anthropic::Client).to receive(:new).and_return(mock_client)
  end

  describe "#call" do
    it "正常にPDFを処理し仕訳データを返すこと" do
      service = described_class.new(pdf: pdf_file, client_code: client.code)

      result = service.call

      expect(result.success?).to be true
      expect(result.data[:statement_period]).to eq("2026年1月")
      expect(result.data[:transactions]).to be_an(Array)
      expect(result.data[:transactions].first[:debit_account]).to eq("消耗品費")
      expect(result.data[:summary][:total_transactions]).to eq(1)
    end

    it "AccountMasterのマッチ情報をプロンプトに含めること" do
      create(:account_master,
        client: client,
        source_type: "amex",
        merchant_keyword: "特定店舗",
        account_category: "接待交際費",
        confidence_score: 90
      )

      service = described_class.new(pdf: pdf_file, client_code: client.code)

      messages = mock_client.messages
      expect(messages).to receive(:create).with(
        hash_including(messages: [
          hash_including(content: array_including(
            hash_including(type: "text", text: include("特定店舗"))
          ))
        ])
      ).and_return(mock_response)

      service.call
    end

    context "JSONがコードブロックで囲まれている場合" do
      let(:mock_response) do
        double("Response",
          content: [
            double("Content", type: "text", text: "```json\n#{valid_response_json}\n```")
          ]
        )
      end

      it "正しくパースできること" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be true
        expect(result.data[:transactions]).to be_present
      end
    end

    context "APIエラーが発生した場合" do
      before do
        messages = double("Messages")
        allow(mock_client).to receive(:messages).and_return(messages)
        allow(messages).to receive(:create).and_raise(
          Anthropic::Errors::AuthenticationError.new(
            url: "https://api.anthropic.com/v1/messages",
            status: 401,
            headers: {},
            body: { error: { message: "API key invalid" } },
            request: double("Request"),
            response: double("Response")
          )
        )
      end

      it "エラーを返すこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("Anthropic API エラー")
      end
    end

    context "不正なJSONが返された場合" do
      let(:mock_response) do
        double("Response",
          content: [
            double("Content", type: "text", text: "invalid json {{{")
          ]
        )
      end

      it "エラーを返すこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("JSON パースエラー")
      end
    end

    context "ANTHROPIC_API_KEYが未設定の場合" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil)
        allow(ENV).to receive(:fetch).and_call_original
      end

      it "エラーを返すこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("ANTHROPIC_API_KEY")
      end
    end
  end
end
