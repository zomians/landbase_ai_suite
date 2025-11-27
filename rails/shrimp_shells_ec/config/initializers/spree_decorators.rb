# frozen_string_literal: true

# Spree デコレーターの読み込み
Rails.application.config.to_prepare do
  # モデルデコレーター
  Dir.glob(Rails.root.join('app/models/spree/*_decorator.rb')).each do |file|
    require_dependency file
  end
  
  # コントローラーデコレーター
  Dir.glob(Rails.root.join('app/controllers/spree/**/*_decorator.rb')).each do |file|
    require_dependency file
  end
end
