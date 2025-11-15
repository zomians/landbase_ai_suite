#!/bin/bash
# scripts/setup_n8n_owner.sh
# n8n初回オーナー作成（開発環境用）

set -e

# 色定義
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🔧 n8n 初回セットアップ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 環境変数読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.env"

# n8nが起動しているか確認
echo -e "${YELLOW}⏳ n8nの起動を待っています...${NC}"
until curl -s http://localhost:${N8N_PORT}/healthz > /dev/null 2>&1; do
  sleep 2
done

echo -e "${GREEN}✅ n8nが起動しました${NC}"
echo ""

# n8nオーナーセットアップAPI呼び出し
echo -e "${YELLOW}📦 n8nオーナーを作成中...${NC}"

RESPONSE=$(curl -s -X POST http://localhost:${N8N_PORT}/rest/owner/setup \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${N8N_OWNER_EMAIL}\",
    \"firstName\": \"${N8N_OWNER_FIRST_NAME}\",
    \"lastName\": \"${N8N_OWNER_LAST_NAME}\",
    \"password\": \"${N8N_OWNER_PASSWORD}\"
  }")

# レスポンス確認
if echo "$RESPONSE" | grep -q "email"; then
  echo -e "${GREEN}✅ n8nオーナー作成完了${NC}"
  echo ""
  echo -e "${YELLOW}📋 ログイン情報:${NC}"
  echo -e "  URL: http://localhost:${N8N_PORT}"
  echo -e "  Email: ${N8N_OWNER_EMAIL}"
  echo -e "  Password: ${N8N_OWNER_PASSWORD}"
  echo ""
elif echo "$RESPONSE" | grep -q "already"; then
  echo -e "${YELLOW}⚠️  n8nオーナーは既に作成されています${NC}"
  echo ""
  echo -e "${YELLOW}📋 ログイン情報:${NC}"
  echo -e "  URL: http://localhost:${N8N_PORT}"
  echo -e "  Email: ${N8N_OWNER_EMAIL}"
  echo ""
else
  echo -e "${RED}❌ n8nオーナー作成失敗${NC}"
  echo -e "レスポンス: ${RESPONSE}"
  exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ n8nセットアップ完了!${NC}"
echo -e "${GREEN}========================================${NC}"
