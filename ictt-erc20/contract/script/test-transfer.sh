#!/bin/bash

# =============================================================================
# test-transfer.sh
# トークンのMintとTransferを実行するスクリプト
#
# 使用方法:
#   ./script/test-transfer.sh \
#     --token <TOKEN_ADDRESS> \
#     --home <HOME_ADDRESS> \
#     --remote <REMOTE_ADDRESS> \
#     --remote-blockchain-id <REMOTE_BLOCKCHAIN_ID>
# =============================================================================

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# .envの読み込み
if [ -f .env ]; then
    source .env
fi

# 引数のパース
while [[ $# -gt 0 ]]; do
    case $1 in
        --token)
            TOKEN_ADDRESS="$2"
            shift 2
            ;;
        --home)
            HOME_ADDRESS="$2"
            shift 2
            ;;
        --remote)
            REMOTE_ADDRESS="$2"
            shift 2
            ;;
        --remote-blockchain-id)
            REMOTE_BLOCKCHAIN_ID="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}不明な引数: $1${NC}"
            exit 1
            ;;
    esac
done

# 必須引数のチェック
if [ -z "$TOKEN_ADDRESS" ]; then
    echo -e "${RED}エラー: --token が必要です${NC}"
    exit 1
fi
if [ -z "$HOME_ADDRESS" ]; then
    echo -e "${RED}エラー: --home が必要です${NC}"
    exit 1
fi
if [ -z "$REMOTE_ADDRESS" ]; then
    echo -e "${RED}エラー: --remote が必要です${NC}"
    exit 1
fi
if [ -z "$REMOTE_BLOCKCHAIN_ID" ]; then
    echo -e "${RED}エラー: --remote-blockchain-id が必要です${NC}"
    exit 1
fi
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}エラー: PRIVATE_KEY が.envに設定されていません${NC}"
    exit 1
fi

# 定数
MINT_AMOUNT=100000000000000000000    # 100トークン
SEND_AMOUNT=50000000000000000000     # 50トークン
REQUIRED_GAS_LIMIT=250000
TX_WAIT_TIME=3                        # トランザクション後の待機時間（秒）
ICM_WAIT_TIME=10                      # ICMクロスチェーン待機時間（秒）
REMOTE_MAX_WAIT=60                    # Remote残高確認の最大待機時間（秒）
REMOTE_POLL_INTERVAL=5                # Remote残高確認のポーリング間隔（秒）

# デプロイヤーアドレスを取得
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

# 残高記録用変数
INITIAL_HOME_BALANCE=0
INITIAL_REMOTE_BALANCE=0
AFTER_MINT_HOME_BALANCE=0
AFTER_MINT_REMOTE_BALANCE=0
FINAL_HOME_BALANCE=0
FINAL_REMOTE_BALANCE=0

# =============================================================================
# 関数定義
# =============================================================================

get_balance_home() {
    BALANCE_RAW=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url home 2>/dev/null || echo "0")
    echo $(echo $BALANCE_RAW | awk '{print $1}')
}

get_balance_remote() {
    BALANCE_RAW=$(cast call $REMOTE_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url remote 2>/dev/null || echo "0")
    echo $(echo $BALANCE_RAW | awk '{print $1}')
}

format_balance() {
    local balance=$1
    local ether=$(cast from-wei $balance 2>/dev/null || echo "0")
    echo "$ether"
}

print_balance() {
    local label=$1
    local balance=$2
    local ether=$(format_balance $balance)
    echo -e "  ${label}: ${GREEN}${BOLD}$ether トークン${NC} ${CYAN}($balance wei)${NC}"
}

print_balance_change() {
    local label=$1
    local before=$2
    local after=$3
    local before_ether=$(format_balance $before)
    local after_ether=$(format_balance $after)

    # bcを使用して大きな数値の計算
    local diff=$(echo "$after - $before" | bc 2>/dev/null || echo "0")

    if [ $(echo "$diff > 0" | bc 2>/dev/null || echo "0") -eq 1 ]; then
        local diff_ether=$(format_balance $diff)
        echo -e "  ${label}: ${before_ether} → ${GREEN}${BOLD}${after_ether}${NC} (${GREEN}+${diff_ether}${NC})"
    elif [ $(echo "$diff < 0" | bc 2>/dev/null || echo "0") -eq 1 ]; then
        local abs_diff=$(echo "$diff * -1" | bc 2>/dev/null || echo "0")
        local abs_diff_ether=$(format_balance $abs_diff)
        echo -e "  ${label}: ${before_ether} → ${GREEN}${BOLD}${after_ether}${NC} (${RED}-${abs_diff_ether}${NC})"
    else
        echo -e "  ${label}: ${before_ether} → ${GREEN}${BOLD}${after_ether}${NC} (変化なし)"
    fi
}

