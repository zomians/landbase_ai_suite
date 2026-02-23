class Client < ApplicationRecord
  # === 関連 ===
  has_many :journal_entries, dependent: :restrict_with_error
  has_many :account_masters, dependent: :restrict_with_error
  has_many :cleaning_manuals, dependent: :restrict_with_error
  has_many :statement_batches, dependent: :restrict_with_error

  # === バリデーション ===
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :status, inclusion: { in: %w[active trial inactive] }
  validates :industry, inclusion: { in: %w[restaurant hotel tour] }, allow_nil: true

  # === スコープ ===
  scope :active, -> { where(status: "active") }
end
