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
		| awk 'BEGIN {FS = ":.*?## "}; {printf " ${GREEN}%-22s${NC} %s\n", $$1, $$2}'

.PHONY: up
up: ## 全サービス起動（PostgreSQL, Platform, Mattermost, n8n）
	@echo "${GREEN}Starting all services...${NC}"
	docker compose up -d postgres platform mattermost n8n
	@echo "${GREEN}Platform is running at http://localhost:${PLATFORM_PORT}${NC}"
	@echo "${GREEN}Mattermost is running at http://localhost:${MATTERMOST_PORT}${NC}"
	@echo "${GREEN}n8n is running at http://localhost:${N8N_PORT}${NC}"

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

.PHONY: init
init: ## Platform: Railsアプリ新規作成
	@[ -d rails/platform ] && echo "${YELLOW}Rails application 'rails/platform' already exists.${NC}" && exit 1 || true
	@mkdir -p rails/platform
	@set -a && . ./.env && set +a && \
	docker compose run --rm --workdir /platform platform \
		rails new . --name $$PLATFORM_APP_NAME --database=postgresql --css=tailwind --javascript=importmap --skip-test --force
	@rm -rf rails/platform/.git
	@perl -i -pe 's/bin\/rails server$$/bin\/rails server -b 0.0.0.0/' rails/platform/Procfile.dev
	@echo "${GREEN}Platform: http://localhost:${PLATFORM_PORT}${NC}"

.PHONY: clean
clean: ## クリーンアップ（コンテナ・ボリューム・プロジェクトイメージ削除）
	docker compose --env-file .env down -v --rmi local
	@echo "${GREEN}Cleaned up Docker resources.${NC}"

# ================================
# ngrok（LINE Webhook用）
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

