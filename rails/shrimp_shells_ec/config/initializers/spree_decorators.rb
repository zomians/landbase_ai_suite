# frozen_string_literal: true

# Spree デコレーターの読み込み
Rails.application.config.to_prepare do
  Dir.glob(Rails.root.join('app/models/spree/*_decorator.rb')).each do |file|
    require_dependency file
  end
end
