class AccountMaster < ApplicationRecord
  # === 関連 ===
  belongs_to :client

  # === バリデーション ===
  validates :account_category, presence: true
  validates :confidence_score, numericality: { in: 0..100 }, allow_nil: true
  validates :source_type, inclusion: { in: %w[amex bank invoice receipt] }, allow_nil: true

  # === スコープ ===
  scope :for_client, ->(code) { where(client: Client.where(code: code)) }
  scope :for_source, ->(type) { where(source_type: [type, nil]) }

  # === キーワードマッチング（merchant_keyword） ===
  def self.find_by_merchant(keyword, client_code:, source_type: nil)
    search_by_merchant(keyword, client_code: client_code, source_type: source_type).first
  end

  def self.search_by_merchant(keyword, client_code:, source_type: nil)
    scope = for_client(client_code)
      .where("merchant_keyword ILIKE ?", "%#{sanitize_sql_like(keyword)}%")
    scope = scope.for_source(source_type) if source_type
    scope.order(confidence_score: :desc)
  end

  # === キーワードマッチング（description_keyword） ===
  def self.find_by_description(keyword, client_code:, source_type: nil)
    search_by_description(keyword, client_code: client_code, source_type: source_type).first
  end

  def self.search_by_description(keyword, client_code:, source_type: nil)
    scope = for_client(client_code)
      .where("description_keyword ILIKE ?", "%#{sanitize_sql_like(keyword)}%")
    scope = scope.for_source(source_type) if source_type
    scope.order(confidence_score: :desc)
  end
end
