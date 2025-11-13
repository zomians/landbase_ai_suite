# LandBase AI Suite Development Lifecycle Automation
# Mattermost + n8n + Rails 8 + Next.js 15 + Flutter 3 + PostgreSQL

include .env
export

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m # No Color

# Docker Compose command
DC := docker compose -f compose.development.yaml --env-file .env

.PHONY: help
help: ## ヘルプ表示
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| cut -d: -f2- \
		| awk 'BEGIN {FS = ":.*?## "}; {printf " ${GREEN}%-15s${NC} %s\n", $$1, $$2}'

.PHONY: up
up: ## Mattermost, n8n, PostgreSQLを起動
	@echo "${GREEN}Starting Mattermost, n8n and PostgreSQL...${NC}"
	$(DC) up -d postgres mattermost n8n
	@echo "${GREEN}Mattermost is running at http://localhost:${MATTERMOST_PORT}${NC}"
	@echo "${GREEN}n8n is running at http://localhost:${N8N_PORT}${NC}"
	@echo "${YELLOW}n8n Login: ${N8N_BASIC_AUTH_USER} / ${N8N_BASIC_AUTH_PASSWORD}${NC}"

.PHONY: down
down: ## サービス停止
	$(DC) down

.PHONY: logs
logs: ## 全サービスのログ表示
	$(DC) logs --follow

.PHONY: n8n-logs
n8n-logs: ## n8nログ表示
	$(DC) logs -f n8n

.PHONY: postgres-logs
postgres-logs: ## PostgreSQLログ表示
	$(DC) logs -f postgres

.PHONY: postgres-shell
postgres-shell: ## PostgreSQLシェル接続
	$(DC) exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

.PHONY: mattermost-logs
mattermost-logs: ## Mattermostログ表示
	$(DC) logs -f mattermost

.PHONY: rails-shell
rails-shell: ## Railsコンテナにシェル接続
	$(DC) run --rm --service-ports rails bash

.PHONY: rails-new
rails-new: ## 新規Railsアプリ作成（PostgreSQL対応）
	@echo "${GREEN}Creating new Rails application with PostgreSQL...${NC}"
	@[ -d ${RAILS_APP_NAME} ] && echo "${YELLOW}Rails application '${RAILS_APP_NAME}' already exists.${NC}" || \
		$(DC) run --rm --service-ports rails bash -c " \
			rails new ${RAILS_APP_NAME} \
				--database=postgresql \
				--javascript=esbuild \
				--css=tailwind \
		"

.PHONY: rails-logs
rails-logs: ## Railsログ表示
	$(DC) logs -f rails

.PHONY: nextjs-shell
nextjs-shell: ## Next.jsコンテナにシェル接続
	$(DC) run --rm --service-ports nextjs bash

.PHONY: nextjs-new
nextjs-new: ## 新規Next.jsアプリ作成
	@echo "${GREEN}Creating new Next.js application...${NC}"
	@[ -d ${NEXTJS_APP_NAME} ] && echo "${YELLOW}Next.js application '${NEXTJS_APP_NAME}' already exists.${NC}" || \
		$(DC) run --rm --service-ports nextjs bash -c " \
			cd /app && \
			npx create-next-app@${NEXTJS_VERSION} ${NEXTJS_APP_NAME} \
				--typescript \
				--tailwind \
				--app \
				--src-dir \
				--import-alias '@/*' \
		"

.PHONY: nextjs-logs
nextjs-logs: ## Next.jsログ表示
	$(DC) logs -f nextjs

.PHONY: clean
clean: ## クリーンアップ（全削除）
	$(DC) down --rmi all --volumes --remove-orphans
	@echo "${GREEN}Cleaned up all Docker resources.${NC}"

.PHONY: build
build: ## サービスビルド（キャッシュ無効）
	$(DC) build --no-cache

# ================================
# プラットフォーム初期セットアップ
# ================================

.PHONY: init
init: ## 初回セットアップ（n8n自動構成）
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}🚀 LandBase AI Suite 初回セットアップ${NC}"
	@echo "${GREEN}========================================${NC}"
	@./scripts/setup_n8n_owner.sh
	@echo ""
	@echo "${YELLOW}📋 Mattermost 手動セットアップ:${NC}"
	@echo "  1. ブラウザで http://localhost:${MATTERMOST_PORT} にアクセス"
	@echo "  2. 管理者アカウントを作成してください"
	@echo ""
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}✅ プラットフォームセットアップ完了!${NC}"
	@echo "${GREEN}========================================${NC}"

