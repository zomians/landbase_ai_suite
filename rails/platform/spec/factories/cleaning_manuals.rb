FactoryBot.define do
  factory :cleaning_manual do
    client
    property_name { "テスト施設" }
    room_type { "スタンダード" }
    manual_data do
      {
        property_name: "テスト施設",
        room_type: "スタンダード",
        generated_at: Time.current.iso8601,
        areas: [
          {
            area_name: "寝室",
            reference_images: ["bedroom_01.jpg"],
            cleaning_steps: [
              {
                order: 1,
                task: "ベッドメイキング",
                description: "シーツを交換し、枕を配置する",
                checkpoint: "シーツにしわがないこと",
                estimated_minutes: 10
              }
            ],
            quality_standards: ["ベッドカバーが均一に整えられている"]
          }
        ],
        supplies_needed: ["マイクロファイバークロス", "中性洗剤"],
        total_estimated_minutes: 10
      }
    end
    status { "draft" }

    trait :published do
      status { "published" }
    end

    trait :processing do
      status { "processing" }
      manual_data { {} }
    end

    trait :failed do
      status { "failed" }
      manual_data { {} }
      error_message { "APIエラーが発生しました" }
    end
  end
end
