class JournalEntryLine < ApplicationRecord
  belongs_to :journal_entry

  validates :side, presence: true, inclusion: { in: %w[debit credit] }
  validates :account, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
