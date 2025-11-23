# frozen_string_literal: true

Devise.secret_key = SecureRandom.hex(50).inspect
Devise.setup do |config|
  config.parent_controller = 'StoreDeviseController'
  config.mailer = 'UserMailer'
end
