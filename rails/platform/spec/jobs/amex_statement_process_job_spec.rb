require "rails_helper"

RSpec.describe AmexStatementProcessJob, type: :job do
  let(:client) { create(:client) }
  let(:batch) { create(:statement_batch, :processing, client: client) }

  let(:mock_result_data) do
    {
      statement_period: "2026年1月",
      card_type: "アメリカン・エキスプレス",
      generated_at: Time.current.iso8601,
      transactions: [
        {
          transaction_no: 1,
          date: "2026-01-05",
          debit_account: "消耗品費",
          debit_sub_account: "",
          debit_department: "",
          debit_partner: "Amazon.co.jp",
          debit_tax_category: "課税仕入10%（非インボイス）",
          debit_invoice: "",
          debit_amount: 3280,
          credit_account: "未払金",
          credit_sub_account: "アメックス",
          credit_department: "",
          credit_partner: "",
          credit_tax_category: "",
          credit_invoice: "",
          credit_amount: 3280,
          description: "Amazon.co.jp 事務用品購入",
          tag: "amex",
          memo: "",
          cardholder: "山田太郎",
          status: "ok"
        }
      ],
      summary: {
        total_transactions: 1,
        total_amount: 3280,
        review_required_count: 0,
        accounts_breakdown: { "消耗品費" => 3280 }
      }
    }
  end

  let(:mock_result) do
    AmexStatementProcessorService::Result.new(
      success: true,
      data: mock_result_data,
      error: nil
    )
  end

  before do
    batch.pdf.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/test_statement.pdf")),
      filename: "test_statement.pdf",
      content_type: "application/pdf"
    )
    allow(AmexStatementProcessorService).to receive(:new).and_return(
      instance_double(AmexStatementProcessorService, call: mock_result)
    )
  end

  it "成功時にステータスをcompletedに更新すること" do
    described_class.perform_now(batch.id)

    batch.reload
    expect(batch.status).to eq("completed")
    expect(batch.summary).to be_present
    expect(batch.error_message).to be_nil
  end

  it "成功時にJournalEntryを作成すること" do
    expect {
      described_class.perform_now(batch.id)
    }.to change(JournalEntry, :count).by(1)

    entry = JournalEntry.last
    expect(entry.client).to eq(client)
    expect(entry.statement_batch).to eq(batch)
    expect(entry.debit_account).to eq("消耗品費")
    expect(entry.debit_amount).to eq(3280)
    expect(entry.credit_amount).to eq(3280)
    expect(entry.cardholder).to eq("山田太郎")
    expect(entry.source_type).to eq("amex")
  end

  context "サービスが失敗した場合" do
    let(:mock_result) do
      AmexStatementProcessorService::Result.new(
        success: false, data: {}, error: "Anthropic API エラー: API key invalid"
      )
    end

    it "ステータスをfailedに更新すること" do
      described_class.perform_now(batch.id)

      batch.reload
      expect(batch.status).to eq("failed")
      expect(batch.error_message).to eq("Anthropic API エラー: API key invalid")
    end

    it "JournalEntryを作成しないこと" do
      expect {
        described_class.perform_now(batch.id)
      }.not_to change(JournalEntry, :count)
    end
  end

  it "レコードが存在しない場合は静かに終了すること" do
    expect {
      described_class.perform_now(-1)
    }.not_to raise_error
  end

  it "既にprocessingでないレコードはスキップすること" do
    batch.update!(status: "completed")

    described_class.perform_now(batch.id)

    expect(AmexStatementProcessorService).not_to have_received(:new)
  end
end
