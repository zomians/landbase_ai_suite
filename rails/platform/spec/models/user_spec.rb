require 'rails_helper'

RSpec.describe User, type: :model do
  describe "Deviseモジュール" do
    it "database_authenticatable が有効であること" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "recoverable が有効であること" do
      expect(User.devise_modules).to include(:recoverable)
    end

    it "rememberable が有効であること" do
      expect(User.devise_modules).to include(:rememberable)
    end

    it "validatable が有効であること" do
      expect(User.devise_modules).to include(:validatable)
    end

    it "registerable が無効であること（公開サインアップ不要）" do
      expect(User.devise_modules).not_to include(:registerable)
    end
  end

  describe "バリデーション" do
    it "有効なユーザーが作成できること" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "メールアドレスがない場合無効であること" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
    end

    it "パスワードがない場合無効であること" do
      user = build(:user, password: "")
      expect(user).not_to be_valid
    end

    it "メールアドレスが重複している場合無効であること" do
      create(:user, email: "dup@example.com")
      user = build(:user, email: "dup@example.com")
      expect(user).not_to be_valid
    end
  end
end
