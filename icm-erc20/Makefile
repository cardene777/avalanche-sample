# Makefile for ICM ERC20 Project

# 環境変数の読み込み
-include .env

# デフォルトターゲット
.PHONY: all
all: build

# ビルド
.PHONY: build
build:
	@echo "Building contracts..."
	forge build

# テスト実行
.PHONY: test
test:
	@echo "Running tests..."
	forge test -vvv

# テストカバレッジ
.PHONY: coverage
coverage:
	@echo "Running test coverage..."
	forge coverage

# フォーマット
.PHONY: format
format:
	@echo "Formatting contracts..."
	forge fmt

# クリーン
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	forge clean
	rm -f deploy_output.json

# 環境変数の設定
.PHONY: setup-env
setup-env:
	@echo "Setting up environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file. Please update it with your values."; \
	fi

# デプロイ関連コマンド
.PHONY: deploy-teleporter-c
deploy-teleporter-c: setup-env
	@echo "Deploying TeleporterERC20 to Fuji C-Chain..."
	@CHAIN_NAME=fuji-c forge script script/DeployTeleporterERC20.s.sol:DeployTeleporterERC20Script \
		--rpc-url fuji-c --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'TeleporterERC20 deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^FUJI_C_TOKEN_ADDRESS=.*/FUJI_C_TOKEN_ADDRESS='"$$ADDRESS"'/' .env && rm .env.bak; \
		echo "Deployment complete. FUJI_C_TOKEN_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

.PHONY: deploy-teleporter-dispatch
deploy-teleporter-dispatch: setup-env
	@echo "Deploying TeleporterERC20 to Fuji Dispatch..."
	@CHAIN_NAME=fuji-dispatch forge script script/DeployTeleporterERC20.s.sol:DeployTeleporterERC20Script \
		--rpc-url fuji-dispatch --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'TeleporterERC20 deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^FUJI_DISPATCH_TOKEN_ADDRESS=.*/FUJI_DISPATCH_TOKEN_ADDRESS='"$$ADDRESS"'/' .env && rm .env.bak; \
		echo "Deployment complete. FUJI_DISPATCH_TOKEN_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

.PHONY: deploy-sender-c
deploy-sender-c: setup-env
	@echo "Deploying SimpleSender to Fuji C-Chain..."
	@CONTRACT_TYPE=sender forge script script/DeploySimpleContracts.s.sol:DeploySimpleContractsScript \
		--rpc-url fuji-c --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'SimpleSender deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^FUJI_C_SIMPLE_SENDER_CONTRACT_ADDRESS=.*/FUJI_C_SIMPLE_SENDER_CONTRACT_ADDRESS='"$$ADDRESS"'/' .env && rm .env.bak; \
		echo "Deployment complete. FUJI_C_SIMPLE_SENDER_CONTRACT_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

.PHONY: deploy-receiver-dispatch
deploy-receiver-dispatch: setup-env
	@echo "Deploying SimpleReceiver to Fuji Dispatch..."
	@CONTRACT_TYPE=receiver forge script script/DeploySimpleContracts.s.sol:DeploySimpleContractsScript \
		--rpc-url fuji-dispatch --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'SimpleReceiver deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS=.*/FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS='"$$ADDRESS"'/' .env && rm .env.bak; \
		echo "Deployment complete. FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

# トークン操作コマンド
.PHONY: mint-c
mint-c:
	@echo "Minting tokens on Fuji C-Chain..."
	@cast send --rpc-url fuji-c --private-key "$(PK)" "$(FUJI_C_TOKEN_ADDRESS)" \
		"mint(address,uint256)" "$(SENDER_ADDRESS)" 100000000000000000000

.PHONY: mint-dispatch
mint-dispatch:
	@echo "Minting tokens on Fuji Dispatch..."
	@cast send --rpc-url fuji-dispatch --private-key "$(PK)" "$(FUJI_DISPATCH_TOKEN_ADDRESS)" \
		"mint(address,uint256)" "$(SENDER_ADDRESS)" 100000000000000000000

.PHONY: balance-c
balance-c:
	@echo "Checking balance on Fuji C-Chain..."
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		ADDR="$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		ADDR=$${ADDRESS:-$(SENDER_ADDRESS)}; \
	fi; \
	cast call --rpc-url fuji-c "$(FUJI_C_TOKEN_ADDRESS)" \
		"balanceOf(address)(uint256)" "$$ADDR"

# Prevent treating arguments as targets
%:
	@:

.PHONY: balance-dispatch
balance-dispatch:
	@echo "Checking balance on Fuji Dispatch..."
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		ADDR="$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		ADDR=$${ADDRESS:-$(SENDER_ADDRESS)}; \
	fi; \
	cast call --rpc-url fuji-dispatch "$(FUJI_DISPATCH_TOKEN_ADDRESS)" \
		"balanceOf(address)(uint256)" "$$ADDR"

