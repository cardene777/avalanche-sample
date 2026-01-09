.PHONY: help install build test clean deploy-fuji initialize-fuji deploy-dispatch initialize-dispatch register-remote mint send balance deploy-and-send

# デフォルトターゲット
help:
	@echo "====================================="
	@echo "ICTT ERC20 Makefile Commands"
	@echo "====================================="
	@echo ""
	@echo "セットアップ:"
	@echo "  make install           - 依存関係をインストール"
	@echo "  make build             - コントラクトをビルド"
	@echo "  make test              - テストを実行"
	@echo ""
	@echo "デプロイ:"
	@echo "  make deploy-fuji       - Fuji側のコントラクトをデプロイ（SampleERC20 + TokenHome）"
	@echo "  make initialize-fuji   - Fuji側のTokenHomeを初期化"
	@echo "  make deploy-dispatch   - Dispatch側のコントラクトをデプロイ（TokenRemote）"
	@echo "  make initialize-dispatch - Dispatch側のTokenRemoteを初期化"
	@echo "  make register-remote   - Dispatch TestnetをFuji側に登録"
	@echo ""
	@echo "トークン操作:"
	@echo "  make mint              - トークンをミント（AMOUNT=100）"
	@echo "  make send              - トークンを送信（AMOUNT=1）"
	@echo "  make balance-fuji      - Fuji側の残高確認"
	@echo "  make balance-dispatch  - Dispatch側の残高確認"
	@echo ""
	@echo "ユーティリティ:"
	@echo "  make clean             - ビルド成果物を削除"
	@echo "  make fmt               - コードフォーマット"
	@echo ""
	@echo "統合コマンド（推奨）:"
	@echo "  make deploy-and-send     - デプロイから送信まで全自動実行"
	@echo ""
	@echo "使用例（統合版）:"
	@echo "  make deploy-and-send"
	@echo ""
	@echo "使用例（従来版）:"
	@echo "  make deploy-fuji"
	@echo "  make initialize-fuji"
	@echo "  make deploy-dispatch"
	@echo "  make initialize-dispatch"
	@echo "  make register-remote"
	@echo "  make mint AMOUNT=100"
	@echo "  make send AMOUNT=1 RECIPIENT=0x..."
	@echo ""

# 環境変数の読み込み
-include .env
export

# デフォルト値
AMOUNT ?= 1000000000000000000
MINT_AMOUNT ?= 100000000000000000000

# ===================================
# セットアップ
# ===================================

install:
	@echo "依存関係をインストール中..."
	forge install

build:
	@echo "コントラクトをビルド中..."
	forge build

test:
	@echo "テストを実行中..."
	forge test -vv

clean:
	@echo "ビルド成果物を削除中..."
	forge clean

fmt:
	@echo "コードをフォーマット中..."
	forge fmt

# ===================================
# デプロイ
# ===================================

