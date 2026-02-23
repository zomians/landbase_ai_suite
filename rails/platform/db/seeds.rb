# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
  end
  puts "管理者ユーザーを作成しました: admin@example.com / password"

  ApiToken.where(name: "development").delete_all
  _token_record, raw_token = ApiToken.generate!(name: "development")
  puts "APIトークンを作成しました: #{raw_token}"
  puts "使用方法: curl -H 'Authorization: Bearer #{raw_token}' http://localhost:3000/api/v1/..."
end
