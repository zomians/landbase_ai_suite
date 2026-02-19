class AccountMaster < ApplicationRecord
  # === バリデーション ===
  validates :client_code, presence: true
  validates :account_category, presence: true
  validates :confidence_score, numericality: { in: 0..100 }, allow_nil: true

  # === スコープ ===
  scope :for_client, ->(code) { where(client_code: code) }

  # === キーワードマッチング（merchant_keyword） ===
  def self.find_by_merchant(keyword, client_code:)
    search_by_merchant(keyword, client_code: client_code).first
  end

  def self.search_by_merchant(keyword, client_code:)
    for_client(client_code)
      .where("merchant_keyword ILIKE ?", "%#{keyword}%")
      .order(confidence_score: :desc)
  end

  # === キーワードマッチング（description_keyword） ===
  def self.find_by_description(keyword, client_code:)
    search_by_description(keyword, client_code: client_code).first
  end

  def self.search_by_description(keyword, client_code:)
    for_client(client_code)
      .where("description_keyword ILIKE ?", "%#{keyword}%")
      .order(confidence_score: :desc)
  end
end
