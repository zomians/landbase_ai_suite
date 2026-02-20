class CleaningManual < ApplicationRecord
  has_many_attached :images

  validates :client_code, presence: true
  validates :property_name, presence: true
  validates :room_type, presence: true
  validates :manual_data, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published] }

  scope :for_client, ->(code) { where(client_code: code) }
  scope :published, -> { where(status: "published") }
  scope :recent, -> { order(created_at: :desc) }
end
