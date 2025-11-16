# Makefile for Simple ERC721 NFT Project

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
	rm -rf cache out broadcast

# 環境変数の設定
.PHONY: setup-env
setup-env:
	@echo "Setting up environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file. Please update it with your values."; \
	fi

# デプロイ関連コマンド
.PHONY: deploy-l1
deploy-l1: setup-env
	@echo "Deploying SimpleNFT to Avalanche L1..."
	@forge script script/Deploy.s.sol:DeployScript \
		--rpc-url avalanche_l1 --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'SimpleNFT deployed at:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^NFT_ADDRESS=.*/NFT_ADDRESS='"$$ADDRESS"'/' .env && rm .env.bak; \
		echo ""; \
		echo "========================================"; \
		echo "Deployment successful!"; \
		echo "SimpleNFT deployed at: $$ADDRESS"; \
		echo "NFT_ADDRESS updated in .env file"; \
		echo "========================================"; \
		echo ""; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

.PHONY: deploy-fuji
deploy-fuji: setup-env
	@echo "Deploying SimpleNFT to Fuji testnet..."
	@forge script script/Deploy.s.sol:DeployScript \
		--rpc-url avalanche_fuji --broadcast -vvv | tee deploy_output.log
	@ADDRESS=$$(grep 'SimpleNFT deployed at:' deploy_output.log | awk '{print $$4}'); \
	if [ -n "$$ADDRESS" ]; then \
		sed -i.bak 's/^NFT_ADDRESS=.*/NFT_ADDRESS='"$$ADDRESS"'/' .env && rm .env.bak; \
		echo ""; \
		echo "========================================"; \
		echo "Deployment successful!"; \
		echo "SimpleNFT deployed at: $$ADDRESS"; \
		echo "NFT_ADDRESS updated in .env file"; \
		echo "========================================"; \
		echo ""; \
	else \
		echo "Failed to extract deployed address"; \
		exit 1; \
	fi

# NFT操作コマンド
.PHONY: mint
mint:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Minting to default address..."; \
		TO_ADDRESS=$${USER_ADDRESS:-$(shell cast wallet address $(PRIVATE_KEY))}; \
	else \
		TO_ADDRESS="$(filter-out $@,$(MAKECMDGOALS))"; \
	fi; \
	cast send $(NFT_ADDRESS) "mint(address)" $$TO_ADDRESS \
		--rpc-url avalanche_l1 \
		--private-key $(PRIVATE_KEY)

.PHONY: mint-batch
mint-batch:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@ARGS="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$ARGS" ]; then \
		echo "Minting 5 NFTs to default address..."; \
		TO_ADDRESS=$${USER_ADDRESS:-$(shell cast wallet address $(PRIVATE_KEY))}; \
		AMOUNT=5; \
	else \
		ARGS_ARRAY=($$ARGS); \
		TO_ADDRESS="$${ARGS_ARRAY[0]}"; \
		AMOUNT="$${ARGS_ARRAY[1]:-5}"; \
	fi; \
	cast send $(NFT_ADDRESS) "mintBatch(address,uint256)" $$TO_ADDRESS $$AMOUNT \
		--rpc-url avalanche_l1 \
		--private-key $(PRIVATE_KEY)

# 読み取り専用コマンド
.PHONY: total-supply
total-supply:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@echo "Total supply:"
	@cast call $(NFT_ADDRESS) "totalSupply()(uint256)" --rpc-url avalanche_l1

.PHONY: balance
balance:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		ADDRESS=$${USER_ADDRESS:-$(shell cast wallet address $(PRIVATE_KEY))}; \
	else \
		ADDRESS="$(filter-out $@,$(MAKECMDGOALS))"; \
	fi; \
	echo "Balance of $$ADDRESS:"; \
	cast call $(NFT_ADDRESS) "balanceOf(address)(uint256)" $$ADDRESS --rpc-url avalanche_l1

.PHONY: owner-of
owner-of:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@TOKEN_ID="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TOKEN_ID" ]; then \
		echo "Error: Token ID is required. Run 'make owner-of <token_id>'"; \
		exit 1; \
	fi; \
	echo "Owner of token $$TOKEN_ID:"; \
	cast call $(NFT_ADDRESS) "ownerOf(uint256)(address)" $$TOKEN_ID --rpc-url avalanche_l1

.PHONY: token-uri
token-uri:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@TOKEN_ID="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TOKEN_ID" ]; then \
		echo "Error: Token ID is required. Run 'make token-uri <token_id>'"; \
		exit 1; \
	fi; \
	echo "Token URI for token $$TOKEN_ID:"; \
	cast call $(NFT_ADDRESS) "tokenURI(uint256)(string)" $$TOKEN_ID --rpc-url avalanche_l1

