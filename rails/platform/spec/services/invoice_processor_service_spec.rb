require "rails_helper"

RSpec.describe InvoiceProcessorService do
  let(:client) { create(:client, code: "test_client") }
  let(:pdf_file) do
    path = Rails.root.join("spec/fixtures/files/test_statement.pdf")
    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(path),
      filename: "test_invoice.pdf",
      type: "application/pdf"
    )
  end

  let(:valid_response_json) do
    {
      invoice_date: "2026-02-01",
      vendor_name: "株式会社テックソリューション",
      invoice_number: "INV-2026-0201",
      has_invoice_number: true,
      invoice_registration_number: "T1234567890123",
      generated_at: Time.current.iso8601,
      transactions: [
        {
          transaction_no: 1,
          date: "2026-02-01",
          debit_account: "外注費",
          debit_sub_account: "",
          debit_department: "",
          debit_partner: "株式会社テックソリューション",
          debit_tax_category: "課税仕入10%（インボイス）",
          debit_invoice: "T1234567890123",
          debit_amount: 550000,
          credit_account: "未払金",
          credit_sub_account: "",
          credit_department: "",
          credit_partner: "株式会社テックソリューション",
          credit_tax_category: "",
          credit_invoice: "",
          credit_amount: 550000,
          description: "株式会社テックソリューション システム開発業務委託費 2026年1月分",
          tag: "invoice",
          memo: "請求書番号: INV-2026-0201 / 支払期限: 2026-02-28",
          status: "ok"
        }
      ],
      summary: {
        total_transactions: 1,
        total_amount: 550000,
        review_required_count: 0,
        accounts_breakdown: { "外注費" => 550000 }
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

  let(:mock_pdf_pages) { [ double("Page1") ] }
  let(:mock_combine_pdf) { double("CombinePDF", pages: mock_pdf_pages) }

  before do
    allow(Anthropic::Client).to receive(:new).and_return(mock_client)
    allow(CombinePDF).to receive(:parse).and_return(mock_combine_pdf)
  end

  describe "#call" do
    it "正常にPDFを処理し仕訳データを返すこと" do
      service = described_class.new(pdf: pdf_file, client_code: client.code)

      result = service.call

      expect(result.success?).to be true
      expect(result.data[:invoice_date]).to eq("2026-02-01")
      expect(result.data[:vendor_name]).to eq("株式会社テックソリューション")
      expect(result.data[:has_invoice_number]).to be true
      expect(result.data[:transactions]).to be_an(Array)
      expect(result.data[:transactions].first[:debit_account]).to eq("外注費")
      expect(result.data[:summary][:total_transactions]).to eq(1)
    end

    it "AccountMasterのマッチ情報をプロンプトに含めること" do
      create(:account_master,
        client: client,
        source_type: "invoice",
        merchant_keyword: "特定取引先",
        account_category: "外注費",
        confidence_score: 90
      )

      service = described_class.new(pdf: pdf_file, client_code: client.code)

      messages = mock_client.messages
      expect(messages).to receive(:create).with(
        hash_including(messages: [
          hash_including(content: array_including(
            hash_including(type: "text", text: include("特定取引先"))
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

    context "5ページ以下の場合" do
      let(:mock_pdf_pages) { Array.new(3) { |i| double("Page#{i + 1}") } }

      it "バッチ分割しないこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)
        messages = mock_client.messages

        expect(messages).to receive(:create).once.and_return(mock_response)

        result = service.call
        expect(result.success?).to be true
      end
    end

    context "6ページ以上の場合" do
      let(:mock_pdf_pages) { Array.new(8) { |i| double("Page#{i + 1}") } }

      let(:batch1_response_json) do
        {
          invoice_date: "2026-02-01",
          vendor_name: "株式会社テックソリューション",
          invoice_number: "INV-2026-0201",
          has_invoice_number: true,
          invoice_registration_number: "T1234567890123",
          generated_at: Time.current.iso8601,
          transactions: [
            {
              transaction_no: 1,
              date: "2026-02-01",
              debit_account: "外注費",
              debit_sub_account: "",
              debit_department: "",
              debit_partner: "株式会社テックソリューション",
              debit_tax_category: "課税仕入10%（インボイス）",
              debit_invoice: "T1234567890123",
              debit_amount: 550000,
              credit_account: "未払金",
              credit_sub_account: "",
              credit_department: "",
              credit_partner: "株式会社テックソリューション",
              credit_tax_category: "",
              credit_invoice: "",
              credit_amount: 550000,
              description: "株式会社テックソリューション システム開発費",
              tag: "invoice",
              memo: "",
              status: "ok"
            }
          ],
          summary: {
            total_transactions: 1,
            total_amount: 550000,
            review_required_count: 0,
            accounts_breakdown: { "外注費" => 550000 }
          }
        }.to_json
      end

      let(:batch2_response_json) do
        {
          invoice_date: "2026-02-01",
          vendor_name: "株式会社テックソリューション",
          invoice_number: "INV-2026-0201",
          has_invoice_number: true,
          invoice_registration_number: "T1234567890123",
          generated_at: Time.current.iso8601,
          transactions: [
            {
              transaction_no: 2,
              date: "2026-02-01",
              debit_account: "通信費",
              debit_sub_account: "",
              debit_department: "",
              debit_partner: "株式会社テックソリューション",
              debit_tax_category: "課税仕入10%（インボイス）",
              debit_invoice: "T1234567890123",
              debit_amount: 33000,
              credit_account: "未払金",
              credit_sub_account: "",
              credit_department: "",
              credit_partner: "株式会社テックソリューション",
              credit_tax_category: "",
              credit_invoice: "",
              credit_amount: 33000,
              description: "株式会社テックソリューション サーバー保守費",
              tag: "invoice",
              memo: "",
              status: "review_required"
            }
          ],
          summary: {
            total_transactions: 1,
            total_amount: 33000,
            review_required_count: 1,
            accounts_breakdown: { "通信費" => 33000 }
          }
        }.to_json
      end

      let(:batch1_mock_response) do
        double("Response",
          content: [
            double("Content", type: "text", text: batch1_response_json)
          ]
        )
      end

      let(:batch2_mock_response) do
        double("Response",
          content: [
            double("Content", type: "text", text: batch2_response_json)
          ]
        )
      end

      before do
        batch_pdf = CombinePDF.new
        allow(CombinePDF).to receive(:new).and_return(batch_pdf)
        allow(batch_pdf).to receive(:<<)
        allow(batch_pdf).to receive(:to_pdf).and_return("fake_pdf_binary")

        messages = mock_client.messages
        allow(messages).to receive(:create)
          .and_return(batch1_mock_response, batch2_mock_response)
      end

      it "バッチ分割すること" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)
        messages = mock_client.messages

        # 8ページ → 2バッチ（5ページ + 3ページ）
        expect(messages).to receive(:create).twice
          .and_return(batch1_mock_response, batch2_mock_response)

        result = service.call
        expect(result.success?).to be true
      end

      it "バッチ結果のマージが正しいこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call

        expect(result.success?).to be true
        expect(result.data[:transactions].size).to eq(2)

        # transaction_no が通し連番で振り直されていること
        expect(result.data[:transactions][0][:transaction_no]).to eq(1)
        expect(result.data[:transactions][1][:transaction_no]).to eq(2)

        # summary が再計算されていること
        expect(result.data[:summary][:total_transactions]).to eq(2)
        expect(result.data[:summary][:total_amount]).to eq(583000)
        expect(result.data[:summary][:review_required_count]).to eq(1)
        expect(result.data[:summary][:accounts_breakdown]).to eq(
          "外注費" => 550000,
          "通信費" => 33000
        )

        # invoice固有フィールドは最初のバッチから取得
        expect(result.data[:invoice_date]).to eq("2026-02-01")
        expect(result.data[:vendor_name]).to eq("株式会社テックソリューション")
        expect(result.data[:invoice_number]).to eq("INV-2026-0201")
        expect(result.data[:has_invoice_number]).to be true
        expect(result.data[:invoice_registration_number]).to eq("T1234567890123")

        # generated_at は現在時刻
        expect(result.data[:generated_at]).to be_present
      end
    end

    context "バッチ処理中にAPIエラーが発生した場合" do
      let(:mock_pdf_pages) { Array.new(8) { |i| double("Page#{i + 1}") } }

      before do
        batch_pdf = CombinePDF.new
        allow(CombinePDF).to receive(:new).and_return(batch_pdf)
        allow(batch_pdf).to receive(:<<)
        allow(batch_pdf).to receive(:to_pdf).and_return("fake_pdf_binary")

        messages = mock_client.messages
        allow(messages).to receive(:create).and_raise(
          Anthropic::Errors::APIError.new(
            url: "https://api.anthropic.com/v1/messages",
            status: 500,
            headers: {},
            body: { error: { message: "Internal server error" } },
            request: double("Request"),
            response: double("Response")
          )
        )
      end

      it "エラーResultを返すこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("Anthropic API エラー")
      end
    end

    context "バッチ処理中にmax_tokensで切り詰められた場合" do
      let(:mock_pdf_pages) { Array.new(8) { |i| double("Page#{i + 1}") } }

      let(:max_tokens_response) do
        double("Response",
          stop_reason: "max_tokens",
          content: [
            double("Content", type: "text", text: '{"incomplete": true}')
          ]
        )
      end

      before do
        batch_pdf = CombinePDF.new
        allow(CombinePDF).to receive(:new).and_return(batch_pdf)
        allow(batch_pdf).to receive(:<<)
        allow(batch_pdf).to receive(:to_pdf).and_return("fake_pdf_binary")

        messages = mock_client.messages
        allow(messages).to receive(:create).and_return(max_tokens_response)
      end

      it "バッチ番号付きのエラーメッセージを返すこと" do
        service = described_class.new(pdf: pdf_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("バッチ1/2")
        expect(result.error).to include("max_tokens")
      end
    end
  end
end