# ================================
# クライアント管理
# ================================

.PHONY: add-client
add-client: ## クライアント追加とプロビジョニング（例: make add-client CODE=okinawa_hotel_a NAME="沖縄ホテルA" INDUSTRY=hotel EMAIL=info@hotel.com）
	@ruby ./scripts/add_client.rb "$(CODE)" "$(NAME)" "$(INDUSTRY)" "$(EMAIL)"
	@if [ $$? -eq 0 ]; then \
		echo ""; \
		echo "${GREEN}クライアント登録完了。プロビジョニングを開始します...${NC}"; \
		echo ""; \
		./scripts/provision_client.sh $(CODE); \
	fi

.PHONY: list-clients
list-clients: ## クライアント一覧表示
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}📋 登録クライアント一覧${NC}"
	@echo "${GREEN}========================================${NC}"
	@ruby -ryaml -e " \
		data = YAML.load_file('config/client_list.yaml'); \
		if data['clients'].empty?; \
			puts '⚠️  登録されているクライアントはありません'; \
		else; \
			data['clients'].each_with_index do |c, i|; \
				puts ''; \
				puts \"#{i+1}. #{c['code']}\"; \
				puts \"   名前: #{c['name']}\"; \
				puts \"   業種: #{c['industry']}\"; \
				puts \"   状態: #{c['status']}\"; \
				puts \"   Email: #{c['contact']['email']}\"; \
				puts \"   n8n Port: #{c.dig('services', 'n8n', 'port')}\"; \
				puts \"   n8n URL: http://localhost:#{c.dig('services', 'n8n', 'port')}\"; \
			end; \
		end \
	"
	@echo ""

.PHONY: start-client
start-client: ## クライアントコンテナ起動（例: make start-client CODE=okinawa_hotel_a）
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}▶️  クライアントコンテナ起動${NC}"
	@echo "${GREEN}========================================${NC}"
	@if [ ! -f "compose.client.$(CODE).yaml" ]; then \
		echo "${RED}❌ エラー: compose.client.$(CODE).yaml が見つかりません${NC}"; \
		echo "${YELLOW}make add-client でクライアントを追加してください${NC}"; \
		exit 1; \
	fi
	@docker compose -f compose.client.$(CODE).yaml up -d
	@echo ""
	@echo "${GREEN}✅ クライアント '$(CODE)' のコンテナを起動しました${NC}"

.PHONY: stop-client
stop-client: ## クライアントコンテナ停止（例: make stop-client CODE=okinawa_hotel_a）
	@echo "${YELLOW}========================================${NC}"
	@echo "${YELLOW}⏸️  クライアントコンテナ停止${NC}"
	@echo "${YELLOW}========================================${NC}"
	@if [ ! -f "compose.client.$(CODE).yaml" ]; then \
		echo "${RED}❌ エラー: compose.client.$(CODE).yaml が見つかりません${NC}"; \
		exit 1; \
	fi
	@docker compose -f compose.client.$(CODE).yaml down
	@echo ""
	@echo "${GREEN}✅ クライアント '$(CODE)' のコンテナを停止しました${NC}"

.PHONY: client-logs
client-logs: ## クライアントn8nログ表示（例: make client-logs CODE=okinawa_hotel_a）
	@if [ ! -f "compose.client.$(CODE).yaml" ]; then \
		echo "${RED}❌ エラー: compose.client.$(CODE).yaml が見つかりません${NC}"; \
		exit 1; \
	fi
	@docker compose -f compose.client.$(CODE).yaml logs -f n8n

