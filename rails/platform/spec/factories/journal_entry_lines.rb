FactoryBot.define do
  factory :journal_entry_line do
    journal_entry
    side { "debit" }
    account { "旅費交通費" }
    sub_account { "" }
    department { "" }
    partner { "" }
    tax_category { "" }
    invoice { "" }
    amount { 1000 }

    trait :debit do
      side { "debit" }
    end

    trait :credit do
      side { "credit" }
    end
  end
end
