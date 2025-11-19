# LandBase AI Suite Development Lifecycle Automation
# Mattermost + n8n + Rails 8 + Next.js 15 + Flutter 3 + PostgreSQL

include .env
export

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m # No Color

.PHONY: help
help: ## ヘルプ表示
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| cut -d: -f2- \
		| awk 'BEGIN {FS = ":.*?## "}; {printf " ${GREEN}%-15s${NC} %s\n", $$1, $$2}'

.PHONY: up
up: ## Mattermost, n8n, PostgreSQLを起動
	@echo "${GREEN}Starting Mattermost, n8n and PostgreSQL...${NC}"
	docker compose up -d postgres mattermost n8n
	@echo "${GREEN}Mattermost is running at http://localhost:${MATTERMOST_PORT}${NC}"
	@echo "${GREEN}n8n is running at http://localhost:${N8N_PORT}${NC}"
	@echo "${YELLOW}n8n Login: ${N8N_BASIC_AUTH_USER} / ${N8N_BASIC_AUTH_PASSWORD}${NC}"

.PHONY: down
down: ## サービス停止
	docker compose down

.PHONY: logs
logs: ## 全サービスのログ表示
	docker compose logs --follow

.PHONY: n8n-logs
n8n-logs: ## n8nログ表示
	docker compose logs -f n8n

.PHONY: postgres-logs
postgres-logs: ## PostgreSQLログ表示
	docker compose logs -f postgres

.PHONY: postgres-shell
postgres-shell: ## PostgreSQLシェル接続
	docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

.PHONY: mattermost-logs
mattermost-logs: ## Mattermostログ表示
	docker compose logs -f mattermost

.PHONY: shrimpshells-new
shrimpshells-new: ## Shrimp Shells EC: Railsアプリ新規作成
	@[ -d rails/${SHRIMP_SHELLS_APP_NAME} ] && echo "${YELLOW}Rails application 'rails/${SHRIMP_SHELLS_APP_NAME}' already exists.${NC}" || \
		docker compose run --rm -e HOME=/tmp -e XDG_CACHE_HOME=/tmp shrimpshells-ec bash -lc " \
			/usr/local/bundle/bin/rails new /$$SHRIMP_SHELLS_APP_NAME \
			  --database=postgresql \
			  --javascript=esbuild \
			  --css=tailwind \
			  --skip-docker \
		"

.PHONY: rails-solidus-install
rails-solidus-install: ## RailsアプリにSolidus導入（Gem追加とインストール）
	docker compose run --rm shrimpshells-ec bash -lc " \
		cd /$$SHRIMP_SHELLS_APP_NAME && \
		bundle add solidus -v '~> 4.5' solidus_auth_devise solidus_support && \
		bundle install && \
		bin/rails g solidus:install || bin/rails g spree:install && \
		bin/rails db:prepare && \
		bin/rails db:seed \
	"

.PHONY: shrimpshells-up
shrimpshells-up: ## Shrimp Shells EC: サービス起動
	docker compose up -d shrimpshells-ec
	@echo "${GREEN}Shrimp Shells EC is running at http://localhost:${SHRIMP_SHELLS_PORT}${NC}"

.PHONY: shrimpshells-logs
shrimpshells-logs: ## Shrimp Shells EC: ログ表示
	docker compose logs -f shrimpshells-ec

.PHONY: shrimpshells-shell
shrimpshells-shell: ## Shrimp Shells EC: コンテナにシェル接続
	docker compose run --rm --service-ports shrimpshells-ec bash

.PHONY: clean
clean: ## クリーンアップ（コンテナ・ボリューム・プロジェクトイメージ削除）
	docker compose down --rmi local --volumes --remove-orphans
	@echo "${GREEN}Cleaned up Docker resources.${NC}"

.PHONY: build
build: ## サービスビルド（キャッシュ無効）
	docker compose build --no-cache

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

.PHONY: ngrok-stop
ngrok-stop: ## ngrokを停止
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}🛑 ngrok停止中...${NC}"
	@echo "${GREEN}========================================${NC}"
	@if pgrep -f "ngrok http" > /dev/null; then \
		pkill -f "ngrok http"; \
		sleep 1; \
		if pgrep -f "ngrok http" > /dev/null; then \
			echo "${RED}❌ ngrokの停止に失敗しました${NC}"; \
			exit 1; \
		else \
			echo "${GREEN}✅ ngrokを停止しました${NC}"; \
		fi \
	else \
		echo "${YELLOW}⚠️  ngrokは起動していません${NC}"; \
	fi
	@echo ""

.PHONY: ngrok-restart
ngrok-restart: ## ngrokを再起動
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}🔄 ngrok再起動中...${NC}"
	@echo "${GREEN}========================================${NC}"
	@$(MAKE) ngrok-stop
	@sleep 1
	@echo "${YELLOW}ngrokを起動します...${NC}"
	@echo ""
	@$(MAKE) ngrok

.PHONY: ngrok-status
ngrok-status: ## ngrokの状態確認
	@echo "${GREEN}========================================${NC}"
	@echo "${GREEN}📊 ngrok状態${NC}"
	@echo "${GREEN}========================================${NC}"
	@if pgrep -f "ngrok http" > /dev/null; then \
		echo "${GREEN}✅ ngrok: 起動中${NC}"; \
		echo ""; \
		echo "${YELLOW}プロセス情報:${NC}"; \
		ps aux | grep "ngrok http" | grep -v grep | awk '{print "  PID: " $$2 " | CPU: " $$3 "% | MEM: " $$4 "% | START: " $$9}'; \
		echo ""; \
		if command -v curl &> /dev/null && curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then \
			echo "${YELLOW}Tunnel情報:${NC}"; \
			curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data = json.load(sys.stdin); [print(f\"  Public URL: {t['public_url']}\") for t in data.get('tunnels', [])]" 2>/dev/null || echo "  情報取得失敗"; \
			echo ""; \
			echo "${YELLOW}Web UI:${NC} http://localhost:4040"; \
		fi; \
	else \
		echo "${RED}❌ ngrok: 停止中${NC}"; \
	fi
	@echo ""

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
