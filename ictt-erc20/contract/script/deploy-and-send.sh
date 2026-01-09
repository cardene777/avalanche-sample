#!/bin/bash

# =============================================================================
# ICTT デプロイ＆送信スクリプト
# =============================================================================
#
# このスクリプトは以下の処理を自動で行います:
# 1. Fuji側デプロイ（SampleERC20 + TokenHome）
# 2. Fuji側初期化
# 3. Dispatch側デプロイ（TokenRemote）
# 4. Dispatch側初期化
# 5. リモート登録
# 6. トークンミント
# 7. トークン送信
# 8. 残高確認
#
# 使用方法:
#   ./script/deploy-and-send.sh
#   または
#   make deploy-and-send
#
# =============================================================================

set -e  # エラー時に停止

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRACT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$CONTRACT_DIR/.env"

# =============================================================================
# ヘルパー関数
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

# .envファイルに変数を追加または更新する関数
update_env() {
    local key=$1
    local value=$2

    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        # 既存の値を更新（macOS互換）
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
        else
            sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
        fi
        print_info "更新: ${key}"
    else
        # ファイル末尾に改行があるか確認し、なければ追加
        if [ -s "$ENV_FILE" ] && [ "$(tail -c 1 "$ENV_FILE" | wc -l)" -eq 0 ]; then
            echo "" >> "$ENV_FILE"
        fi
        # 新しい値を追加
        echo "${key}=${value}" >> "$ENV_FILE"
        print_info "追加: ${key}"
    fi
}

# =============================================================================
# 前提条件チェック
# =============================================================================

print_header "前提条件チェック"

# .envファイルの存在確認
if [ ! -f "$ENV_FILE" ]; then
    print_error ".envファイルが見つかりません"
    print_info "以下のコマンドを実行してください:"
    echo "  cp .env.example .env"
    echo "  vim .env  # PRIVATE_KEYを設定"
    exit 1
fi

# .envファイルを読み込み
source "$ENV_FILE"

# PRIVATE_KEYの確認
if [ -z "$PRIVATE_KEY" ]; then
    print_error "PRIVATE_KEYが設定されていません"
    print_info ".envファイルにPRIVATE_KEYを設定してください"
    exit 1
fi

print_success "PRIVATE_KEY が設定されています"

# デプロイヤーアドレスを取得
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
print_success "デプロイヤー: $DEPLOYER"

# =============================================================================
# Step 1: Fuji側デプロイ
# =============================================================================

print_header "[1/8] Fuji側デプロイ"

# Blockchain IDを取得
print_info "Blockchain IDを取得中..."
FUJI_BLOCKCHAIN_ID=$(cast call 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" --rpc-url fuji 2>/dev/null)
print_success "Fuji Blockchain ID: $FUJI_BLOCKCHAIN_ID"

# デプロイ実行
print_info "SampleERC20 と TokenHome をデプロイ中..."
DEPLOY_OUTPUT=$(FUJI_BLOCKCHAIN_ID=$FUJI_BLOCKCHAIN_ID forge script script/DeployAll.s.sol:DeployFujiHome \
    --rpc-url fuji \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

# アドレスを抽出
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE "TOKEN_ADDRESS= 0x[a-fA-F0-9]{40}" | awk '{print $2}')
TOKEN_HOME_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE "TOKEN_HOME_ADDRESS= 0x[a-fA-F0-9]{40}" | awk '{print $2}')

if [ -z "$TOKEN_ADDRESS" ] || [ -z "$TOKEN_HOME_ADDRESS" ]; then
    print_error "アドレスの抽出に失敗しました"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

print_success "SampleERC20: $TOKEN_ADDRESS"
print_success "TokenHome: $TOKEN_HOME_ADDRESS"

# .envに保存
update_env "TOKEN_HOME_BLOCKCHAIN_ID" "$FUJI_BLOCKCHAIN_ID"
update_env "TOKEN_ADDRESS" "$TOKEN_ADDRESS"
update_env "TOKEN_HOME_ADDRESS" "$TOKEN_HOME_ADDRESS"

# =============================================================================
# Step 2: Fuji側初期化
# =============================================================================

print_header "[2/8] Fuji側TokenHome初期化"

# .envを再読み込み
source "$ENV_FILE"

TELEPORTER_REGISTRY=${FUJI_TELEPORTER_REGISTRY_ADDRESS:-0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228}
TOKEN_DECIMALS=${TOKEN_DECIMALS:-18}

print_info "TokenHome を初期化中..."
TX_OUTPUT=$(cast send $TOKEN_HOME_ADDRESS \
    "initialize(address,address,uint256,address,uint8)" \
    $TELEPORTER_REGISTRY \
    $DEPLOYER \
    1 \
    $TOKEN_ADDRESS \
    $TOKEN_DECIMALS \
    --rpc-url fuji \
    --private-key $PRIVATE_KEY 2>&1)

