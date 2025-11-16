#!/bin/bash
# mint-and-transfer.sh

set -e

# 色付きメッセージ用の関数
print_step() {
    echo -e "\n\033[1;34m==> $1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✓ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m✗ $1\033[0m"
}

# 設定値
TOKEN_CONTRACT="0x52C84043CD9c865236f11d9Fc9F56aa003c1f922"
USER_ADDRESS="0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC"
PRIVATE_KEY="0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027"
C_CHAIN_RPC="http://127.0.0.1:9650/ext/bc/C/rpc"

# Bridge Addresses
CHAIN1_BRIDGE="0x5aa01b3b5877255ce50cc55e8986a7a5fe29c70e"
CHAIN2_BRIDGE="0x52c84043cd9c865236f11d9fc9f56aa003c1f922"

echo "=========================================="
echo "SimpleERC20Bridge トークン転送ワークフロー"
echo "=========================================="

# ヘルプ表示
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "使用方法: $0 [options]"
    echo ""
    echo "このスクリプトは以下を実行します:"
    echo "1. C-ChainのERC20トークンをmint"
    echo "2. 残高確認"
    echo "3. クロスチェーン転送の準備"
    echo ""
    echo "オプション:"
    echo "  --mint-amount N     mint量を指定（デフォルト: 1000000）"
    echo "  --skip-mint         mintをスキップ"
    echo "  --help, -h          このヘルプを表示"
    echo ""
    echo "設定値:"
    echo "  Token Contract: $TOKEN_CONTRACT"
    echo "  User Address: $USER_ADDRESS"
    echo "  Chain1 Bridge: $CHAIN1_BRIDGE"
    echo "  Chain2 Bridge: $CHAIN2_BRIDGE"
    exit 0
fi

# オプション解析
MINT_AMOUNT="1000000000000000000000000"  # 1,000,000 tokens (18 decimals)
SKIP_MINT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --mint-amount)
            # トークン数をweiに変換
            MINT_AMOUNT=$(echo "$2 * 10^18" | bc)
            shift 2
            ;;
        --skip-mint)
            SKIP_MINT=true
            shift
            ;;
        *)
            print_error "不明なオプション: $1"
            echo "使用方法については --help を参照してください"
            exit 1
            ;;
    esac
done

# 必要なコマンドの確認
if ! command -v cast &> /dev/null; then
    print_error "cast コマンドが見つかりません"
    echo "Foundryをインストールしてください: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

print_step "1. 事前確認"

# RPC接続確認
echo "C-Chain RPC接続確認中..."
if curl -s -X POST -H "Content-Type: application/json" \
   -d '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion"}' \
   $C_CHAIN_RPC | grep -q "result"; then
    print_success "C-Chain RPC接続OK"
else
    print_error "C-Chain RPCに接続できません"
    exit 1
fi

# トークンコントラクト確認
echo "トークンコントラクト確認中..."
TOKEN_NAME=$(cast call $TOKEN_CONTRACT "name()" --rpc-url $C_CHAIN_RPC 2>/dev/null || echo "")
if [ -n "$TOKEN_NAME" ]; then
    print_success "トークンコントラクト確認OK: $TOKEN_NAME"
else
    print_error "トークンコントラクトにアクセスできません"
    exit 1
fi

print_step "2. 初期残高確認"
INITIAL_BALANCE=$(cast call $TOKEN_CONTRACT "balanceOf(address)" $USER_ADDRESS --rpc-url $C_CHAIN_RPC 2>/dev/null || echo "0x0")
INITIAL_BALANCE_FORMATTED=$(cast to-unit $INITIAL_BALANCE ether 2>/dev/null || echo "0")
echo "現在の残高: $INITIAL_BALANCE_FORMATTED tokens"

if [ "$SKIP_MINT" = false ]; then
    print_step "3. トークンMint"
    echo "Mint量: $(cast to-unit $MINT_AMOUNT ether) tokens"
    
    if cast send $TOKEN_CONTRACT \
        "mint(address,uint256)" \
        $USER_ADDRESS \
        $MINT_AMOUNT \
        --rpc-url $C_CHAIN_RPC \
        --private-key $PRIVATE_KEY \
        --gas-limit 100000; then
        print_success "Mint完了"
    else
        print_error "Mintに失敗しました"
        exit 1
    fi
    
    # Mint後の残高確認
    sleep 2
    NEW_BALANCE=$(cast call $TOKEN_CONTRACT "balanceOf(address)" $USER_ADDRESS --rpc-url $C_CHAIN_RPC)
    NEW_BALANCE_FORMATTED=$(cast to-unit $NEW_BALANCE ether)
    echo "Mint後の残高: $NEW_BALANCE_FORMATTED tokens"
else
    print_warning "Mintをスキップしました"
fi

print_step "4. クロスチェーン転送の準備"
echo "以下の情報を使用してavalanhe key transferコマンドを実行してください："
echo ""
echo "コマンド:"
echo "  /Users/cardene/bin/avalanche key transfer --local"
echo ""
echo "対話式プロンプトでの入力値:"
echo "  ✔ Blockchain: chain1"
echo "  ✔ Blockchain: chain2"
echo "  ✔ Token Transferrer on chain1: $CHAIN1_BRIDGE"
echo "  ✔ Token Transferrer on chain2: $CHAIN2_BRIDGE"
echo "  ✔ Private key: Genesis Allocated address を選択"
echo "  ✔ Amount: 転送したい量を入力（例: 1000）"
echo ""

print_step "5. 自動実行（オプション）"
echo "自動で転送コマンドを実行しますか？"
read -p "実行する場合は 'y' を入力してください: " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_warning "対話式プロンプトが表示されます。上記の値を入力してください。"
    sleep 2
    
    if /Users/cardene/bin/avalanche key transfer --local; then
        print_success "転送コマンド完了"
    else
        print_error "転送コマンドでエラーが発生しました"
    fi
else
    echo "手動で以下のコマンドを実行してください:"
    echo "/Users/cardene/bin/avalanche key transfer --local"
fi

print_step "6. 残高確認スクリプト"
echo "転送後の残高確認には以下のスクリプトを使用してください:"
echo "./scripts/check-token-balance.sh --token $TOKEN_CONTRACT --user $USER_ADDRESS"

echo ""
echo "=========================================="
print_success "ワークフロー準備完了！"
echo ""
echo "重要な情報:"
echo "  Token Contract: $TOKEN_CONTRACT"
echo "  Chain1 Bridge: $CHAIN1_BRIDGE"
echo "  Chain2 Bridge: $CHAIN2_BRIDGE"
echo "  User Address: $USER_ADDRESS"
echo ""
echo "次のステップ:"
echo "1. avalanche key transfer --local を実行"
echo "2. 残高確認スクリプトで結果を確認"
echo "3. AWM Relayerログで転送状況を確認"
echo "=========================================="