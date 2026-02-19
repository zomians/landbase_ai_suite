FactoryBot.define do
  factory :journal_entry do
    client_code { "test_client" }
    source_type { "amex" }
    source_period { "2026-01" }
    transaction_no { Faker::Number.between(from: 1, to: 9999) }
    date { Faker::Date.between(from: 1.year.ago, to: Date.current) }
    debit_account { "旅費交通費" }
    debit_sub_account { "" }
    debit_department { "" }
    debit_partner { Faker::Company.name }
    debit_tax_category { "課税仕入10%" }
    debit_invoice { "" }
    debit_amount { Faker::Number.between(from: 100, to: 100_000) }
    credit_account { "未払金" }
    credit_sub_account { "" }
    credit_department { "" }
    credit_partner { "" }
    credit_tax_category { "" }
    credit_invoice { "" }
    credit_amount { debit_amount }
    description { Faker::Lorem.sentence }
    tag { "" }
    memo { "" }
    status { "ok" }

    trait :amex do
      source_type { "amex" }
    end

    trait :bank do
      source_type { "bank" }
      debit_account { "水道光熱費" }
      credit_account { "普通預金" }
    end

    trait :invoice do
      source_type { "invoice" }
      debit_account { "仕入高" }
      credit_account { "買掛金" }
    end

    trait :receipt do
      source_type { "receipt" }
      debit_account { "消耗品費" }
      credit_account { "現金" }
    end

    trait :review_required do
      status { "review_required" }
    end
  end
end
