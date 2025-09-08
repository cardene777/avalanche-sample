# Makefile for ICM ERC20 Project

# 環境変数の読み込み
-include .env

# Avalancheローカルテスト用のewoqキー
EWOQ_PRIVATE_KEY = 0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
EWOQ_ADDRESS = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC

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

# チェーン設定を取得する関数
define get_chain_config
	$(eval CHAIN := $(1))
	$(if $(filter c-chain,$(CHAIN)),
		$(eval CHAIN_NAME := fuji-c)
		$(eval TOKEN_ADDRESS := $(FUJI_C_TOKEN_ADDRESS))
		$(eval BLOCKCHAIN_ID := $(FUJI_C_CHAIN_BLOCKCHAIN_ID_HEX))
		$(eval SENDER_CONTRACT := $(FUJI_C_SIMPLE_SENDER_CONTRACT_ADDRESS))
		$(eval RPC_URL := fuji-c)
		$(eval DEPLOY_PK := $(PK))
		$(eval SENDER_ADDRESS := $(SENDER_ADDRESS))
		$(eval RECEIVER_ADDRESS := $(RECEIVER_ADDRESS))
		$(eval ENV_VAR_PREFIX := FUJI_C)
		$(eval CHAIN_DISPLAY := Fuji C-Chain)
	)
	$(if $(filter dispatch,$(CHAIN)),
		$(eval CHAIN_NAME := fuji-dispatch)
		$(eval TOKEN_ADDRESS := $(FUJI_DISPATCH_TOKEN_ADDRESS))
		$(eval BLOCKCHAIN_ID := $(FUJI_DISPATCH_BLOCKCHAIN_ID_HEX))
		$(eval RECEIVER_CONTRACT := $(FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS))
		$(eval RPC_URL := fuji-dispatch)
		$(eval DEPLOY_PK := $(PK))
		$(eval SENDER_ADDRESS := $(SENDER_ADDRESS))
		$(eval RECEIVER_ADDRESS := $(RECEIVER_ADDRESS))
		$(eval ENV_VAR_PREFIX := FUJI_DISPATCH)
		$(eval CHAIN_DISPLAY := Fuji Dispatch)
	)
	$(if $(filter l1-1,$(CHAIN)),
		$(eval CHAIN_NAME := local-l1)
		$(eval TOKEN_ADDRESS := $(LOCAL_L1_1_TOKEN_ADDRESS))
		$(eval BLOCKCHAIN_ID := $(LOCAL_L1_1_BLOCKCHAIN_ID_HEX))
		$(eval SENDER_CONTRACT := $(LOCAL_L1_1_SIMPLE_SENDER_CONTRACT_ADDRESS))
		$(eval RPC_URL := local-l1)
		$(eval DEPLOY_PK := $(EWOQ_PRIVATE_KEY))
		$(eval SENDER_ADDRESS := $(EWOQ_ADDRESS))
		$(eval RECEIVER_ADDRESS := $(EWOQ_ADDRESS))
		$(eval ENV_VAR_PREFIX := LOCAL_L1_1)
		$(eval CHAIN_DISPLAY := L1-1)
	)
	$(if $(filter l1-2,$(CHAIN)),
		$(eval CHAIN_NAME := local-l2)
		$(eval TOKEN_ADDRESS := $(LOCAL_L1_2_TOKEN_ADDRESS))
		$(eval BLOCKCHAIN_ID := $(LOCAL_L1_2_BLOCKCHAIN_ID_HEX))
		$(eval RECEIVER_CONTRACT := $(LOCAL_L1_2_SIMPLE_RECEIVER_CONTRACT_ADDRESS))
		$(eval RPC_URL := local-l2)
		$(eval DEPLOY_PK := $(EWOQ_PRIVATE_KEY))
		$(eval SENDER_ADDRESS := $(EWOQ_ADDRESS))
		$(eval RECEIVER_ADDRESS := $(EWOQ_ADDRESS))
		$(eval ENV_VAR_PREFIX := LOCAL_L1_2)
		$(eval CHAIN_DISPLAY := L1-2)
	)