.PHONY: remove-client
remove-client: ## クライアント削除（例: make remove-client CODE=okinawa_hotel_a）
	@echo "${RED}========================================${NC}"
	@echo "${RED}⚠️  クライアント削除${NC}"
	@echo "${RED}========================================${NC}"
	@echo ""
	@ruby -ryaml -e " \
		code = '$(CODE)'; \
		file = 'config/client_list.yaml'; \
		data = YAML.load_file(file); \
		client = data['clients'].find { |c| c['code'] == code }; \
		if client.nil?; \
			puts '❌ クライアント \"#{code}\" が見つかりません'; \
			exit 1; \
		end; \
	"
	@echo "${YELLOW}📦 Step 1/3: Dockerコンテナ停止・削除中...${NC}"
	@if [ -f "compose.client.$(CODE).yaml" ]; then \
		docker compose -f compose.client.$(CODE).yaml down --volumes || true; \
		echo "${GREEN}✅ Dockerコンテナ削除完了${NC}"; \
	else \
		echo "${YELLOW}⚠️  Composeファイルが見つかりません（スキップ）${NC}"; \
	fi
	@echo ""
	@echo "${YELLOW}📦 Step 2/3: Composeファイル削除中...${NC}"
	@if [ -f "compose.client.$(CODE).yaml" ]; then \
		rm compose.client.$(CODE).yaml; \
		echo "${GREEN}✅ Composeファイル削除完了${NC}"; \
	else \
		echo "${YELLOW}⚠️  Composeファイルが見つかりません（スキップ）${NC}"; \
	fi
	@echo ""
	@echo "${YELLOW}📦 Step 3/3: client_list.yamlから削除中...${NC}"
	@ruby -ryaml -e " \
		code = '$(CODE)'; \
		file = 'config/client_list.yaml'; \
		data = YAML.load_file(file); \
		data['clients'].reject! { |c| c['code'] == code }; \
		File.write(file, data.to_yaml); \
		puts \"${GREEN}✅ client_list.yamlから削除完了${NC}\"; \
	"
	@echo ""
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}✅ クライアント '$(CODE)' の削除完了${NC}"
	@echo "${GREEN}========================================${NC}"

# ================================
# LINE Bot 統合
# ================================

.PHONY: ngrok
ngrok: ## ngrokでn8nを公開（LINE Webhook用）
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}🌐 ngrok起動中...${NC}"
	@echo "${GREEN}========================================${NC}"
	@if ! command -v ngrok &> /dev/null; then \
		echo "${RED}❌ ngrokがインストールされていません${NC}"; \
		echo "${YELLOW}インストール方法: brew install ngrok${NC}"; \
		exit 1; \
	fi
	@echo "${YELLOW}n8n (Port ${N8N_PORT}) を公開します...${NC}"
	@echo "${YELLOW}LINE Developers ConsoleでWebhook URLを設定してください:${NC}"
	@echo "${GREEN}  https://<ngrok-url>/webhook/line-webhook${NC}"
	@echo ""
	ngrok http ${N8N_PORT}

.PHONY: line-bot-info
line-bot-info: ## LINE Bot設定情報表示
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}📱 LINE Bot 設定情報${NC}"
	@echo "${GREEN}========================================${NC}"
	@echo ""
	@echo "${YELLOW}LINE Developers Console:${NC}"
	@echo "  https://developers.line.biz/console/"
	@echo ""
	@echo "${YELLOW}必要な設定:${NC}"
	@echo "  1. Channel Secret → .env.local の LINE_CHANNEL_SECRET に設定"
	@echo "  2. Channel Access Token → .env.local の LINE_CHANNEL_ACCESS_TOKEN に設定"
	@echo "  3. Webhook URL → ngrokで取得したURL/webhook/line-webhook"
	@echo "  4. Webhook送信 → ON"
	@echo "  5. グループトーク参加 → ON"
	@echo ""
	@echo "${YELLOW}現在の環境変数:${NC}"
	@if [ "$(LINE_CHANNEL_SECRET)" = "your_line_channel_secret_here" ]; then \
		echo "  LINE_CHANNEL_SECRET: ${RED}未設定${NC}"; \
	else \
		echo "  LINE_CHANNEL_SECRET: ${GREEN}設定済み${NC}"; \
	fi
	@if [ "$(LINE_CHANNEL_ACCESS_TOKEN)" = "your_line_channel_access_token_here" ]; then \
		echo "  LINE_CHANNEL_ACCESS_TOKEN: ${RED}未設定${NC}"; \
	else \
		echo "  LINE_CHANNEL_ACCESS_TOKEN: ${GREEN}設定済み${NC}"; \
	fi
	@echo ""
	@echo "${YELLOW}ワークフロー:${NC}"
	@echo "  n8n/workflows/line-to-gdrive.json"
	@echo ""
	@echo "${GREEN}========================================${NC}"

.PHONY: line-bot-test
line-bot-test: ## LINE Bot Webhook接続テスト
	@echo "${GREEN}LINE Bot Webhook接続テスト${NC}"
	@echo "${YELLOW}n8nのWebhookエンドポイントをテストします...${NC}"
	@curl -X POST http://localhost:${N8N_PORT}/webhook/line-webhook \
		-H "Content-Type: application/json" \
		-d '{"events":[{"type":"message","message":{"type":"text","text":"test"}}]}' \
		&& echo "\n${GREEN}✅ Webhook接続成功${NC}" \
		|| echo "\n${RED}❌ Webhook接続失敗${NC}"
