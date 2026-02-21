require "rails_helper"

RSpec.describe CleaningManual, type: :model do
  describe "バリデーション" do
    it "有効なファクトリであること" do
      manual = build(:cleaning_manual)
      expect(manual).to be_valid
    end

    it "client が必須であること" do
      manual = build(:cleaning_manual, client: nil)
      expect(manual).not_to be_valid
      expect(manual.errors[:client]).to be_present
    end

    it "property_name が必須であること" do
      manual = build(:cleaning_manual, property_name: nil)
      expect(manual).not_to be_valid
      expect(manual.errors[:property_name]).to be_present
    end

    it "room_type が必須であること" do
      manual = build(:cleaning_manual, room_type: nil)
      expect(manual).not_to be_valid
      expect(manual.errors[:room_type]).to be_present
    end

    it "manual_data が必須であること" do
      manual = build(:cleaning_manual, manual_data: nil)
      expect(manual).not_to be_valid
      expect(manual.errors[:manual_data]).to be_present
    end

    it "status が不正な値の場合バリデーションエラーになること" do
      manual = build(:cleaning_manual, status: "invalid")
      expect(manual).not_to be_valid
      expect(manual.errors[:status]).to be_present
    end

    it "status が draft で有効であること" do
      manual = build(:cleaning_manual, status: "draft")
      expect(manual).to be_valid
    end

    it "status が published で有効であること" do
      manual = build(:cleaning_manual, status: "published")
      expect(manual).to be_valid
    end

    it "status が processing で有効であること" do
      manual = build(:cleaning_manual, status: "processing", manual_data: {})
      expect(manual).to be_valid
    end

    it "status が failed で有効であること" do
      manual = build(:cleaning_manual, status: "failed", manual_data: {})
      expect(manual).to be_valid
    end

    it "status が draft の場合 manual_data が必須であること" do
      manual = build(:cleaning_manual, status: "draft", manual_data: nil)
      expect(manual).not_to be_valid
      expect(manual.errors[:manual_data]).to be_present
    end

    it "status が processing の場合 manual_data が空でも有効であること" do
      manual = build(:cleaning_manual, status: "processing", manual_data: {})
      expect(manual).to be_valid
    end
  end

  describe "スコープ" do
    describe ".for_client" do
      it "指定した client_code のレコードのみ返すこと" do
        client_a = create(:client, code: "client_a")
        client_b = create(:client, code: "client_b")
        manual_a = create(:cleaning_manual, client: client_a)
        _manual_b = create(:cleaning_manual, client: client_b)

        result = CleaningManual.for_client("client_a")
        expect(result).to contain_exactly(manual_a)
      end
    end

    describe ".published" do
      it "公開済みのレコードのみ返すこと" do
        _draft = create(:cleaning_manual, status: "draft")
        published = create(:cleaning_manual, :published)

        result = CleaningManual.published
        expect(result).to contain_exactly(published)
      end
    end

    describe ".recent" do
      it "作成日時の降順で返すこと" do
        old = create(:cleaning_manual, created_at: 1.day.ago)
        new_manual = create(:cleaning_manual, created_at: Time.current)

        result = CleaningManual.recent
        expect(result.first).to eq(new_manual)
        expect(result.last).to eq(old)
      end
    end
  end

  describe "マルチテナント分離" do
    it "異なるクライアントのデータが混在しないこと" do
      client_a = create(:client, code: "tenant_a")
      client_b = create(:client, code: "tenant_b")
      create(:cleaning_manual, client: client_a, property_name: "施設A")
      create(:cleaning_manual, client: client_b, property_name: "施設B")

      tenant_a_manuals = CleaningManual.for_client("tenant_a")
      expect(tenant_a_manuals.pluck(:property_name)).to eq(["施設A"])
    end
  end
end
