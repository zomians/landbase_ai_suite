require "rails_helper"

RSpec.describe Client, type: :model do
  describe "バリデーション" do
    subject { build(:client) }

    describe "必須カラム" do
      it "有効なファクトリが正常に動作する" do
        expect(subject).to be_valid
      end

      it "codeが空の場合無効" do
        subject.code = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:code]).to be_present
      end

      it "nameが空の場合無効" do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to be_present
      end
    end

    describe "code" do
      it "重複する場合無効" do
        create(:client, code: "duplicate_code")
        subject.code = "duplicate_code"
        expect(subject).not_to be_valid
        expect(subject.errors[:code]).to be_present
      end
    end

    describe "status" do
      %w[active trial inactive].each do |valid_status|
        it "#{valid_status}は有効" do
          subject.status = valid_status
          expect(subject).to be_valid
        end
      end

      it "無効なstatusの場合エラー" do
        subject.status = "invalid"
        expect(subject).not_to be_valid
        expect(subject.errors[:status]).to be_present
      end
    end

    describe "industry" do
      %w[restaurant hotel tour].each do |valid_industry|
        it "#{valid_industry}は有効" do
          subject.industry = valid_industry
          expect(subject).to be_valid
        end
      end

      it "nilは有効" do
        subject.industry = nil
        expect(subject).to be_valid
      end

      it "無効なindustryの場合エラー" do
        subject.industry = "invalid"
        expect(subject).not_to be_valid
        expect(subject.errors[:industry]).to be_present
      end
    end
  end

  describe "スコープ" do
    describe ".active" do
      it "activeステータスのクライアントのみ取得する" do
        active_client = create(:client, status: "active")
        create(:client, status: "inactive")

        result = described_class.active
        expect(result).to contain_exactly(active_client)
      end
    end
  end

  describe "関連" do
    let!(:client) { create(:client) }

    it "journal_entriesを持てる" do
      entry = create(:journal_entry, client: client)
      expect(client.journal_entries).to contain_exactly(entry)
    end

    it "account_mastersを持てる" do
      master = create(:account_master, client: client)
      expect(client.account_masters).to contain_exactly(master)
    end
  end
end