print_separator() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_tx_result() {
    local tx_hash=$1
    local label=$2
    echo -e "  ${GREEN}✓${NC} ${label}"
    echo -e "    TX: ${CYAN}${tx_hash}${NC}"
}

wait_for_tx() {
    local seconds=$1
    echo -e "  ${CYAN}状態反映を待機中（${seconds}秒）...${NC}"
    sleep $seconds
}

wait_for_remote_balance() {
    local initial_balance=$1
    local max_wait=$2
    local interval=$3
    local elapsed=0

    echo -e "  ${CYAN}Remote残高の反映を待機中...${NC}" >&2

    while [ $elapsed -lt $max_wait ]; do
        local current_balance=$(get_balance_remote)

        if [ "$current_balance" != "$initial_balance" ]; then
            echo -e "  ${GREEN}✓${NC} 残高が反映されました！" >&2
            echo "$current_balance"
            return 0
        fi

        elapsed=$((elapsed + interval))
        echo -e "    待機中... (${elapsed}/${max_wait}秒)" >&2
        sleep $interval
    done

    echo -e "  ${YELLOW}⚠${NC} タイムアウト（${max_wait}秒経過）" >&2
    echo "$initial_balance"
    return 1
}

# =============================================================================
# メイン処理
# =============================================================================

echo ""
print_separator
echo -e "${YELLOW}${BOLD}  ICTT Transfer 実行スクリプト${NC}"
print_separator
echo ""
echo -e "${BOLD}設定情報${NC}"
echo -e "  デプロイヤー: ${CYAN}$DEPLOYER${NC}"
echo -e "  Token:        ${CYAN}$TOKEN_ADDRESS${NC}"
echo -e "  Home:         ${CYAN}$HOME_ADDRESS${NC}"
echo -e "  Remote:       ${CYAN}$REMOTE_ADDRESS${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 1: 初期残高確認
# -----------------------------------------------------------------------------
print_separator
echo -e "${YELLOW}${BOLD}[Step 1/5] 初期残高確認${NC}"
print_separator
echo ""

INITIAL_HOME_BALANCE=$(get_balance_home)
INITIAL_REMOTE_BALANCE=$(get_balance_remote)

print_balance "Home残高  " $INITIAL_HOME_BALANCE
print_balance "Remote残高" $INITIAL_REMOTE_BALANCE
echo ""

# -----------------------------------------------------------------------------
# Step 2: Mint（100トークン）
# -----------------------------------------------------------------------------
print_separator
echo -e "${YELLOW}${BOLD}[Step 2/5] Mint（100トークン）${NC}"
print_separator
echo ""

echo -e "${BLUE}Mint実行中...${NC}"
TX_OUTPUT=$(cast send $TOKEN_ADDRESS \
    "mint(address,uint256)" \
    $DEPLOYER \
    $MINT_AMOUNT \
    --rpc-url home \
    --private-key $PRIVATE_KEY \
    --json)

TX_HASH=$(echo $TX_OUTPUT | jq -r '.transactionHash')
print_tx_result "$TX_HASH" "Mint完了（100トークン）"
echo ""

wait_for_tx $TX_WAIT_TIME
echo ""

# -----------------------------------------------------------------------------
# Step 3: Mint後の残高確認
# -----------------------------------------------------------------------------
print_separator
echo -e "${YELLOW}${BOLD}[Step 3/5] Mint後の残高確認${NC}"
print_separator
echo ""

AFTER_MINT_HOME_BALANCE=$(get_balance_home)
AFTER_MINT_REMOTE_BALANCE=$(get_balance_remote)

print_balance_change "Home残高  " $INITIAL_HOME_BALANCE $AFTER_MINT_HOME_BALANCE
print_balance_change "Remote残高" $INITIAL_REMOTE_BALANCE $AFTER_MINT_REMOTE_BALANCE
echo ""

