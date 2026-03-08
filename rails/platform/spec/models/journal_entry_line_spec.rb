require "rails_helper"

RSpec.describe JournalEntryLine, type: :model do
  describe "バリデーション" do
    subject { build(:journal_entry_line) }

    it "有効なファクトリが正常に動作する" do
      expect(subject).to be_valid
    end

    it "sideが空の場合無効" do
      subject.side = nil
      expect(subject).not_to be_valid
    end

    it "sideがdebitの場合有効" do
      subject.side = "debit"
      expect(subject).to be_valid
    end

    it "sideがcreditの場合有効" do
      subject.side = "credit"
      expect(subject).to be_valid
    end

    it "sideが無効な値の場合無効" do
      subject.side = "invalid"
      expect(subject).not_to be_valid
    end

    it "accountが空の場合無効" do
      subject.account = nil
      expect(subject).not_to be_valid
    end

    it "amountが負の場合無効" do
      subject.amount = -1
      expect(subject).not_to be_valid
    end

    it "amountが0の場合有効" do
      subject.amount = 0
      expect(subject).to be_valid
    end
  end

  describe "関連" do
    it "journal_entryに属する" do
      line = build(:journal_entry_line)
      expect(line.journal_entry).to be_present
    end
  end
end
