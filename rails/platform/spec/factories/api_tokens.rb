FactoryBot.define do
  factory :api_token do
    sequence(:name) { |n| "token_#{n}" }

    transient do
      raw_token { SecureRandom.hex(32) }
    end

    token_digest { OpenSSL::Digest::SHA256.hexdigest(raw_token) }

    after(:create) do |api_token, evaluator|
      api_token.raw_token = evaluator.raw_token
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
