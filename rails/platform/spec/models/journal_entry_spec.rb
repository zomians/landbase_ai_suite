require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  describe "バリデーション" do
    subject { build(:journal_entry) }

    describe "必須カラム" do
      it "有効なファクトリが正常に動作する" do
        expect(subject).to be_valid
      end

      it "clientが空の場合無効" do
        subject.client = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:client]).to be_present
      end

      it "dateが空の場合無効" do
        subject.date = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:date]).to be_present
      end

      it "debit_accountが空の場合無効" do
        subject.debit_account = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:debit_account]).to be_present
      end

      it "credit_accountが空の場合無効" do
        subject.credit_account = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:credit_account]).to be_present
      end
    end

    describe "金額" do
      it "debit_amountが0の場合有効（調整仕訳対応）" do
        subject.debit_amount = 0
        subject.credit_amount = 0
        expect(subject).to be_valid
      end

      it "debit_amountが負の場合無効" do
        subject.debit_amount = -1
        expect(subject).not_to be_valid
        expect(subject.errors[:debit_amount]).to be_present
      end

      it "credit_amountが負の場合無効" do
        subject.debit_amount = 1000
        subject.credit_amount = -1
        expect(subject).not_to be_valid
        expect(subject.errors[:credit_amount]).to be_present
      end
    end

    describe "source_type" do
      %w[amex bank invoice receipt].each do |valid_type|
        it "#{valid_type}は有効" do
          subject.source_type = valid_type
          expect(subject).to be_valid
        end
      end

      it "無効なsource_typeの場合エラー" do
        subject.source_type = "invalid"
        expect(subject).not_to be_valid
        expect(subject.errors[:source_type]).to be_present
      end
    end

    describe "status" do
      %w[ok review_required].each do |valid_status|
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

    describe "借方貸方一致バリデーション" do
      it "debit_amountとcredit_amountが一致する場合有効" do
        subject.debit_amount = 1000
        subject.credit_amount = 1000
        expect(subject).to be_valid
      end

      it "debit_amountとcredit_amountが不一致の場合無効" do
        subject.debit_amount = 1000
        subject.credit_amount = 2000
        expect(subject).not_to be_valid
        expect(subject.errors[:credit_amount]).to be_present
      end
    end
  end

  describe "スコープ" do
    describe ".for_client" do
      it "指定クライアントの仕訳のみ取得する" do
        client_a = create(:client, code: "client_a")
        client_b = create(:client, code: "client_b")
        entry_a = create(:journal_entry, client: client_a)
        create(:journal_entry, client: client_b)

        result = described_class.for_client("client_a")
        expect(result).to contain_exactly(entry_a)
      end
    end

    describe ".by_source" do
      it "指定source_typeの仕訳のみ取得する" do
        amex_entry = create(:journal_entry, :amex)
        create(:journal_entry, :bank)

        result = described_class.by_source("amex")
        expect(result).to contain_exactly(amex_entry)
      end
    end

    describe ".review_required" do
      it "review_requiredステータスの仕訳のみ取得する" do
        review_entry = create(:journal_entry, :review_required)
        create(:journal_entry, status: "ok")

        result = described_class.review_required
        expect(result).to contain_exactly(review_entry)
      end
    end

    describe ".in_period" do
      it "指定期間内の仕訳のみ取得する" do
        in_range = create(:journal_entry, date: Date.new(2026, 1, 15))
        create(:journal_entry, date: Date.new(2025, 12, 1))

        result = described_class.in_period(Date.new(2026, 1, 1), Date.new(2026, 1, 31))
        expect(result).to contain_exactly(in_range)
      end
    end
  end

  describe ".to_csv" do
    it "CSV形式でエクスポートされる" do
      create(:journal_entry, transaction_no: 1, date: Date.new(2026, 1, 15),
             debit_account: "旅費交通費", credit_account: "未払金",
             debit_amount: 5000, credit_amount: 5000, status: "ok")

      csv_string = described_class.to_csv
      csv = CSV.parse(csv_string, headers: true)

      expect(csv.headers).to eq(JournalEntry::CSV_HEADERS)
      expect(csv.size).to eq(1)
      expect(csv.first["取引No"]).to eq("1")
      expect(csv.first["取引日"]).to eq("2026-01-15")
      expect(csv.first["借方勘定科目"]).to eq("旅費交通費")
      expect(csv.first["貸方勘定科目"]).to eq("未払金")
      expect(csv.first["借方金額(円)"]).to eq("5000")
      expect(csv.first["ステータス"]).to eq("ok")
    end
  end

  describe "マルチテナント分離" do
    it "異なるクライアントのデータが混在しない" do
      client_a = create(:client, code: "client_a")
      client_b = create(:client, code: "client_b")
      create(:journal_entry, client: client_a, debit_amount: 1000, credit_amount: 1000)
      create(:journal_entry, client: client_b, debit_amount: 2000, credit_amount: 2000)

      client_a_entries = described_class.for_client("client_a")
      client_b_entries = described_class.for_client("client_b")

      expect(client_a_entries.count).to eq(1)
      expect(client_b_entries.count).to eq(1)
      expect(client_a_entries.first.debit_amount).to eq(1000)
      expect(client_b_entries.first.debit_amount).to eq(2000)
    end
  end
end
