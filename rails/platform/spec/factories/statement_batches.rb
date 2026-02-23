FactoryBot.define do
  factory :statement_batch do
    client
    source_type { "amex" }
    status { "processing" }
    summary { {} }

    trait :processing do
      status { "processing" }
    end

    trait :completed do
      status { "completed" }
      summary do
        {
          total_transactions: 5,
          total_amount: 50_000,
          review_required_count: 1,
          accounts_breakdown: { "旅費交通費" => 30_000, "消耗品費" => 20_000 }
        }
      end
    end

    trait :failed do
      status { "failed" }
      error_message { "Anthropic API エラー: API key invalid" }
    end
  end
end