endef

# トークンのデプロイ
.PHONY: deploy-token
deploy-token: setup-env
	@if [ -z "$(filter c-chain dispatch l1-1 l1-2,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make deploy-token [c-chain|dispatch|l1-1|l1-2]"; \
		exit 1; \
	fi
	$(eval TARGET_CHAIN := $(filter c-chain dispatch l1-1 l1-2,$(MAKECMDGOALS)))
	$(call get_chain_config,$(TARGET_CHAIN))
	@echo "Deploying TeleporterERC20 to $(CHAIN_DISPLAY)..."
	@DEPLOY_PK=$(DEPLOY_PK) CHAIN_NAME=$(CHAIN_NAME) forge script script/DeployTeleporterERC20.s.sol:DeployTeleporterERC20Script \
		--rpc-url $(RPC_URL) --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'TeleporterERC20 deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^$(ENV_VAR_PREFIX)_TOKEN_ADDRESS=.*/$(ENV_VAR_PREFIX)_TOKEN_ADDRESS='$$ADDRESS'/' .env && rm .env.bak; \
		echo "Deployment complete. $(ENV_VAR_PREFIX)_TOKEN_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

# SimpleSenderのデプロイ
.PHONY: deploy-sender
deploy-sender: setup-env
	@if [ -z "$(filter c-chain l1-1,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make deploy-sender [c-chain|l1-1]"; \
		exit 1; \
	fi
	$(eval TARGET_CHAIN := $(filter c-chain l1-1,$(MAKECMDGOALS)))
	$(call get_chain_config,$(TARGET_CHAIN))
	@echo "Deploying SimpleSender to $(CHAIN_DISPLAY)..."
	@CONTRACT_TYPE=sender DEPLOY_PK=$(DEPLOY_PK) CHAIN_NAME=$(CHAIN_NAME) forge script script/DeploySimpleContracts.s.sol:DeploySimpleContractsScript \
		--rpc-url $(RPC_URL) --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'SimpleSender deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^$(ENV_VAR_PREFIX)_SIMPLE_SENDER_CONTRACT_ADDRESS=.*/$(ENV_VAR_PREFIX)_SIMPLE_SENDER_CONTRACT_ADDRESS='$$ADDRESS'/' .env && rm .env.bak; \
		echo "Deployment complete. $(ENV_VAR_PREFIX)_SIMPLE_SENDER_CONTRACT_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

# SimpleReceiverのデプロイ
.PHONY: deploy-receiver
deploy-receiver: setup-env
	@if [ -z "$(filter dispatch l1-2,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make deploy-receiver [dispatch|l1-2]"; \
		exit 1; \
	fi
	$(eval TARGET_CHAIN := $(filter dispatch l1-2,$(MAKECMDGOALS)))
	$(call get_chain_config,$(TARGET_CHAIN))
	@echo "Deploying SimpleReceiver to $(CHAIN_DISPLAY)..."
	@CONTRACT_TYPE=receiver DEPLOY_PK=$(DEPLOY_PK) CHAIN_NAME=$(CHAIN_NAME) forge script script/DeploySimpleContracts.s.sol:DeploySimpleContractsScript \
		--rpc-url $(RPC_URL) --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'SimpleReceiver deployed to:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^$(ENV_VAR_PREFIX)_SIMPLE_RECEIVER_CONTRACT_ADDRESS=.*/$(ENV_VAR_PREFIX)_SIMPLE_RECEIVER_CONTRACT_ADDRESS='$$ADDRESS'/' .env && rm .env.bak; \
		echo "Deployment complete. $(ENV_VAR_PREFIX)_SIMPLE_RECEIVER_CONTRACT_ADDRESS updated to $$ADDRESS"; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

# トークンのmint
.PHONY: mint
mint:
	@if [ -z "$(filter c-chain dispatch l1-1 l1-2,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make mint [c-chain|dispatch|l1-1|l1-2]"; \
		exit 1; \
	fi
	$(eval TARGET_CHAIN := $(filter c-chain dispatch l1-1 l1-2,$(MAKECMDGOALS)))
	$(call get_chain_config,$(TARGET_CHAIN))
	@echo "Minting tokens on $(CHAIN_DISPLAY)..."
	@cast send --rpc-url $(RPC_URL) --private-key "$(DEPLOY_PK)" "$(TOKEN_ADDRESS)" \
		"mint(address,uint256)" "$(SENDER_ADDRESS)" 100000000000000000000

# 残高確認
.PHONY: balance
balance:
	@if [ -z "$(filter c-chain dispatch l1-1 l1-2,$(word 2,$(MAKECMDGOALS)))" ]; then \
		echo "Usage: make balance [c-chain|dispatch|l1-1|l1-2] [address]"; \
		exit 1; \
	fi
	$(eval TARGET_CHAIN := $(word 2,$(MAKECMDGOALS)))
	$(eval ADDRESS_ARG := $(word 3,$(MAKECMDGOALS)))
	$(call get_chain_config,$(TARGET_CHAIN))
	@echo "Checking balance on $(CHAIN_DISPLAY)..."
	@if [ -z "$(TOKEN_ADDRESS)" ]; then \
		echo "Error: Token address not set. Deploy the token first."; \
		exit 1; \
	fi
	@if [ -n "$(ADDRESS_ARG)" ]; then \
		ADDR="$(ADDRESS_ARG)"; \
	else \
		ADDR="$(SENDER_ADDRESS)"; \
	fi; \
	echo "Checking balance of $$ADDR..."; \
	cast call --rpc-url $(RPC_URL) "$(TOKEN_ADDRESS)" \
		"balanceOf(address)(uint256)" "$$ADDR"

# トークン送信
.PHONY: send-tokens
send-tokens:
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ] || [ -z "$(word 3,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make send-tokens [from-chain] [to-chain]"; \
		echo "  Chains: c-chain, dispatch, l1-1, l1-2"; \
		exit 1; \
	fi
	$(eval FROM_CHAIN := $(word 2,$(MAKECMDGOALS)))
	$(eval TO_CHAIN := $(word 3,$(MAKECMDGOALS)))
	$(call get_chain_config,$(FROM_CHAIN))
	$(eval FROM_TOKEN := $(TOKEN_ADDRESS))
	$(eval FROM_RPC := $(RPC_URL))
	$(eval FROM_PK := $(DEPLOY_PK))
	$(eval FROM_DISPLAY := $(CHAIN_DISPLAY))
	$(eval FROM_ADDR := $(RECEIVER_ADDRESS))
	$(call get_chain_config,$(TO_CHAIN))
	$(eval TO_TOKEN := $(TOKEN_ADDRESS))
	$(eval TO_BLOCKCHAIN_ID := $(BLOCKCHAIN_ID))
	$(eval TO_DISPLAY := $(CHAIN_DISPLAY))
	@echo "Sending tokens from $(FROM_DISPLAY) to $(TO_DISPLAY)..."
	@cast send --rpc-url $(FROM_RPC) --private-key "$(FROM_PK)" "$(FROM_TOKEN)" \
		"sendTokens(bytes32,address,address,uint256)" \
		"$(TO_BLOCKCHAIN_ID)" "$(TO_TOKEN)" "$(FROM_ADDR)" 10000000000000000000

# シンプルメッセージ送信
.PHONY: send-message
send-message:
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ] || [ -z "$(word 3,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make send-message [from-chain] [to-chain]"; \
		echo "  From chains: c-chain, l1-1"; \
		echo "  To chains: dispatch, l1-2"; \
		exit 1; \
	fi
	$(eval FROM_CHAIN := $(word 2,$(MAKECMDGOALS)))
	$(eval TO_CHAIN := $(word 3,$(MAKECMDGOALS)))
	$(call get_chain_config,$(FROM_CHAIN))
	$(eval FROM_RPC := $(RPC_URL))
	$(eval FROM_PK := $(DEPLOY_PK))
	$(eval FROM_SENDER := $(SENDER_CONTRACT))
	$(eval FROM_DISPLAY := $(CHAIN_DISPLAY))
	$(call get_chain_config,$(TO_CHAIN))
	$(eval TO_RECEIVER := $(RECEIVER_CONTRACT))
	$(eval TO_BLOCKCHAIN_ID := $(BLOCKCHAIN_ID))
	$(eval TO_DISPLAY := $(CHAIN_DISPLAY))
	@MSG="Hello from $(FROM_DISPLAY)!"; \
	echo "Sending message from $(FROM_DISPLAY) to $(TO_DISPLAY)..."; \
	cast send --rpc-url $(FROM_RPC) --private-key "$(FROM_PK)" "$(FROM_SENDER)" \
		"sendMessage(bytes32,address,string)" \
		"$(TO_BLOCKCHAIN_ID)" "$(TO_RECEIVER)" "$$MSG"

# メッセージ確認
.PHONY: check-message
check-message:
	@if [ -z "$(filter dispatch l1-2,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make check-message [dispatch|l1-2]"; \
		exit 1; \
	fi
	$(eval TARGET_CHAIN := $(filter dispatch l1-2,$(MAKECMDGOALS)))
	$(call get_chain_config,$(TARGET_CHAIN))
	@echo "Checking last message on $(CHAIN_DISPLAY)..."
	@cast call --rpc-url $(RPC_URL) "$(RECEIVER_CONTRACT)" "lastMessage()(string)"

# 全コントラクトのデプロイ
.PHONY: deploy-all
deploy-all:
	@if [ -z "$(filter fuji local,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make deploy-all [fuji|local]"; \
		exit 1; \
	fi
	@if [ "$(filter fuji,$(MAKECMDGOALS))" ]; then \
		$(MAKE) deploy-token c-chain; \
		$(MAKE) deploy-token dispatch; \
		$(MAKE) deploy-sender c-chain; \
		$(MAKE) deploy-receiver dispatch; \
		echo "All Fuji testnet contracts deployed!"; \
	elif [ "$(filter local,$(MAKECMDGOALS))" ]; then \
		$(MAKE) deploy-token l1-1; \
		$(MAKE) deploy-token l1-2; \
		$(MAKE) deploy-sender l1-1; \
		$(MAKE) deploy-receiver l1-2; \
		echo "All local contracts deployed!"; \
	fi

# Makeが引数をターゲットとして扱わないようにする
%:
	@:

# ヘルプ
.PHONY: help
help:
	@echo "ICM ERC20 Project Commands"
	@echo ""
	@echo "Basic commands:"
	@echo "  make build                    - Build contracts"
	@echo "  make test                     - Run tests"
	@echo "  make coverage                 - Run test coverage"
	@echo "  make format                   - Format contracts"
	@echo "  make clean                    - Clean build artifacts"
	@echo ""
	@echo "Deployment commands:"
	@echo "  make deploy-all fuji          - Deploy all contracts to Fuji testnet"
	@echo "  make deploy-all local         - Deploy all contracts to local chains"
	@echo "  make deploy-token [chain]     - Deploy TeleporterERC20 token contract"
	@echo "  make deploy-sender [chain]    - Deploy SimpleSender contract"
	@echo "  make deploy-receiver [chain]  - Deploy SimpleReceiver contract"
	@echo ""
	@echo "Token operations:"
	@echo "  make mint [chain]             - Mint 100 tokens"
	@echo "  make balance [chain] [addr]   - Check token balance"
	@echo "  make send-tokens [from] [to]  - Send 10 tokens between chains"
	@echo ""
	@echo "Message operations:"
	@echo "  make send-message [from] [to] - Send a test message"
	@echo "  make check-message [chain]    - Check last received message"
	@echo ""
	@echo "Available chains:"
	@echo "  c-chain    - Fuji C-Chain"
	@echo "  dispatch   - Fuji Dispatch"
	@echo "  l1-1       - Local L1 chain 1"
	@echo "  l1-2       - Local L1 chain 2"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy-all fuji"
	@echo "  make mint c-chain"
	@echo "  make balance l1-1 0x1234..."
	@echo "  make send-tokens c-chain dispatch"
	@echo "  make send-message l1-1 l1-2"