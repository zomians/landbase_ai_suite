# Caddy Reverse Proxy Management

YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m

.PHONY: help
help: ## ヘルプ表示
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| cut -d: -f2- \
		| awk 'BEGIN {FS = ":.*?## "}; {printf " ${GREEN}%-22s${NC} %s\n", $$1, $$2}'

.PHONY: network
network: ## 共有ネットワーク作成
	@docker network create web-proxy-net 2>/dev/null || true
	@echo "${GREEN}web-proxy-net network ready.${NC}"

.PHONY: up
up: network ## Caddy起動
	docker compose up -d
	@echo "${GREEN}Caddy reverse proxy is running.${NC}"

.PHONY: down
down: ## Caddy停止
	docker compose down

.PHONY: logs
logs: ## ログ表示
	docker compose logs -f

.PHONY: reload
reload: ## Caddyfile再読み込み
	docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
	@echo "${GREEN}Caddyfile reloaded.${NC}"
