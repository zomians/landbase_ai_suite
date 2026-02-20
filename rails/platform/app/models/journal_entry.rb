require "csv"

class JournalEntry < ApplicationRecord
  # === 関連 ===
  belongs_to :client, primary_key: :code, foreign_key: :client_code, optional: true

  # === バリデーション ===
  validates :client_code, presence: true
  validates :date, presence: true
  validates :debit_account, presence: true
  validates :credit_account, presence: true
  validates :debit_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :credit_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :source_type, inclusion: { in: %w[amex bank invoice receipt] }
  validates :status, inclusion: { in: %w[ok review_required] }
  validates :transaction_no, uniqueness: { scope: %i[client_code source_type source_period] }, allow_nil: true
  validate :amounts_must_match

  # === スコープ ===
  scope :for_client, ->(code) { where(client_code: code) }
  scope :by_source, ->(type) { where(source_type: type) }
  scope :review_required, -> { where(status: "review_required") }
  scope :in_period, ->(from, to) { where(date: from..to) }

  # === CSVエクスポート ===
  CSV_HEADERS = %w[
    取引No 取引日 借方勘定科目 借方補助科目 借方部門 借方取引先 借方税区分
    借方インボイス 借方金額(円) 貸方勘定科目 貸方補助科目 貸方部門
    貸方取引先 貸方税区分 貸方インボイス 貸方金額(円) 摘要 タグ メモ カード利用者 ステータス
  ].freeze

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << CSV_HEADERS

      find_each do |entry|
        csv << [
          entry.transaction_no,
          entry.date,
          entry.debit_account,
          entry.debit_sub_account,
          entry.debit_department,
          entry.debit_partner,
          entry.debit_tax_category,
          entry.debit_invoice,
          entry.debit_amount,
          entry.credit_account,
          entry.credit_sub_account,
          entry.credit_department,
          entry.credit_partner,
          entry.credit_tax_category,
          entry.credit_invoice,
          entry.credit_amount,
          entry.description,
          entry.tag,
          entry.memo,
          entry.cardholder,
          entry.status
        ]
      end
    end
  end

  private

  def amounts_must_match
    return if debit_amount.blank? || credit_amount.blank?

    if debit_amount != credit_amount
      errors.add(:credit_amount, "は借方金額と一致する必要があります")
    end
  end
end
