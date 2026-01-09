.PHONY: help install build test clean deploy-fuji initialize-fuji deploy-dispatch initialize-dispatch register-remote mint send balance-fuji balance-dispatch deploy-and-send fmt

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
	@echo "  make deploy-fuji       - Fuji側のコントラクトをデプロイ"
	@echo "  make initialize-fuji   - Fuji側のTokenHomeを初期化"
	@echo "  make deploy-dispatch   - Dispatch側のコントラクトをデプロイ"
	@echo "  make initialize-dispatch - Dispatch側のTokenRemoteを初期化"
	@echo "  make register-remote   - TokenRemoteをTokenHomeに登録"
	@echo ""
	@echo "トークン操作:"
	@echo "  make mint              - トークンをミント（デフォルト100トークン）"
	@echo "  make send              - トークンを送信（デフォルト1トークン）"
	@echo "  make balance-fuji      - Fuji側の残高確認"
	@echo "  make balance-dispatch  - Dispatch側の残高確認"
	@echo ""
	@echo "ユーティリティ:"
	@echo "  make clean             - ビルド成果物を削除"
	@echo "  make fmt               - コードフォーマット"
	@echo ""
	@echo "統合コマンド（推奨）:"
	@echo "  make deploy-and-send   - デプロイから送信まで全自動実行"
	@echo ""

# 環境変数の読み込み
-include .env
export

# デフォルト値
SEND_AMOUNT ?= 1000000000000000000
REQUIRED_GAS_LIMIT ?= 250000

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
# デプロイ（forge script）
# ===================================

deploy-fuji:
	@echo "====================================="
	@echo "Fuji側デプロイ"
	@echo "====================================="
	forge script script/Deploy.s.sol:DeployFujiHome --rpc-url fuji --broadcast

deploy-dispatch:
	@echo "====================================="
	@echo "Dispatch側デプロイ"
	@echo "====================================="
	forge script script/Deploy.s.sol:DeployDispatchRemote --rpc-url dispatch --broadcast

# ===================================
# 初期化・登録（cast send）
# ===================================

initialize-fuji:
	@echo "====================================="
	@echo "Fuji側TokenHome初期化"
	@echo "====================================="
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	cast send $(TOKEN_HOME_ADDRESS) \
		"initialize(address,address,uint256,address,uint8)" \
		0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228 \
		$$DEPLOYER \
		1 \
		$(TOKEN_ADDRESS) \
		18 \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY)
	@echo "初期化完了"

initialize-dispatch:
	@echo "====================================="
	@echo "Dispatch側TokenRemote初期化"
	@echo "====================================="
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	cast send $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) \
		"initialize((address,address,uint256,bytes32,address,uint8),string,string,uint8)" \
		"(0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228,$$DEPLOYER,1,$(TOKEN_HOME_BLOCKCHAIN_ID),$(TOKEN_HOME_ADDRESS),18)" \
		"Bridged Token" \
		"bSMPL" \
		18 \
		--rpc-url dispatch \
		--private-key $(PRIVATE_KEY)
	@echo "初期化完了"

register-remote:
	@echo "====================================="
	@echo "リモート登録"
	@echo "====================================="
	cast send $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) \
		"registerWithHome((address,uint256))" \
		"(0x0000000000000000000000000000000000000000,0)" \
		--rpc-url dispatch \
		--private-key $(PRIVATE_KEY)
	@echo "登録リクエスト送信完了"
	@echo "※クロスチェーン登録完了まで10秒〜数分かかります"

# ===================================
# トークン操作
# ===================================

mint:
	@echo "====================================="
	@echo "トークンミント"
	@echo "====================================="
	forge script script/Token.s.sol:MintToken --rpc-url fuji --broadcast

send:
	@echo "====================================="
	@echo "トークン送信"
	@echo "====================================="
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	echo "1. トークン承認中..."; \
	cast send $(TOKEN_ADDRESS) \
		"approve(address,uint256)" \
		$(TOKEN_HOME_ADDRESS) \
		$(SEND_AMOUNT) \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY); \
	echo "2. トークン送信中..."; \
	cast send $(TOKEN_HOME_ADDRESS) \
		"send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
		"($(DISPATCH_BLOCKCHAIN_ID),$(REMOTE_TOKEN_TRANSFERRER_ADDRESS),$$DEPLOYER,$(TOKEN_ADDRESS),0,0,$(REQUIRED_GAS_LIMIT),0x0000000000000000000000000000000000000000)" \
		$(SEND_AMOUNT) \
		--rpc-url fuji \
		--private-key $(PRIVATE_KEY)
	@echo "送信完了"
	@echo "※クロスチェーンメッセージ処理まで10秒〜数分かかります"

balance-fuji:
	@echo "====================================="
	@echo "Fuji側の残高確認"
	@echo "====================================="
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	BALANCE_RAW=$$(cast call $(TOKEN_ADDRESS) "balanceOf(address)(uint256)" $$DEPLOYER --rpc-url fuji); \
	BALANCE=$$(echo $$BALANCE_RAW | awk '{print $$1}'); \
	echo "残高: $$BALANCE wei"; \
	BALANCE_ETHER=$$(cast from-wei $$BALANCE); \
	echo "残高: $$BALANCE_ETHER トークン"

balance-dispatch:
	@echo "====================================="
	@echo "Dispatch側の残高確認"
	@echo "====================================="
	@DEPLOYER=$$(cast wallet address --private-key $(PRIVATE_KEY)); \
	BALANCE_RAW=$$(cast call $(REMOTE_TOKEN_TRANSFERRER_ADDRESS) "balanceOf(address)(uint256)" $$DEPLOYER --rpc-url dispatch); \
	BALANCE=$$(echo $$BALANCE_RAW | awk '{print $$1}'); \
	echo "残高: $$BALANCE wei"; \
	BALANCE_ETHER=$$(cast from-wei $$BALANCE); \
	echo "残高: $$BALANCE_ETHER トークン"

# ===================================
# 統合コマンド
# ===================================

deploy-and-send:
	@echo "====================================="
	@echo "デプロイから送信まで全自動実行"
	@echo "====================================="
	@bash script/deploy-and-send.sh