deploy-fuji:
	@echo "====================================="
	@echo "Fuji側デプロイ開始"
	@echo "====================================="
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "エラー: PRIVATE_KEYが設定されていません"; \
		echo ".envファイルを作成してPRIVATE_KEYを設定してください"; \
		exit 1; \
	fi
	@echo ""
	@echo "Blockchain IDを取得中..."
	@FUJI_BLOCKCHAIN_ID=$$(cast call 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" --rpc-url fuji 2>/dev/null); \
	FUJI_BLOCKCHAIN_ID=$$FUJI_BLOCKCHAIN_ID forge script script/DeployAll.s.sol:DeployFujiHome \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY) \
		--broadcast

initialize-fuji:
	@echo "====================================="
	@echo "Fuji側TokenHome初期化"
	@echo "====================================="
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "エラー: PRIVATE_KEYが設定されていません"; \
		exit 1; \
	fi
	@if [ -z "$(TOKEN_HOME_ADDRESS)" ] || [ -z "$(TOKEN_ADDRESS)" ]; then \
		echo "エラー: TOKEN_HOME_ADDRESSとTOKEN_ADDRESSが必要です"; \
		echo "先にmake deploy-fujiを実行してください"; \
		exit 1; \
	fi
	@TELEPORTER_REGISTRY=$${FUJI_TELEPORTER_REGISTRY_ADDRESS:-0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228}; \
	DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	TOKEN_DECIMALS=$${TOKEN_DECIMALS:-18}; \
	echo "Token Home Address: $(TOKEN_HOME_ADDRESS)"; \
	echo "Teleporter Registry: $$TELEPORTER_REGISTRY"; \
	echo "Teleporter Manager: $$DEPLOYER"; \
	echo "Token Address: $(TOKEN_ADDRESS)"; \
	echo "Token Decimals: $$TOKEN_DECIMALS"; \
	echo ""; \
	TX_OUTPUT=$$(cast send $(TOKEN_HOME_ADDRESS) \
		"initialize(address,address,uint256,address,uint8)" \
		$$TELEPORTER_REGISTRY \
		$$DEPLOYER \
		1 \
		$(TOKEN_ADDRESS) \
		$$TOKEN_DECIMALS \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY) 2>&1); \
	TX_HASH=$$(echo "$$TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
	if [ -n "$$TX_HASH" ]; then \
		echo "Tx: https://testnet.snowtrace.io/tx/$$TX_HASH"; \
	fi
	@echo ""
	@echo "====================================="
	@echo "初期化完了！"
	@echo "====================================="

deploy-dispatch:
	@echo "====================================="
	@echo "Dispatch側デプロイ開始"
	@echo "====================================="
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "エラー: PRIVATE_KEYが設定されていません"; \
		exit 1; \
	fi
	@if [ -z "$(TOKEN_HOME_BLOCKCHAIN_ID)" ] || [ -z "$(TOKEN_HOME_ADDRESS)" ]; then \
		echo "エラー: TOKEN_HOME_BLOCKCHAIN_IDとTOKEN_HOME_ADDRESSが必要です"; \
		echo "先にmake deploy-fujiを実行してください"; \
		exit 1; \
	fi
	@echo ""
	@echo "Blockchain IDを取得中..."
	@DISPATCH_BLOCKCHAIN_ID=$$(cast call 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" --rpc-url dispatch 2>/dev/null); \
	DISPATCH_BLOCKCHAIN_ID=$$DISPATCH_BLOCKCHAIN_ID forge script script/DeployAll.s.sol:DeployDispatchRemote \
		--rpc-url dispatch \
		--private-key $(PRIVATE_KEY) \
		--broadcast

initialize-dispatch:
	@echo "====================================="
	@echo "Dispatch側TokenRemote初期化"
	@echo "====================================="
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "エラー: PRIVATE_KEYが設定されていません"; \
		exit 1; \
	fi
	@if [ -z "$(REMOTE_TOKEN_TRANSFERRER_ADDRESS)" ] || [ -z "$(TOKEN_HOME_BLOCKCHAIN_ID)" ] || [ -z "$(TOKEN_HOME_ADDRESS)" ]; then \
		echo "エラー: REMOTE_TOKEN_TRANSFERRER_ADDRESS、TOKEN_HOME_BLOCKCHAIN_ID、TOKEN_HOME_ADDRESSが必要です"; \
		echo "先にmake deploy-fujiとmake deploy-dispatchを実行してください"; \
		exit 1; \
	fi
	@TELEPORTER_REGISTRY=$${DISPATCH_TELEPORTER_REGISTRY_ADDRESS:-0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228}; \
	DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	TOKEN_HOME_DECIMALS=$${TOKEN_HOME_DECIMALS:-18}; \
	REMOTE_TOKEN_NAME=$${REMOTE_TOKEN_NAME:-"Bridged Token"}; \
	REMOTE_TOKEN_SYMBOL=$${REMOTE_TOKEN_SYMBOL:-"bSMPL"}; \
	REMOTE_TOKEN_DECIMALS=$${REMOTE_TOKEN_DECIMALS:-18}; \
	echo "Remote Token Transferrer Address: $(REMOTE_TOKEN_TRANSFERRER_ADDRESS)"; \
	echo "Teleporter Registry: $$TELEPORTER_REGISTRY"; \
	echo "Teleporter Manager: $$DEPLOYER"; \
	echo "Token Home Blockchain ID: $(TOKEN_HOME_BLOCKCHAIN_ID)"; \
	echo "Token Home Address: $(TOKEN_HOME_ADDRESS)"; \
	echo "Token Home Decimals: $$TOKEN_HOME_DECIMALS"; \
	echo "Remote Token Name: $$REMOTE_TOKEN_NAME"; \
	echo "Remote Token Symbol: $$REMOTE_TOKEN_SYMBOL"; \
	echo "Remote Token Decimals: $$REMOTE_TOKEN_DECIMALS"; \
	echo ""; \
	TX_OUTPUT=$$(cast send $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) \
		"initialize((address,address,uint256,bytes32,address,uint8),string,string,uint8)" \
		"($$TELEPORTER_REGISTRY,$$DEPLOYER,1,$(TOKEN_HOME_BLOCKCHAIN_ID),$(TOKEN_HOME_ADDRESS),$$TOKEN_HOME_DECIMALS)" \
		"$$REMOTE_TOKEN_NAME" \
		"$$REMOTE_TOKEN_SYMBOL" \
		$$REMOTE_TOKEN_DECIMALS \
		--rpc-url dispatch \
		--private-key $(PRIVATE_KEY) 2>&1); \
	TX_HASH=$$(echo "$$TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
	if [ -n "$$TX_HASH" ]; then \
		echo "Tx: https://testnet.snowtrace.io/tx/$$TX_HASH"; \
	fi
	@echo ""
	@echo "====================================="
	@echo "初期化完了！"
	@echo "====================================="

register-remote:
	@echo "====================================="
	@echo "リモートチェーン登録"
	@echo "====================================="
	@if [ -z "$(REMOTE_TOKEN_TRANSFERRER_ADDRESS)" ]; then \
		echo "エラー: REMOTE_TOKEN_TRANSFERRER_ADDRESSが必要です"; \
		echo "先にmake deploy-dispatchを実行してください"; \
		exit 1; \
	fi
	@echo "TokenRemoteの初期化を確認中..."
	@TOKEN_NAME=$$(cast call $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) "name()(string)" --rpc-url dispatch 2>/dev/null); \
	if [ -z "$$TOKEN_NAME" ]; then \
		echo ""; \
		echo "❌ エラー: TokenRemoteが初期化されていません"; \
		echo ""; \
		echo "先に以下のコマンドを実行してください:"; \
		echo "  make initialize-dispatch"; \
		echo ""; \
		exit 1; \
	else \
		echo "✓ TokenRemoteは初期化済みです"; \
	fi
	@echo ""
	@echo "リモート登録実行中..."
	@REGISTRATION_FEE=$${REGISTRATION_FEE:-0}; \
	FEE_TOKEN_ADDRESS=$${FEE_TOKEN_ADDRESS:-0x0000000000000000000000000000000000000000}; \
	echo "Registration Fee: $$REGISTRATION_FEE"; \
	echo "Fee Token Address: $$FEE_TOKEN_ADDRESS"; \
	echo ""; \
	TX_OUTPUT=$$(cast send $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) \
		"registerWithHome((address,uint256))" \
		"($$FEE_TOKEN_ADDRESS,$$REGISTRATION_FEE)" \
		--rpc-url dispatch \
		--private-key $(PRIVATE_KEY) 2>&1); \
	TX_HASH=$$(echo "$$TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
	if [ -n "$$TX_HASH" ]; then \
		echo "Tx: https://testnet.snowtrace.io/tx/$$TX_HASH"; \
	fi
	@echo ""
	@echo "====================================="
	@echo "リモートチェーン登録完了！"
	@echo "====================================="

# ===================================
# トークン操作
# ===================================

mint:
	@echo "====================================="
	@echo "トークンをミント"
	@echo "====================================="
	@if [ -z "$(TOKEN_ADDRESS)" ]; then \
		echo "エラー: TOKEN_ADDRESSが設定されていません"; \
		exit 1; \
	fi
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	echo "ミント先: $$DEPLOYER"; \
	echo "ミント量: $(MINT_AMOUNT) wei"; \
	echo ""; \
	TX_OUTPUT=$$(cast send $(TOKEN_ADDRESS) \
		"mint(address,uint256)" \
		$$DEPLOYER \
		$(MINT_AMOUNT) \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY) 2>&1); \
	TX_HASH=$$(echo "$$TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
	if [ -n "$$TX_HASH" ]; then \
		echo "Tx: https://testnet.snowtrace.io/tx/$$TX_HASH"; \
	fi
	@echo ""
	@echo "ミント完了！"

send:
	@echo "====================================="
	@echo "トークンを送信"
	@echo "====================================="
	@if [ -z "$(TOKEN_HOME_ADDRESS)" ] || [ -z "$(REMOTE_TOKEN_TRANSFERRER_ADDRESS)" ] || [ -z "$(TOKEN_ADDRESS)" ] || [ -z "$(DISPATCH_BLOCKCHAIN_ID)" ]; then \
		echo "エラー: 必要なアドレスが設定されていません"; \
		exit 1; \
	fi
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	RECIPIENT_ADDR=$${RECIPIENT:-$$DEPLOYER}; \
	PRIMARY_FEE=$${PRIMARY_FEE:-0}; \
	SECONDARY_FEE=$${SECONDARY_FEE:-0}; \
	REQUIRED_GAS_LIMIT=$${REQUIRED_GAS_LIMIT:-250000}; \
	PRIMARY_FEE_TOKEN_ADDRESS=$${PRIMARY_FEE_TOKEN_ADDRESS:-$(TOKEN_ADDRESS)}; \
	MULTI_HOP_FALLBACK=$${MULTI_HOP_FALLBACK:-0x0000000000000000000000000000000000000000}; \
	echo "送信量: $(AMOUNT) wei"; \
	echo "受取人: $$RECIPIENT_ADDR"; \
	echo ""; \
	if [ "$$PRIMARY_FEE_TOKEN_ADDRESS" = "$(TOKEN_ADDRESS)" ] && [ $$PRIMARY_FEE -gt 0 ]; then \
		APPROVE_AMOUNT=$$(($(AMOUNT) + $$PRIMARY_FEE)); \
	else \
		APPROVE_AMOUNT=$(AMOUNT); \
	fi; \
	echo "トークン承認中..."; \
	echo "Approve Amount: $$APPROVE_AMOUNT wei"; \
	APPROVE_TX_OUTPUT=$$(cast send $(TOKEN_ADDRESS) \
		"approve(address,uint256)" \
		$(TOKEN_HOME_ADDRESS) \
		$$APPROVE_AMOUNT \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY) 2>&1); \
	APPROVE_TX_HASH=$$(echo "$$APPROVE_TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
	if [ -n "$$APPROVE_TX_HASH" ]; then \
		echo "Approve Tx: https://testnet.snowtrace.io/tx/$$APPROVE_TX_HASH"; \
	fi; \
	if [ "$$PRIMARY_FEE_TOKEN_ADDRESS" != "$(TOKEN_ADDRESS)" ] && [ $$PRIMARY_FEE -gt 0 ]; then \
		echo "Fee Token Approve: $$PRIMARY_FEE wei"; \
		FEE_APPROVE_TX_OUTPUT=$$(cast send $$PRIMARY_FEE_TOKEN_ADDRESS \
			"approve(address,uint256)" \
			$(TOKEN_HOME_ADDRESS) \
			$$PRIMARY_FEE \
			--rpc-url fuji \
			--private-key $(PRIVATE_KEY) 2>&1); \
		FEE_APPROVE_TX_HASH=$$(echo "$$FEE_APPROVE_TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
		if [ -n "$$FEE_APPROVE_TX_HASH" ]; then \
			echo "Fee Approve Tx: https://testnet.snowtrace.io/tx/$$FEE_APPROVE_TX_HASH"; \
		fi; \
	fi; \
	echo "承認完了"; \
	echo ""; \
	echo "トークン送信実行中..."; \
	SEND_TX_OUTPUT=$$(cast send $(TOKEN_HOME_ADDRESS) \
		"send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
		"($(DISPATCH_BLOCKCHAIN_ID),$(REMOTE_TOKEN_TRANSFERRER_ADDRESS),$$RECIPIENT_ADDR,$$PRIMARY_FEE_TOKEN_ADDRESS,$$PRIMARY_FEE,$$SECONDARY_FEE,$$REQUIRED_GAS_LIMIT,$$MULTI_HOP_FALLBACK)" \
		$(AMOUNT) \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY) 2>&1); \
	SEND_TX_HASH=$$(echo "$$SEND_TX_OUTPUT" | grep "transactionHash" | awk '{print $$2}'); \
	if [ -n "$$SEND_TX_HASH" ]; then \
		echo "Send Tx: https://testnet.snowtrace.io/tx/$$SEND_TX_HASH"; \
	fi
	@echo ""
	@echo "====================================="
	@echo "トークン送信完了！"
	@echo "数秒〜数分待ってからmake balance-dispatchで確認してください"
	@echo "====================================="

balance-fuji:
	@echo "====================================="
	@echo "Fuji側の残高確認"
	@echo "====================================="
	@if [ -z "$(TOKEN_ADDRESS)" ]; then \
		echo "エラー: TOKEN_ADDRESSが設定されていません"; \
		exit 1; \
	fi
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	ADDR=$${ADDRESS:-$$DEPLOYER}; \
	echo "確認するアドレス: $$ADDR"; \
	echo ""; \
	BALANCE_RAW=$$(cast call $(TOKEN_ADDRESS) "balanceOf(address)(uint256)" $$ADDR --rpc-url fuji); \
	BALANCE=$$(echo $$BALANCE_RAW | awk '{print $$1}'); \
	echo "残高: $$BALANCE wei"; \
	BALANCE_ETHER=$$(cast to-unit $$BALANCE ether); \
	echo "残高: $$BALANCE_ETHER トークン"

balance-dispatch:
	@echo "====================================="
	@echo "Dispatch側の残高確認"
	@echo "====================================="
	@if [ -z "$(REMOTE_TOKEN_TRANSFERRER_ADDRESS)" ]; then \
		echo "エラー: REMOTE_TOKEN_TRANSFERRER_ADDRESSが設定されていません"; \
		exit 1; \
	fi
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	ADDR=$${ADDRESS:-$$DEPLOYER}; \
	echo "確認するアドレス: $$ADDR"; \
	echo ""; \
	BALANCE_RAW=$$(cast call $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) "balanceOf(address)(uint256)" $$ADDR --rpc-url dispatch); \
	BALANCE=$$(echo $$BALANCE_RAW | awk '{print $$1}'); \
	echo "残高: $$BALANCE wei"; \
	BALANCE_ETHER=$$(cast to-unit $$BALANCE ether); \
	echo "残高: $$BALANCE_ETHER トークン"

# ===================================
# 開発用
# ===================================

# 個別デプロイ（上級者向け）
deploy-token-home:
	forge script script/DeployTokenHome.s.sol:DeployTokenHome \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv

deploy-token-remote:
	forge script script/DeployTokenRemote.s.sol:DeployTokenRemote \
		--rpc-url dispatch \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv

# ===================================
# 統合コマンド（推奨）
# ===================================

deploy-and-send:
	@echo "====================================="
	@echo "デプロイから送信まで全自動実行"
	@echo "====================================="
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "エラー: PRIVATE_KEYが設定されていません"; \
		exit 1; \
	fi
	@bash script/deploy-and-send.sh
