require "rails_helper"

RSpec.describe ReceiptProcessorService do
  let(:client) { create(:client, code: "test_client") }
  let(:image_file) do
    path = Rails.root.join("spec/fixtures/files/test_receipt.jpg")
    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(path),
      filename: "test_receipt.jpg",
      type: "image/jpeg"
    )
  end

  let(:valid_response_json) do
    {
      is_receipt: true,
      receipt_date: "2026-03-01",
      vendor_name: "マックスバリュ やんばる店",
      total_amount: 2160,
      tax_amount: 160,
      has_invoice_number: true,
      invoice_registration_number: "T9876543210123",
      transactions: [
        {
          transaction_no: 1,
          date: "2026-03-01",
          debit_account: "仕入高",
          debit_sub_account: "",
          debit_department: "",
          debit_partner: "マックスバリュ やんばる店",
          debit_tax_category: "課税仕入8%（軽減・インボイス）",
          debit_invoice: "T9876543210123",
          debit_amount: 2160,
          credit_account: "現金",
          credit_sub_account: "",
          credit_department: "",
          credit_partner: "",
          credit_tax_category: "",
          credit_invoice: "",
          credit_amount: 2160,
          description: "マックスバリュ やんばる店 食材仕入",
          tag: "receipt",
          memo: "",
          status: "ok"
        }
      ],
      summary: {
        total_transactions: 1,
        total_amount: 2160,
        review_required_count: 0,
        accounts_breakdown: { "仕入高" => 2160 }
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
    it "正常に画像を処理し仕訳データを返すこと" do
      service = described_class.new(image: image_file, client_code: client.code)

      result = service.call

      expect(result.success?).to be true
      expect(result.data[:is_receipt]).to be true
      expect(result.data[:receipt_date]).to eq("2026-03-01")
      expect(result.data[:vendor_name]).to eq("マックスバリュ やんばる店")
      expect(result.data[:total_amount]).to eq(2160)
      expect(result.data[:transactions]).to be_an(Array)
      expect(result.data[:transactions].first[:debit_account]).to eq("仕入高")
      expect(result.data[:transactions].first[:credit_account]).to eq("現金")
      expect(result.data[:summary][:total_transactions]).to eq(1)
    end

    it "AccountMasterのマッチ情報をプロンプトに含めること" do
      create(:account_master,
        client: client,
        source_type: "receipt",
        merchant_keyword: "マックスバリュ",
        account_category: "仕入高",
        confidence_score: 95
      )

      service = described_class.new(image: image_file, client_code: client.code)

      messages = mock_client.messages
      expect(messages).to receive(:create).with(
        hash_including(messages: [
          hash_including(content: array_including(
            hash_including(type: "text", text: include("マックスバリュ"))
          ))
        ])
      ).and_return(mock_response)

      service.call
    end

    it "Claude Vision APIに画像データを送信すること" do
      service = described_class.new(image: image_file, client_code: client.code)

      messages = mock_client.messages
      expect(messages).to receive(:create).with(
        hash_including(messages: [
          hash_including(content: array_including(
            hash_including(type: "image", source: hash_including(type: "base64", media_type: "image/jpeg"))
          ))
        ])
      ).and_return(mock_response)

      service.call
    end

    context "非領収書画像の場合" do
      let(:not_receipt_response_json) do
        { is_receipt: false }.to_json
      end

      let(:mock_response) do
        double("Response",
          content: [
            double("Content", type: "text", text: not_receipt_response_json)
          ]
        )
      end

      it "NonReceiptImageErrorを発生させること" do
        service = described_class.new(image: image_file, client_code: client.code)

        expect { service.call }.to raise_error(NonReceiptImageError, "領収書として認識できません")
      end
    end

    context "非対応画像フォーマットの場合" do
      let(:image_file) do
        # AVI file (RIFF header but not WEBP)
        tempfile = Tempfile.new(["test", ".avi"])
        tempfile.binmode
        tempfile.write("RIFF\x00\x00\x00\x00AVI ")
        tempfile.rewind
        ActionDispatch::Http::UploadedFile.new(
          tempfile: tempfile,
          filename: "test.avi",
          type: "video/avi"
        )
      end

      it "UnsupportedImageFormatErrorを発生させること" do
        service = described_class.new(image: image_file, client_code: client.code)

        expect { service.call }.to raise_error(UnsupportedImageFormatError, "対応していない画像フォーマットです")
      end
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
        service = described_class.new(image: image_file, client_code: client.code)

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
        service = described_class.new(image: image_file, client_code: client.code)

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
        service = described_class.new(image: image_file, client_code: client.code)

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
        service = described_class.new(image: image_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("ANTHROPIC_API_KEY")
      end
    end

    context "max_tokensで切り詰められた場合" do
      let(:mock_response) do
        double("Response",
          stop_reason: "max_tokens",
          content: [
            double("Content", type: "text", text: '{"incomplete": true}')
          ]
        )
      end

      it "エラーを返すこと" do
        service = described_class.new(image: image_file, client_code: client.code)

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to include("max_tokens")
      end
    end
  end
end
