require "rails_helper"

RSpec.describe YayoiExportService do
  let(:client) { create(:client) }
  let(:service) { described_class.new }

  let!(:entry1) do
    create(:journal_entry, client: client,
           date: Date.new(2026, 1, 15), transaction_no: 1,
           debit_account: "旅費交通費", debit_sub_account: "", debit_department: "",
           debit_partner: "テスト株式会社", debit_tax_category: "課税仕入10%", debit_invoice: "T1234567890123",
           debit_amount: 10_000, credit_account: "未払金", credit_sub_account: "", credit_department: "",
           credit_partner: "", credit_tax_category: "", credit_invoice: "",
           credit_amount: 10_000, description: "出張旅費", tag: "", memo: "")
  end

  let!(:entry2) do
    create(:journal_entry, client: client,
           date: Date.new(2026, 1, 20), transaction_no: 2,
           debit_account: "消耗品費", debit_sub_account: "", debit_department: "",
           debit_partner: "", debit_tax_category: "課税仕入10%", debit_invoice: "",
           debit_amount: 5_000, credit_account: "現金", credit_sub_account: "", credit_department: "",
           credit_partner: "", credit_tax_category: "", credit_invoice: "",
           credit_amount: 5_000, description: "事務用品", tag: "", memo: "")
  end

  let(:entries) { client.journal_entries.order(date: :asc) }

  describe "#export_single_entry" do
    it "25列のCSVを生成すること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      rows.each do |row|
        expect(row.length).to eq(25)
      end
    end

    it "識別フラグが2000であること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      rows.each do |row|
        expect(row[0]).to eq("2000")
      end
    end

    it "タイプが0であること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      rows.each do |row|
        expect(row[19]).to eq("0")
      end
    end

    it "取引日がYYYY/MM/DD形式であること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      expect(rows[0][1]).to eq("2026/01/15")
      expect(rows[1][1]).to eq("2026/01/20")
    end

    it "金額フィールドが正しいこと" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      expect(rows[0][8]).to eq("10000")
      expect(rows[0][15]).to eq("10000")
    end

    it "ヘッダ行がないこと" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      expect(rows.length).to eq(2)
    end

    it "予備列が空文字であること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      rows.each do |row|
        (20..24).each do |i|
          expect(row[i]).to eq("")
        end
      end
    end
  end

  describe "#export_transfer_slip" do
    it "先頭行の識別フラグが2110であること" do
      csv_data = service.export_transfer_slip(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      expect(rows[0][0]).to eq("2110")
    end

    it "2行目以降の識別フラグが2101であること" do
      csv_data = service.export_transfer_slip(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      expect(rows[1][0]).to eq("2101")
    end

    it "タイプが3であること" do
      csv_data = service.export_transfer_slip(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      rows.each do |row|
        expect(row[19]).to eq("3")
      end
    end

    it "25列のCSVを生成すること" do
      csv_data = service.export_transfer_slip(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      rows.each do |row|
        expect(row.length).to eq(25)
      end
    end
  end

  describe "Shift_JISエンコーディング" do
    it "Shift_JISでエンコードされていること" do
      csv_data = service.export_single_entry(entries)
      expect(csv_data.encoding).to eq(Encoding::Shift_JIS)
    end

    it "日本語が正しくエンコードされること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      expect(decoded).to include("旅費交通費")
      expect(decoded).to include("出張旅費")
    end
  end

  describe "空フィールドの扱い" do
    it "空文字フィールドが空文字のまま出力されること" do
      csv_data = service.export_single_entry(entries)
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      # entry2の借方取引先は空
      expect(rows[1][5]).to eq("")
    end

    it "金額が0の場合0が出力されること" do
      entry = create(:journal_entry, client: client, debit_amount: 0, credit_amount: 0,
                     date: Date.new(2026, 2, 1))
      csv_data = service.export_single_entry(JournalEntry.where(id: entry.id))
      decoded = csv_data.encode("UTF-8", "Shift_JIS")
      rows = CSV.parse(decoded)

      expect(rows[0][8]).to eq("0")
      expect(rows[0][15]).to eq("0")
    end
  end
end
