# Makefile for ICM ERC20 Project

# .envファイルを読み込む
include .env
export

# デフォルト値
AMOUNT ?= 1000000000000000000000
TRANSFER_AMOUNT ?= 100000000000000000000
TO ?= $(DEFAULT_RECIPIENT)
ADDRESS ?= $(DEFAULT_RECIPIENT)
CHAIN ?= 1
FROM ?= 1

# ヘルプ
.PHONY: help
help:
	@echo "使用可能なコマンド:"
	@echo ""
	@echo "  make deploy        - Chain1とChain2にTeleporterERC20をデプロイ"
	@echo ""
	@echo "  make mint CHAIN=1 TO=0x... AMOUNT=1000"
	@echo "                     - 指定チェーンでトークンをmint"
	@echo "                     - CHAIN: 1 または 2 (デフォルト: 1)"
	@echo "                     - TO: 受信者アドレス (デフォルト: DEFAULT_RECIPIENT)"
	@echo "                     - AMOUNT: mint量（wei単位） (デフォルト: 1000 * 10^18)"
	@echo ""
	@echo "  make balance CHAIN=1 ADDRESS=0x..."
	@echo "                     - 指定チェーンの残高確認"
	@echo "                     - CHAIN: 1, 2, または all (デフォルト: 1)"
	@echo "                     - ADDRESS: 確認するアドレス (デフォルト: DEFAULT_RECIPIENT)"
	@echo ""
	@echo "  make transfer FROM=1 TO=2 TRANSFER_AMOUNT=100 ADDRESS=0x..."
	@echo "                     - クロスチェーン転送"
	@echo "                     - FROM: 送信元チェーン (デフォルト: 1)"
	@echo "                     - TO: 送信先チェーン (必須: 1 または 2)"
	@echo "                     - TRANSFER_AMOUNT: 転送量（wei単位） (デフォルト: 100 * 10^18)"
	@echo "                     - ADDRESS: 受信者アドレス (デフォルト: DEFAULT_RECIPIENT)"
	@echo ""
	@echo "  make clean         - キャッシュとビルドファイルをクリーン"
	@echo ""
	@echo "例:"
	@echo "  make mint CHAIN=2 TO=0x1234... AMOUNT=5000000000000000000000"
	@echo "  make balance CHAIN=1 ADDRESS=0x1234..."
	@echo "  make transfer FROM=1 TO=2 TRANSFER_AMOUNT=50000000000000000000"

# デプロイ
.PHONY: deploy
deploy:
	@echo "TeleporterERC20をデプロイ中..."
	./scripts/setup/deploy-teleporter-tokens.sh

# mint（パラメータ指定可能）
.PHONY: mint
mint:
ifeq ($(CHAIN),2)
	@echo "Chain2でトークンをmint中..."
	@echo "宛先: $(TO)"
	@echo "金額: $(AMOUNT) wei"
	cd contract && TOKEN_ADDRESS=$(CHAIN2_TOKEN_ADDRESS) MINT_TO=$(TO) MINT_AMOUNT=$(AMOUNT) \
		forge script script/MintToken.s.sol:MintToken \
		--rpc-url $(CHAIN2_RPC_URL) \
		--broadcast \
		--slow
else
	@echo "Chain1でトークンをmint中..."
	@echo "宛先: $(TO)"
	@echo "金額: $(AMOUNT) wei"
	cd contract && TOKEN_ADDRESS=$(CHAIN1_TOKEN_ADDRESS) MINT_TO=$(TO) MINT_AMOUNT=$(AMOUNT) \
		forge script script/MintToken.s.sol:MintToken \
		--rpc-url $(CHAIN1_RPC_URL) \
		--broadcast \
		--slow
endif

# 残高確認（パラメータ指定可能）
.PHONY: balance
balance:
ifeq ($(CHAIN),all)
	@cd contract && TOKEN_ADDRESS=$(CHAIN1_TOKEN_ADDRESS) CHECK_ADDRESS=$(ADDRESS) CHAIN_NAME="Chain1" \
		forge script script/CheckBalance.s.sol:CheckBalance \
		--rpc-url $(CHAIN1_RPC_URL)
	@echo ""
	@cd contract && TOKEN_ADDRESS=$(CHAIN2_TOKEN_ADDRESS) CHECK_ADDRESS=$(ADDRESS) CHAIN_NAME="Chain2" \
		forge script script/CheckBalance.s.sol:CheckBalance \
		--rpc-url $(CHAIN2_RPC_URL)
else ifeq ($(CHAIN),1)
	@cd contract && TOKEN_ADDRESS=$(CHAIN1_TOKEN_ADDRESS) CHECK_ADDRESS=$(ADDRESS) CHAIN_NAME="Chain1" \
		forge script script/CheckBalance.s.sol:CheckBalance \
		--rpc-url $(CHAIN1_RPC_URL)
else ifeq ($(CHAIN),2)
	@cd contract && TOKEN_ADDRESS=$(CHAIN2_TOKEN_ADDRESS) CHECK_ADDRESS=$(ADDRESS) CHAIN_NAME="Chain2" \
		forge script script/CheckBalance.s.sol:CheckBalance \
		--rpc-url $(CHAIN2_RPC_URL)
else
	@echo "Error: CHAIN must be 1, 2, or all"
	@exit 1
endif

# 転送（パラメータ指定可能）
.PHONY: transfer
transfer:
ifeq ($(FROM),1)
ifeq ($(TO),2)
	@echo "Chain1からChain2へトークンを転送中..."
	@echo "宛先アドレス: $(ADDRESS)"
	@echo "転送量: $(TRANSFER_AMOUNT) wei"
	cd contract && TOKEN_ADDRESS=$(CHAIN1_TOKEN_ADDRESS) \
		DESTINATION_CHAIN_ID=$(CHAIN2_BLOCKCHAIN_ID) \
		TRANSFER_TO=$(ADDRESS) \
		TRANSFER_AMOUNT=$(TRANSFER_AMOUNT) \
		forge script script/TransferToken.s.sol:TransferToken \
		--rpc-url $(CHAIN1_RPC_URL) \
		--broadcast \
		--slow
else
	@echo "Error: TO must be 2 when FROM is 1"
	@exit 1
endif
else ifeq ($(FROM),2)
ifeq ($(TO),1)
	@echo "Chain2からChain1へトークンを転送中..."
	@echo "宛先アドレス: $(ADDRESS)"
	@echo "転送量: $(TRANSFER_AMOUNT) wei"
	cd contract && TOKEN_ADDRESS=$(CHAIN2_TOKEN_ADDRESS) \
		DESTINATION_CHAIN_ID=$(CHAIN1_BLOCKCHAIN_ID) \
		TRANSFER_TO=$(ADDRESS) \
		TRANSFER_AMOUNT=$(TRANSFER_AMOUNT) \
		forge script script/TransferToken.s.sol:TransferToken \
		--rpc-url $(CHAIN2_RPC_URL) \
		--broadcast \
		--slow
else
	@echo "Error: TO must be 1 when FROM is 2"
	@exit 1
endif
else
	@echo "Error: FROM must be 1 or 2"
	@exit 1
endif

# クリーン
.PHONY: clean
clean:
	@echo "キャッシュとビルドファイルをクリーン中..."
	cd contract && forge clean