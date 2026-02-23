# LandBase AI Suite Development Lifecycle Automation
# Mattermost + n8n + Rails 8 + Next.js 15 + Flutter 3 + PostgreSQL

include .env.development
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
		| awk 'BEGIN {FS = ":.*?## "}; {printf " ${GREEN}%-22s${NC} %s\n", $$1, $$2}'

.PHONY: up
up: ## 全サービス起動（PostgreSQL, Platform, Mattermost, n8n）
	@echo "${GREEN}Starting all services...${NC}"
	docker compose -f compose.development.yaml --env-file .env.development up -d postgres platform mattermost n8n
	@echo "${GREEN}Platform is running at http://localhost:${PLATFORM_PORT}${NC}"
	@echo "${GREEN}Mattermost is running at http://localhost:${MATTERMOST_PORT}${NC}"
	@echo "${GREEN}n8n is running at http://localhost:${N8N_PORT}${NC}"

.PHONY: down
down: ## サービス停止
	docker compose -f compose.development.yaml --env-file .env.development down

.PHONY: logs
logs: ## 全サービスのログ表示
	docker compose -f compose.development.yaml --env-file .env.development logs --follow

.PHONY: postgres-shell
postgres-shell: ## PostgreSQLシェル接続
	docker compose -f compose.development.yaml --env-file .env.development exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

.PHONY: init
init: ## Platform: Railsアプリ新規作成
	@[ -d rails/platform ] && echo "${YELLOW}Rails application 'rails/platform' already exists.${NC}" && exit 1 || true
	@mkdir -p rails/platform
	@set -a && . ./.env.development && set +a && \
	docker compose -f compose.development.yaml --env-file .env.development run --rm --workdir /platform platform \
		rails new . --name $$PLATFORM_APP_NAME --database=postgresql --css=tailwind --javascript=importmap --skip-test --force
	@rm -rf rails/platform/.git
	@perl -i -pe 's/bin\/rails server$$/bin\/rails server -b 0.0.0.0/' rails/platform/Procfile.dev
	@echo "${GREEN}Platform: http://localhost:${PLATFORM_PORT}${NC}"

.PHONY: clean
clean: ## クリーンアップ（コンテナ・ボリューム・プロジェクトイメージ削除）
	docker compose -f compose.development.yaml --env-file .env.development down -v --rmi local
	@echo "${GREEN}Cleaned up Docker resources.${NC}"

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

# ================================
# Production Deployment
# ================================

.PHONY: prod-deploy
prod-deploy: ## 本番: Platformデプロイ（build → up → db:prepare）
	@echo "${GREEN}Deploying Platform...${NC}"
	docker compose -f compose.production.yaml --env-file .env.production build --no-cache
	docker compose -f compose.production.yaml --env-file .env.production down
	docker compose -f compose.production.yaml --env-file .env.production up -d
	docker compose -f compose.production.yaml --env-file .env.production exec app-suite rails db:prepare
	@echo "${GREEN}Platform deployed successfully.${NC}"

.PHONY: prod-logs
prod-logs: ## 本番: ログ表示
	docker compose -f compose.production.yaml --env-file .env.production logs -f

.PHONY: prod-db-reset
prod-db-reset: ## 本番: DBリセット（データ削除）
	@echo "${RED}WARNING: This will reset the production database!${NC}"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose -f compose.production.yaml --env-file .env.production exec app-suite rails db:reset

.PHONY: prod-secret
prod-secret: ## 本番: SECRET_KEY_BASE生成
	docker compose -f compose.production.yaml --env-file .env.production run --rm app-suite bundle exec rails secret
