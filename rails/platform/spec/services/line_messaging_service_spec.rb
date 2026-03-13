require "rails_helper"

RSpec.describe LineMessagingService do
  let(:channel_token) { "test_channel_token" }
  let(:service) { described_class.new }
  let(:http_success) { instance_double(Net::HTTPOK, is_a?: true, code: "200", body: "{}") }
  let(:http_error) { instance_double(Net::HTTPNotFound, is_a?: false, code: "404", body: '{"message":"Not found"}') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("LINE_CHANNEL_TOKEN").and_return(channel_token)
    allow(Net::HTTP).to receive(:start).and_return(http_success)
  end

  describe "#reply" do
    it "Reply APIを呼び出すこと" do
      service.reply("reply_token_001", "テストメッセージ")

      expect(Net::HTTP).to have_received(:start).with(
        "api.line.me", 443, use_ssl: true
      )
    end

    it "レスポンスを返すこと" do
      result = service.reply("reply_token_001", "テストメッセージ")
      expect(result).to eq(http_success)
    end
  end

  describe "#push" do
    it "Push APIを呼び出すこと" do
      service.push("U1234567890", "通知メッセージ")

      expect(Net::HTTP).to have_received(:start).with(
        "api.line.me", 443, use_ssl: true
      )
    end
  end

  describe "#get_content" do
    it "Content APIから画像バイナリを取得すること" do
      image_binary = "\xFF\xD8\xFF\xE0".b
      content_response = instance_double(Net::HTTPOK, is_a?: true, body: image_binary)
      allow(Net::HTTP).to receive(:start)
        .with("api-data.line.me", 443, use_ssl: true)
        .and_return(content_response)

      result = service.get_content("msg_001")

      expect(result.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it "取得失敗時にnilを返すこと" do
      allow(Net::HTTP).to receive(:start)
        .with("api-data.line.me", 443, use_ssl: true)
        .and_return(http_error)

      result = service.get_content("msg_001")

      expect(result).to be_nil
    end
  end

  describe ".reply (クラスメソッド)" do
    it "インスタンスを作成してreplyを呼び出すこと" do
      described_class.reply("token", "text")
      expect(Net::HTTP).to have_received(:start)
    end
  end

  describe ".push (クラスメソッド)" do
    it "インスタンスを作成してpushを呼び出すこと" do
      described_class.push("user_id", "text")
      expect(Net::HTTP).to have_received(:start)
    end
  end
end
