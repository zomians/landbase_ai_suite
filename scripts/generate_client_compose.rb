#!/usr/bin/env ruby
# scripts/generate_client_compose.rb
# クライアント専用Docker Composeファイル生成

require 'yaml'

# 引数チェック
if ARGV.length < 1
  puts "使用方法: ruby generate_client_compose.rb <client_code>"
  exit 1
end

client_code = ARGV[0]

# clients.yml読み込み
clients_file = File.join(__dir__, '../config/clients.yml')
unless File.exist?(clients_file)
  puts "❌ エラー: config/clients.yml が見つかりません"
  exit 1
end

clients_data = YAML.load_file(clients_file)
client = clients_data['clients'].find { |c| c['code'] == client_code }

if client.nil?
  puts "❌ エラー: クライアント '#{client_code}' が見つかりません"
  exit 1
end

# n8nポート番号取得
n8n_port = client['services']['n8n']['port']
n8n_db_schema = "n8n_#{client_code}"

# Docker Compose YAML生成
compose_data = {
  'name' => 'landbase_ai_suite_development',
  'services' => {
    "n8n-#{client_code.gsub('_', '-')}" => {
      'image' => "n8nio/n8n:latest",
      'container_name' => "n8n_#{client_code}",
      'environment' => [
        'DB_TYPE=postgresdb',
        'DB_POSTGRESDB_HOST=postgres',
        'DB_POSTGRESDB_PORT=5432',
        "DB_POSTGRESDB_DATABASE=landbase_development",
        "DB_POSTGRESDB_SCHEMA=#{n8n_db_schema}",
        'DB_POSTGRESDB_USER=landbase',
        'DB_POSTGRESDB_PASSWORD=landbase_dev_password'
      ],
      'ports' => ["#{n8n_port}:5678"],
      'volumes' => ["n8n_data_#{client_code}:/home/node/.n8n"],
      'networks' => ['landbase_ai_suite_development_default'],
      'restart' => 'unless-stopped'
    }
  },
  'volumes' => {
    "n8n_data_#{client_code}" => {
      'driver' => 'local'
    }
  },
  'networks' => {
    'landbase_ai_suite_development_default' => {
      'external' => true
    }
  }
}

# ファイル出力
output_file = File.join(__dir__, "../compose.client.#{client_code}.yaml")
File.write(output_file, compose_data.to_yaml)

puts "✅ クライアント専用Docker Composeファイル生成完了"
puts "   ファイル: compose.client.#{client_code}.yaml"
puts "   n8n Port: #{n8n_port}"
puts "   DB Schema: #{n8n_db_schema}"
