#!/usr/bin/env ruby
# scripts/add_client.rb
# クライアント情報をclient_list.yamlに追加

require 'yaml'
require 'securerandom'

# コマンドライン引数チェック
if ARGV.length < 3
  puts "使用方法: ruby add_client.rb CODE NAME INDUSTRY [EMAIL]"
  puts "例: ruby add_client.rb okinawa_hotel_a '沖縄リゾートホテルA' hotel info@hotel-a.com"
  exit 1
end

code = ARGV[0]
name = ARGV[1]
industry = ARGV[2]
email = ARGV[3] || "admin@#{code}.landbase.ai"

# client_list.yaml読み込み
clients_file = File.join(__dir__, '../config/client_list.yaml')
clients_data = if File.exist?(clients_file)
  YAML.load_file(clients_file) || {}
else
  {}
end

clients_data['clients'] ||= []

# 重複チェック
if clients_data['clients'].any? { |c| c['code'] == code }
  puts "❌ エラー: クライアントコード '#{code}' は既に存在します"
  exit 1
end

# パスワード生成
password = SecureRandom.alphanumeric(16)

# n8nポート自動割り当て（5679から開始）
base_port = 5679
used_ports = clients_data['clients'].map { |c| c.dig('services', 'n8n', 'port') }.compact
next_port = base_port
while used_ports.include?(next_port)
  next_port += 1
end

# 新規クライアント情報
new_client = {
  'code' => code,
  'name' => name,
  'industry' => industry,
  'subdomain' => code.gsub('_', '-'),
  'contact' => {
    'email' => email
  },
  'services' => {
    'n8n' => {
      'enabled' => true,
      'port' => next_port,
      'owner_email' => "admin-#{code.gsub('_', '-')}@landbase.ai",
      'owner_password' => password,
      'db_schema' => "n8n_#{code}",
      'workflows' => []
    },
    'mattermost' => {
      'enabled' => true,
      'team_name' => "#{name} Team",
      'admin_username' => "#{code}_admin",
      'admin_email' => email,
      'admin_password' => password
    }
  },
  'status' => 'trial',
  'created_at' => Time.now.to_s
}

# 追加
clients_data['clients'] << new_client

# 保存
File.open(clients_file, 'w') do |f|
  f.write(clients_data.to_yaml)
end

puts "✅ クライアント追加成功!"
puts ""
puts "📋 クライアント情報:"
puts "  コード: #{code}"
puts "  名前: #{name}"
puts "  業種: #{industry}"
puts "  n8n Port: #{next_port}"
puts "  n8n Email: admin-#{code.gsub('_', '-')}@landbase.ai"
puts "  パスワード: #{password}"
puts ""
puts "次のステップ: make provision-client CODE=#{code}"
