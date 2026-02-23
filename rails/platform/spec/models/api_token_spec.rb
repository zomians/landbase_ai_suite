require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe "バリデーション" do
    it "有効なトークンが作成できること" do
      token = build(:api_token)
      expect(token).to be_valid
    end

    it "nameがない場合無効であること" do
      token = build(:api_token, name: "")
      expect(token).not_to be_valid
    end

    it "token_digestがない場合無効であること" do
      token = build(:api_token, token_digest: "")
      expect(token).not_to be_valid
    end

    it "token_digestが重複している場合無効であること" do
      create(:api_token, token_digest: "abc123")
      token = build(:api_token, token_digest: "abc123")
      expect(token).not_to be_valid
    end
  end

  describe ".generate!" do
    it "平文トークンとレコードを返すこと" do
      token_record, raw_token = ApiToken.generate!(name: "test")
      expect(token_record).to be_persisted
      expect(raw_token).to be_present
      expect(raw_token.length).to eq(64)
    end

    it "DBにはdigestのみ保存されること" do
      token_record, raw_token = ApiToken.generate!(name: "test")
      expect(token_record.token_digest).not_to eq(raw_token)
      expect(token_record.token_digest.length).to eq(64)
    end

    it "expires_atを指定できること" do
      expires = 30.days.from_now
      token_record, = ApiToken.generate!(name: "test", expires_at: expires)
      expect(token_record.expires_at).to be_within(1.second).of(expires)
    end
  end

  describe ".find_by_raw_token" do
    it "平文トークンからレコードを検索できること" do
      token_record, raw_token = ApiToken.generate!(name: "test")
      found = ApiToken.find_by_raw_token(raw_token)
      expect(found).to eq(token_record)
    end

    it "存在しないトークンの場合nilを返すこと" do
      expect(ApiToken.find_by_raw_token("invalid_token")).to be_nil
    end

    it "nilの場合nilを返すこと" do
      expect(ApiToken.find_by_raw_token(nil)).to be_nil
    end

    it "空文字の場合nilを返すこと" do
      expect(ApiToken.find_by_raw_token("")).to be_nil
    end
  end

  describe "#expired?" do
    it "expires_atが未来の場合falseを返すこと" do
      token = build(:api_token, expires_at: 1.day.from_now)
      expect(token.expired?).to be false
    end

    it "expires_atが過去の場合trueを返すこと" do
      token = build(:api_token, :expired)
      expect(token.expired?).to be true
    end

    it "expires_atがnilの場合falseを返すこと（無期限）" do
      token = build(:api_token, expires_at: nil)
      expect(token.expired?).to be false
    end
  end

  describe "#active?" do
    it "有効なトークンはtrueを返すこと" do
      token = build(:api_token, expires_at: nil)
      expect(token.active?).to be true
    end

    it "期限切れトークンはfalseを返すこと" do
      token = build(:api_token, :expired)
      expect(token.active?).to be false
    end
  end

  describe "#touch_last_used!" do
    it "last_used_atが更新されること" do
      token = create(:api_token)
      expect { token.touch_last_used! }.to change { token.reload.last_used_at }
    end
  end
end
