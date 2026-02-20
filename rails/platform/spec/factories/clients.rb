FactoryBot.define do
  factory :client do
    code { "test_client" }
    name { "テストクライアント" }
    industry { "restaurant" }
    subdomain { nil }
    services { {} }
    status { "active" }

    trait :hotel do
      code { "hotel_client" }
      name { "テストホテル" }
      industry { "hotel" }
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :trial do
      status { "trial" }
    end
  end
end