# -----------------------------------------------------------------------------
# Step 4: Send（50トークン）
# -----------------------------------------------------------------------------
print_separator
echo -e "${YELLOW}${BOLD}[Step 4/5] Send（50トークン、Home → Remote）${NC}"
print_separator
echo ""

echo -e "${BLUE}1. Approve実行中...${NC}"
TX_OUTPUT=$(cast send $TOKEN_ADDRESS \
    "approve(address,uint256)" \
    $HOME_ADDRESS \
    $SEND_AMOUNT \
    --rpc-url home \
    --private-key $PRIVATE_KEY \
    --json)

TX_HASH=$(echo $TX_OUTPUT | jq -r '.transactionHash')
print_tx_result "$TX_HASH" "Approve完了（50トークン）"
echo ""

wait_for_tx $TX_WAIT_TIME
echo ""

echo -e "${BLUE}2. Send実行中...${NC}"
TX_OUTPUT=$(cast send $HOME_ADDRESS \
    "send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
    "($REMOTE_BLOCKCHAIN_ID,$REMOTE_ADDRESS,$DEPLOYER,$TOKEN_ADDRESS,0,0,$REQUIRED_GAS_LIMIT,0x0000000000000000000000000000000000000000)" \
    $SEND_AMOUNT \
    --rpc-url home \
    --private-key $PRIVATE_KEY \
    --json)

TX_HASH=$(echo $TX_OUTPUT | jq -r '.transactionHash')
print_tx_result "$TX_HASH" "Send完了（50トークン → Remote）"
echo ""

# -----------------------------------------------------------------------------
# Step 5: Send後の残高確認（Remote残高はポーリング）
# -----------------------------------------------------------------------------
print_separator
echo -e "${YELLOW}${BOLD}[Step 5/5] Send後の残高確認${NC}"
print_separator
echo ""

# Home残高はすぐ確認
wait_for_tx $TX_WAIT_TIME
FINAL_HOME_BALANCE=$(get_balance_home)
print_balance_change "Home残高  " $AFTER_MINT_HOME_BALANCE $FINAL_HOME_BALANCE
echo ""

# ICMクロスチェーン処理の待機
echo -e "  ${CYAN}ICMクロスチェーン処理を待機中（${ICM_WAIT_TIME}秒）...${NC}"
sleep $ICM_WAIT_TIME
echo ""

# Remote残高はポーリングで待機
FINAL_REMOTE_BALANCE=$(wait_for_remote_balance $AFTER_MINT_REMOTE_BALANCE $REMOTE_MAX_WAIT $REMOTE_POLL_INTERVAL)
print_balance_change "Remote残高" $AFTER_MINT_REMOTE_BALANCE $FINAL_REMOTE_BALANCE
echo ""

# -----------------------------------------------------------------------------
# 最終サマリー
# -----------------------------------------------------------------------------
print_separator
echo -e "${GREEN}${BOLD}  実行完了！${NC}"
print_separator
echo ""

echo -e "${BOLD}【実行サマリー】${NC}"
echo ""
echo -e "  ${BOLD}Mint:${NC}   100 トークン"
echo -e "  ${BOLD}Send:${NC}   50 トークン (Home → Remote)"
echo ""

echo -e "${BOLD}【残高変化】${NC}"
echo ""
echo -e "  ${BOLD}Home残高:${NC}"
print_balance_change "    初期 → 最終" $INITIAL_HOME_BALANCE $FINAL_HOME_BALANCE
echo ""
echo -e "  ${BOLD}Remote残高:${NC}"
print_balance_change "    初期 → 最終" $INITIAL_REMOTE_BALANCE $FINAL_REMOTE_BALANCE
echo ""

print_separator
echo ""

if [ "$FINAL_REMOTE_BALANCE" == "$AFTER_MINT_REMOTE_BALANCE" ]; then
    echo -e "${YELLOW}⚠ Remote側の残高がまだ反映されていない可能性があります${NC}"
    echo -e "  さらに待ってから以下のコマンドで確認してください:"
    echo ""
    echo -e "  ${CYAN}cast call $REMOTE_ADDRESS \"balanceOf(address)(uint256)\" $DEPLOYER --rpc-url remote${NC}"
    echo ""
fi