TX_HASH=$(echo "$TX_OUTPUT" | grep "transactionHash" | awk '{print $2}')
if [ -n "$TX_HASH" ]; then
    print_success "Tx: https://testnet.snowtrace.io/tx/$TX_HASH"
fi

print_success "TokenHome 初期化完了"

# =============================================================================
# Step 3: Dispatch側デプロイ
# =============================================================================

print_header "[3/8] Dispatch側デプロイ"

# .envを再読み込みしてexport
source "$ENV_FILE"
export TOKEN_HOME_BLOCKCHAIN_ID
export TOKEN_HOME_ADDRESS

# Blockchain IDを取得
print_info "Dispatch Blockchain IDを取得中..."
DISPATCH_BLOCKCHAIN_ID=$(cast call 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" --rpc-url dispatch 2>/dev/null)
print_success "Dispatch Blockchain ID: $DISPATCH_BLOCKCHAIN_ID"

# デプロイ実行
print_info "TokenRemote をデプロイ中..."
DEPLOY_OUTPUT=$(DISPATCH_BLOCKCHAIN_ID=$DISPATCH_BLOCKCHAIN_ID forge script script/DeployAll.s.sol:DeployDispatchRemote \
    --rpc-url dispatch \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

# アドレスを抽出
REMOTE_TOKEN_TRANSFERRER_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE "REMOTE_TOKEN_TRANSFERRER_ADDRESS= 0x[a-fA-F0-9]{40}" | awk '{print $2}')

if [ -z "$REMOTE_TOKEN_TRANSFERRER_ADDRESS" ]; then
    print_error "アドレスの抽出に失敗しました"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

print_success "TokenRemote: $REMOTE_TOKEN_TRANSFERRER_ADDRESS"

# .envに保存
update_env "DISPATCH_BLOCKCHAIN_ID" "$DISPATCH_BLOCKCHAIN_ID"
update_env "REMOTE_TOKEN_TRANSFERRER_ADDRESS" "$REMOTE_TOKEN_TRANSFERRER_ADDRESS"

# =============================================================================
# Step 4: Dispatch側初期化
# =============================================================================

print_header "[4/8] Dispatch側TokenRemote初期化"

# .envを再読み込み
source "$ENV_FILE"

DISPATCH_TELEPORTER_REGISTRY=${DISPATCH_TELEPORTER_REGISTRY_ADDRESS:-0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228}
TOKEN_HOME_DECIMALS=${TOKEN_HOME_DECIMALS:-18}
REMOTE_TOKEN_NAME=${REMOTE_TOKEN_NAME:-"Bridged Token"}
REMOTE_TOKEN_SYMBOL=${REMOTE_TOKEN_SYMBOL:-"bSMPL"}
REMOTE_TOKEN_DECIMALS=${REMOTE_TOKEN_DECIMALS:-18}

print_info "TokenRemote を初期化中..."
TX_OUTPUT=$(cast send $REMOTE_TOKEN_TRANSFERRER_ADDRESS \
    "initialize((address,address,uint256,bytes32,address,uint8),string,string,uint8)" \
    "($DISPATCH_TELEPORTER_REGISTRY,$DEPLOYER,1,$TOKEN_HOME_BLOCKCHAIN_ID,$TOKEN_HOME_ADDRESS,$TOKEN_HOME_DECIMALS)" \
    "$REMOTE_TOKEN_NAME" \
    "$REMOTE_TOKEN_SYMBOL" \
    $REMOTE_TOKEN_DECIMALS \
    --rpc-url dispatch \
    --private-key $PRIVATE_KEY 2>&1)

TX_HASH=$(echo "$TX_OUTPUT" | grep "transactionHash" | awk '{print $2}')
if [ -n "$TX_HASH" ]; then
    print_success "Tx: https://testnet.snowtrace.io/tx/$TX_HASH"
fi

print_success "TokenRemote 初期化完了"

# =============================================================================
# Step 5: リモート登録
# =============================================================================

print_header "[5/8] リモートチェーン登録"

print_info "registerWithHome を実行中..."
TX_OUTPUT=$(cast send $REMOTE_TOKEN_TRANSFERRER_ADDRESS \
    "registerWithHome((address,uint256))" \
    "(0x0000000000000000000000000000000000000000,0)" \
    --rpc-url dispatch \
    --private-key $PRIVATE_KEY 2>&1)

TX_HASH=$(echo "$TX_OUTPUT" | grep "transactionHash" | awk '{print $2}')
if [ -n "$TX_HASH" ]; then
    print_success "Tx: https://testnet.snowtrace.io/tx/$TX_HASH"
fi

print_success "リモート登録リクエスト送信完了"
print_warning "クロスチェーン登録完了まで10秒〜数分かかります"

# 少し待機
print_info "15秒待機中..."
sleep 15

# =============================================================================
# Step 6: トークンミント
# =============================================================================

print_header "[6/8] トークンミント"

MINT_AMOUNT=${MINT_AMOUNT:-100000000000000000000}  # 100 tokens

print_info "トークンをミント中..."
TX_OUTPUT=$(cast send $TOKEN_ADDRESS \
    "mint(address,uint256)" \
    $DEPLOYER \
    $MINT_AMOUNT \
    --rpc-url fuji \
    --private-key $PRIVATE_KEY 2>&1)

TX_HASH=$(echo "$TX_OUTPUT" | grep "transactionHash" | awk '{print $2}')
if [ -n "$TX_HASH" ]; then
    print_success "Tx: https://testnet.snowtrace.io/tx/$TX_HASH"
fi

print_success "ミント完了: $(cast from-wei $MINT_AMOUNT) トークン"

# =============================================================================
# Step 7: トークン送信
# =============================================================================

print_header "[7/8] トークン送信"

SEND_AMOUNT=${SEND_AMOUNT:-1000000000000000000}  # 1 token
REQUIRED_GAS_LIMIT=${REQUIRED_GAS_LIMIT:-250000}

# Approve
print_info "トークンを承認中..."
TX_OUTPUT=$(cast send $TOKEN_ADDRESS \
    "approve(address,uint256)" \
    $TOKEN_HOME_ADDRESS \
    $SEND_AMOUNT \
    --rpc-url fuji \
    --private-key $PRIVATE_KEY 2>&1)

TX_HASH=$(echo "$TX_OUTPUT" | grep "transactionHash" | awk '{print $2}')
if [ -n "$TX_HASH" ]; then
    print_success "Approve Tx: https://testnet.snowtrace.io/tx/$TX_HASH"
fi

# Send
print_info "トークンを送信中..."
TX_OUTPUT=$(cast send $TOKEN_HOME_ADDRESS \
    "send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
    "($DISPATCH_BLOCKCHAIN_ID,$REMOTE_TOKEN_TRANSFERRER_ADDRESS,$DEPLOYER,$TOKEN_ADDRESS,0,0,$REQUIRED_GAS_LIMIT,0x0000000000000000000000000000000000000000)" \
    $SEND_AMOUNT \
    --rpc-url fuji \
    --private-key $PRIVATE_KEY 2>&1)

TX_HASH=$(echo "$TX_OUTPUT" | grep "transactionHash" | awk '{print $2}')
if [ -n "$TX_HASH" ]; then
    print_success "Send Tx: https://testnet.snowtrace.io/tx/$TX_HASH"
fi

print_success "送信完了: $(cast from-wei $SEND_AMOUNT) トークン"
print_warning "クロスチェーンメッセージ処理まで10秒〜数分かかります"

# 少し待機
print_info "20秒待機中..."
sleep 20

# =============================================================================
# Step 8: 残高確認
# =============================================================================

print_header "[8/8] 残高確認"

# Fuji側残高
print_info "Fuji側残高を確認中..."
FUJI_BALANCE_RAW=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url fuji)
FUJI_BALANCE=$(echo $FUJI_BALANCE_RAW | awk '{print $1}')
FUJI_BALANCE_ETH=$(cast from-wei $FUJI_BALANCE)
print_success "Fuji残高: $FUJI_BALANCE_ETH トークン"

# Dispatch側残高
print_info "Dispatch側残高を確認中..."
DISPATCH_BALANCE_RAW=$(cast call $REMOTE_TOKEN_TRANSFERRER_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url dispatch)
DISPATCH_BALANCE=$(echo $DISPATCH_BALANCE_RAW | awk '{print $1}')
DISPATCH_BALANCE_ETH=$(cast from-wei $DISPATCH_BALANCE)
print_success "Dispatch残高: $DISPATCH_BALANCE_ETH トークン"

# =============================================================================
# 完了
# =============================================================================

print_header "デプロイ完了！"

echo "デプロイされたコントラクト:"
echo "  - SampleERC20 (Fuji): $TOKEN_ADDRESS"
echo "  - TokenHome (Fuji): $TOKEN_HOME_ADDRESS"
echo "  - TokenRemote (Dispatch): $REMOTE_TOKEN_TRANSFERRER_ADDRESS"
echo ""
echo ".envファイルが自動更新されました"
echo ""
echo "次のステップ:"
echo "  - make balance-fuji      # Fuji側残高確認"
echo "  - make balance-dispatch  # Dispatch側残高確認"
echo "  - make send AMOUNT=...   # 追加送信"
echo ""

print_success "全ての処理が完了しました！"