# NFTコントラクトの情報
.PHONY: nft-info
nft-info:
	@if [ -z "$(NFT_ADDRESS)" ]; then \
		echo "Error: NFT_ADDRESS is not set. Deploy the contract first using 'make deploy-l1' or 'make deploy-fuji'"; \
		exit 1; \
	fi
	@echo "NFT Contract Information:"
	@echo "========================"
	@echo "Address: $(NFT_ADDRESS)"
	@echo -n "Name: "
	@cast call $(NFT_ADDRESS) "name()(string)" --rpc-url avalanche_l1
	@echo -n "Symbol: "
	@cast call $(NFT_ADDRESS) "symbol()(string)" --rpc-url avalanche_l1
	@echo -n "Total Supply: "
	@cast call $(NFT_ADDRESS) "totalSupply()(uint256)" --rpc-url avalanche_l1
	@echo -n "Owner: "
	@cast call $(NFT_ADDRESS) "owner()(address)" --rpc-url avalanche_l1

# トランザクション確認コマンド
.PHONY: tx-count
tx-count:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		ADDRESS=$${USER_ADDRESS:-$(shell cast wallet address $(PRIVATE_KEY))}; \
	else \
		ADDRESS="$(filter-out $@,$(MAKECMDGOALS))"; \
	fi; \
	echo "Transaction count for $$ADDRESS:"; \
	cast nonce $$ADDRESS --rpc-url avalanche_l1

.PHONY: latest-block
latest-block:
	@echo "Latest block information:"
	@cast block latest --rpc-url avalanche_l1

.PHONY: block-number
block-number:
	@echo "Current block number:"
	@cast block-number --rpc-url avalanche_l1

.PHONY: gas-price
gas-price:
	@echo "Current gas price:"
	@cast gas-price --rpc-url avalanche_l1

.PHONY: tx
tx:
	@TX_HASH="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TX_HASH" ]; then \
		echo "Error: Transaction hash is required. Run 'make tx <tx_hash>'"; \
		exit 1; \
	fi; \
	echo "Transaction details for $$TX_HASH:"; \
	cast tx $$TX_HASH --rpc-url avalanche_l1

.PHONY: receipt
receipt:
	@TX_HASH="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TX_HASH" ]; then \
		echo "Error: Transaction hash is required. Run 'make receipt <tx_hash>'"; \
		exit 1; \
	fi; \
	echo "Transaction receipt for $$TX_HASH:"; \
	cast receipt $$TX_HASH --rpc-url avalanche_l1

# ヘルプ
.PHONY: help
help:
	@echo "Available commands:"
	@echo ""
	@echo "Basic commands:"
	@echo "  make build                  - Build contracts"
	@echo "  make test                   - Run tests"
	@echo "  make coverage               - Run test coverage"
	@echo "  make format                 - Format contracts"
	@echo "  make clean                  - Clean build artifacts"
	@echo ""
	@echo "Deployment commands:"
	@echo "  make deploy-l1              - Deploy to Avalanche L1"
	@echo "  make deploy-fuji            - Deploy to Fuji testnet"
	@echo ""
	@echo "NFT operations:"
	@echo "  make mint [address]         - Mint a single NFT to address (default: your address)"
	@echo "  make mint-batch [address] [amount] - Mint multiple NFTs (default: 5 to your address)"
	@echo ""
	@echo "Read operations:"
	@echo "  make nft-info               - Show NFT contract information"
	@echo "  make total-supply           - Get total supply"
	@echo "  make balance [address]      - Check balance of address (default: your address)"
	@echo "  make owner-of <token_id>    - Get owner of specific token"
	@echo "  make token-uri <token_id>   - Get token URI"
	@echo ""
	@echo "Transaction info:"
	@echo "  make tx-count [address]     - Get transaction count (nonce)"
	@echo "  make latest-block           - Show latest block info"
	@echo "  make block-number           - Show current block number"
	@echo "  make gas-price              - Show current gas price"
	@echo "  make tx <tx_hash>           - Show transaction details"
	@echo "  make receipt <tx_hash>      - Show transaction receipt"
	@echo ""
	@echo "Environment setup:"
	@echo "  make setup-env              - Set up environment files"
	@echo ""
	@echo "Usage examples:"
	@echo "  make deploy-l1"
	@echo "  make mint 0x1234..."
	@echo "  make mint-batch 0x1234... 10"
	@echo "  make balance 0x1234..."
	@echo "  make owner-of 0"
	@echo "  make token-uri 0"
	@echo "  make tx-count"
	@echo "  make tx 0xabc123..."