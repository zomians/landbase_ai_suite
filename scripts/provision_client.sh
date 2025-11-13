#!/bin/bash
# scripts/provision_client.sh
# クライアント環境の自動プロビジョニング

set -e

# 色定義
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# 引数チェック
if [ -z "$1" ]; then
  echo -e "${RED}❌ エラー: クライアントコードを指定してください${NC}"
  echo "使用方法: ./provision_client.sh <client_code>"
  exit 1
fi

CLIENT_CODE=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/clients.yml"

# clients.ymlからクライアント情報を取得（Ruby使用）
CLIENT_DATA=$(ruby -ryaml -e "
  data = YAML.load_file('${CONFIG_FILE}')
  client = data['clients'].find { |c| c['code'] == '${CLIENT_CODE}' }
  if client.nil?
    puts 'NOT_FOUND'
  else
    require 'json'
    puts client.to_json
  end
")

if [ "$CLIENT_DATA" = "NOT_FOUND" ]; then
  echo -e "${RED}❌ エラー: クライアント '${CLIENT_CODE}' が見つかりません${NC}"
  echo "make list-clients で確認してください"
  exit 1
fi

# JSON解析
N8N_PORT=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['n8n']['port']")
N8N_EMAIL=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['n8n']['owner_email']")
N8N_PASSWORD=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['n8n']['owner_password']")
N8N_FIRSTNAME=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['name']")
N8N_DB_SCHEMA=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['n8n']['db_schema']")
MM_TEAM_NAME=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['mattermost']['team_name']")
MM_ADMIN_USERNAME=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['mattermost']['admin_username']")
MM_ADMIN_EMAIL=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['mattermost']['admin_email']")
MM_ADMIN_PASSWORD=$(echo $CLIENT_DATA | ruby -rjson -e "puts JSON.parse(STDIN.read)['services']['mattermost']['admin_password']")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 クライアント環境プロビジョニング${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "クライアント: ${YELLOW}${CLIENT_CODE}${NC}"
echo ""

# ================================================
# Step 1: Docker Compose生成
# ================================================
echo -e "${YELLOW}📦 Step 1/3: Docker Compose生成中...${NC}"
ruby ${SCRIPT_DIR}/generate_client_compose.rb ${CLIENT_CODE}

# ================================================
# Step 2: n8nコンテナ起動
# ================================================
echo ""
echo -e "${YELLOW}📦 Step 2/3: n8nコンテナ起動中...${NC}"
docker compose -f ${SCRIPT_DIR}/../compose.client.${CLIENT_CODE}.yaml up -d

# n8nの起動を待つ
echo -e "⏳ n8nの起動を待っています..."
until curl -s http://localhost:${N8N_PORT}/healthz > /dev/null 2>&1; do
  sleep 2
done
echo -e "${GREEN}✅ n8nコンテナ起動完了${NC}"

# ================================================
# Step 3: n8nオーナー作成
# ================================================
echo ""
echo -e "${YELLOW}📦 Step 3/3: n8nオーナー作成中...${NC}"

N8N_SETUP_RESPONSE=$(curl -s -X POST http://localhost:${N8N_PORT}/rest/owner/setup \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${N8N_EMAIL}\",
    \"firstName\": \"${N8N_FIRSTNAME}\",
    \"lastName\": \"Admin\",
    \"password\": \"${N8N_PASSWORD}\"
  }")

if echo "$N8N_SETUP_RESPONSE" | grep -q "email"; then
  echo -e "${GREEN}✅ n8nオーナー作成完了${NC}"
  echo -e "   Email: ${N8N_EMAIL}"
else
  echo -e "${RED}❌ n8nオーナー作成失敗${NC}"
  echo -e "${YELLOW}⚠️  レスポンス: ${N8N_SETUP_RESPONSE}${NC}"
fi

# ================================================
# 完了
# ================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ プロビジョニング完了!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📋 クライアント情報:${NC}"
echo ""
echo -e "${GREEN}n8n（クライアント専用）:${NC}"
echo -e "  URL: http://localhost:${N8N_PORT}"
echo -e "  Email: ${N8N_EMAIL}"
echo -e "  Password: ${N8N_PASSWORD}"
echo -e "  DB Schema: ${N8N_DB_SCHEMA}"
echo ""
echo -e "${GREEN}Mattermost:${NC}"
echo -e "  URL: http://localhost:8065"
echo -e "  ※ ブラウザで手動セットアップしてください"
echo -e "     1. チーム作成: ${MM_TEAM_NAME}"
echo -e "     2. ユーザー招待: ${MM_ADMIN_EMAIL}"
echo ""
