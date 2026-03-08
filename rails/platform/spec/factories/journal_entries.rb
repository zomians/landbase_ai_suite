FactoryBot.define do
  factory :journal_entry do
    client
    source_type { "amex" }
    source_period { "2026-01" }
    transaction_no { Faker::Number.between(from: 1, to: 9999) }
    date { Faker::Date.between(from: 1.year.ago, to: Date.current) }
    description { Faker::Lorem.sentence }
    tag { "" }
    memo { "" }
    cardholder { "" }
    status { "ok" }

    transient do
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
    end

    after(:build) do |entry, evaluator|
      entry.journal_entry_lines << build(:journal_entry_line, :debit,
        journal_entry: entry,
        account: evaluator.debit_account,
        sub_account: evaluator.debit_sub_account,
        department: evaluator.debit_department,
        partner: evaluator.debit_partner,
        tax_category: evaluator.debit_tax_category,
        invoice: evaluator.debit_invoice,
        amount: evaluator.debit_amount
      )
      entry.journal_entry_lines << build(:journal_entry_line, :credit,
        journal_entry: entry,
        account: evaluator.credit_account,
        sub_account: evaluator.credit_sub_account,
        department: evaluator.credit_department,
        partner: evaluator.credit_partner,
        tax_category: evaluator.credit_tax_category,
        invoice: evaluator.credit_invoice,
        amount: evaluator.credit_amount
      )
    end

    trait :amex do
      source_type { "amex" }
      cardholder { "山田太郎" }
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