.PHONY: send-tokens-c-to-dispatch
send-tokens-c-to-dispatch:
	@echo "Sending tokens from Fuji C-Chain to Dispatch..."
	@cast send --rpc-url fuji-c --private-key "$(PK)" "$(FUJI_C_TOKEN_ADDRESS)" \
		"sendTokens(bytes32,address,address,uint256)" \
		"$(FUJI_DISPATCH_BLOCKCHAIN_ID_HEX)" "$(FUJI_DISPATCH_TOKEN_ADDRESS)" "$(RECEIVER_ADDRESS)" 10000000000000000000

.PHONY: send-tokens-dispatch-to-c
send-tokens-dispatch-to-c:
	@echo "Sending tokens from Fuji Dispatch to C-Chain..."
	@cast send --rpc-url fuji-dispatch --private-key "$(PK)" "$(FUJI_DISPATCH_TOKEN_ADDRESS)" \
		"sendTokens(bytes32,address,address,uint256)" \
		"$(FUJI_C_CHAIN_BLOCKCHAIN_ID_HEX)" "$(FUJI_C_TOKEN_ADDRESS)" "$(RECEIVER_ADDRESS)" 10000000000000000000

# シンプルメッセージ送信コマンド
.PHONY: send-message-c-to-dispatch
send-message-c-to-dispatch:
	@echo "Sending message from Fuji C-Chain to Dispatch..."
	@cast send --rpc-url fuji-c --private-key "$(PK)" "$(FUJI_C_SIMPLE_SENDER_CONTRACT_ADDRESS)" \
		"sendMessage(bytes32,address,string)" \
		"$(FUJI_DISPATCH_BLOCKCHAIN_ID_HEX)" "$(FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS)" "Hello from C-Chain!"

.PHONY: check-message-dispatch
check-message-dispatch:
	@echo "Checking last message on Fuji Dispatch..."
	@cast call --rpc-url fuji-dispatch "$(FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS)" "lastMessage()(string)"

# トークンコントラクトのデプロイ
.PHONY: deploy-tokens
deploy-tokens: deploy-teleporter-c deploy-teleporter-dispatch
	@echo "Token contracts deployed!"
	@echo ""
	@echo "Deployed token contract addresses have been updated in .env file."

# シンプルコントラクトのデプロイ
.PHONY: deploy-simple-contracts
deploy-simple-contracts: deploy-sender-c deploy-receiver-dispatch
	@echo "Simple contracts deployed!"
	@echo ""
	@echo "Deployed simple contract addresses have been updated in .env file."

# 全コントラクトのデプロイ
.PHONY: deploy-all
deploy-all: deploy-tokens deploy-simple-contracts
	@echo "All contracts deployed!"
	@echo ""
	@echo "All contract addresses have been updated in .env file."


# ヘルプ
.PHONY: help
help:
	@echo "Available commands:"
	@echo ""
	@echo "Basic commands:"
	@echo "  make build                    - Build contracts"
	@echo "  make test                     - Run tests"
	@echo "  make coverage                 - Run test coverage"
	@echo "  make format                   - Format contracts"
	@echo "  make clean                    - Clean build artifacts"
	@echo ""
	@echo "Deployment commands:"
	@echo "  make deploy-all               - Deploy all contracts"
	@echo "  make deploy-tokens            - Deploy only TeleporterERC20 token contracts"
	@echo "  make deploy-simple-contracts  - Deploy only SimpleSender/SimpleReceiver contracts"
	@echo "  make deploy-teleporter-c      - Deploy TeleporterERC20 to Fuji C-Chain"
	@echo "  make deploy-teleporter-dispatch - Deploy TeleporterERC20 to Fuji Dispatch"
	@echo "  make deploy-sender-c          - Deploy SimpleSender to Fuji C-Chain"
	@echo "  make deploy-receiver-dispatch - Deploy SimpleReceiver to Fuji Dispatch"
	@echo ""
	@echo "Token operations:"
	@echo "  make mint-c                   - Mint tokens on Fuji C-Chain"
	@echo "  make mint-dispatch            - Mint tokens on Fuji Dispatch"
	@echo "  make balance-c                - Check balance on Fuji C-Chain"
	@echo "  make balance-dispatch         - Check balance on Fuji Dispatch"
	@echo "  make send-tokens-c-to-dispatch - Send tokens from C-Chain to Dispatch"
	@echo "  make send-tokens-dispatch-to-c - Send tokens from Dispatch to C-Chain"
	@echo ""
	@echo "Simple message operations:"
	@echo "  make send-message-c-to-dispatch - Send message from C-Chain to Dispatch"
	@echo "  make check-message-dispatch     - Check last message on Dispatch"
	@echo ""
	@echo "Environment setup:"
	@echo "  make setup-env                - Set up environment files"