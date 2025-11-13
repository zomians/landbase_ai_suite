# LandBase AI Suite Development Lifecycle Automation
# Mattermost + n8n + Rails 8 + Next.js 15 + Flutter 3 + PostgreSQL

include .env.development
export

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m # No Color

# Docker Compose command
DC := docker compose -f compose.development.yaml --env-file .env.development

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

.PHONY: n8n-import-workflows
n8n-import-workflows: ## n8nにサンプルワークフローをインポート
	@echo "${GREEN}Importing sample workflows into n8n...${NC}"
	@echo "${YELLOW}Waiting for n8n to be ready...${NC}"
	@until curl -s http://localhost:${N8N_PORT}/healthz > /dev/null 2>&1; do sleep 2; done
	@echo "${GREEN}n8n is ready!${NC}"
	@sleep 3
	@$(DC) exec -T postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < n8n/import-workflows.sql
	@echo "${GREEN}Sample workflows imported successfully!${NC}"

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

.PHONY: setup-platform
setup-platform: ## 初回セットアップ（n8n自動構成）
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
add-client: ## クライアント追加（例: make add-client CODE=okinawa_hotel_a NAME="沖縄ホテルA" INDUSTRY=hotel EMAIL=info@hotel.com）
	@ruby ./scripts/add_client.rb "$(CODE)" "$(NAME)" "$(INDUSTRY)" "$(EMAIL)"

.PHONY: list-clients
list-clients: ## クライアント一覧表示
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}📋 登録クライアント一覧${NC}"
	@echo "${GREEN}========================================${NC}"
	@ruby -ryaml -e " \
		data = YAML.load_file('config/clients.yml'); \
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

.PHONY: provision-client
provision-client: ## クライアント環境プロビジョニング（例: make provision-client CODE=okinawa_hotel_a）
	@./scripts/provision_client.sh $(CODE)

.PHONY: remove-client
remove-client: ## クライアント削除（例: make remove-client CODE=okinawa_hotel_a）
	@echo "${RED}========================================${NC}"
	@echo "${RED}⚠️  クライアント削除${NC}"
	@echo "${RED}========================================${NC}"
	@ruby -ryaml -e " \
		code = '$(CODE)'; \
		file = 'config/clients.yml'; \
		data = YAML.load_file(file); \
		client = data['clients'].find { |c| c['code'] == code }; \
		if client.nil?; \
			puts '❌ クライアント \"#{code}\" が見つかりません'; \
			exit 1; \
		end; \
		data['clients'].reject! { |c| c['code'] == code }; \
		File.write(file, data.to_yaml); \
		puts \"✅ クライアント \\\"#{code}\\\" を削除しました\"; \
	"
