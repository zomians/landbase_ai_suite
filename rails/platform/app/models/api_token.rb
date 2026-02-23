class ApiToken < ApplicationRecord
  attr_accessor :raw_token

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  # トークン生成（平文トークンを返す。DBにはdigestのみ保存）
  def self.generate!(name:, expires_at: nil)
    raw_token = SecureRandom.hex(32)
    token = create!(
      name: name,
      token_digest: digest(raw_token),
      expires_at: expires_at
    )
    [ token, raw_token ]
  end

  # トークンからレコードを検索
  def self.find_by_raw_token(raw_token)
    return nil if raw_token.blank?

    find_by(token_digest: digest(raw_token))
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def active?
    !expired?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end
  private_class_method :digest
end
