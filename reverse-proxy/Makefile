# Caddy Reverse Proxy Management

.PHONY: help
help: ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: up
up: ## リバースプロキシを起動（web-proxy-netも自動作成）
	docker network inspect web-proxy-net >/dev/null 2>&1 || docker network create web-proxy-net
	docker compose up -d
	@echo "✅ リバースプロキシを起動しました"

.PHONY: down
down: ## リバースプロキシを停止
	docker compose down
	@echo "✅ リバースプロキシを停止しました"

.PHONY: logs
logs: ## リバースプロキシのログを表示
	docker compose logs -f

.PHONY: reload
reload: ## Caddyfileの設定を再読み込み
	docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
	@echo "✅ Caddyfile を再読み込みしました"
