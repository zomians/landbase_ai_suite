FactoryBot.define do
  factory :account_master do
    client_code { "test_client" }
    merchant_keyword { Faker::Company.name }
    description_keyword { Faker::Lorem.word }
    account_category { "旅費交通費" }
    confidence_score { Faker::Number.between(from: 30, to: 80) }
    last_used_date { nil }
    usage_count { 0 }
    auto_learned { false }
    notes { "" }

    trait :auto_learned do
      auto_learned { true }
    end

    trait :high_confidence do
      confidence_score { 90 }
    end
  end
end
