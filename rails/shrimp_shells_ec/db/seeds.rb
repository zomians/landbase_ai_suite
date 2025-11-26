# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Spree::Core::Engine.load_seed
Spree::Auth::Engine.load_seed

# カスタムシードデータの読み込み
puts "\n=== Loading custom seed data ==="

seed_files = [
  'products.rb',
  'stock_items.rb',
  'orders.rb'
]

seed_files.each do |file|
  seed_file = Rails.root.join('db', 'seeds', file)
  if File.exist?(seed_file)
    puts "\nLoading #{file}..."
    load seed_file
  else
    puts "Skipping #{file} (file not found)"
  end
end

puts "\n=== Custom seed data loaded ==="
