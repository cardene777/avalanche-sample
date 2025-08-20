#!/bin/bash
# check-token-balance.sh

# 設定値（実際の値に置換してください）
TOKEN_CONTRACT="0x52C84043CD9c865236f11d9fc9f56aa003c1f922"  # C-ChainのERC20アドレス
USER_ADDRESS="0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC"
RPC_URL_C_CHAIN="http://127.0.0.1:9650/ext/bc/C/rpc"
RPC_URL_CHAIN1="http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/rpc"
RPC_URL_CHAIN2="http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/rpc"

# Remote Tokenアドレス（ICTTデプロイ時に取得）
REMOTE_TOKEN_CHAIN1=""  # 実際のアドレスに置換
REMOTE_TOKEN_CHAIN2=""  # 実際のアドレスに置換

echo "=========================================="
echo "トークン残高確認ツール"
echo "=========================================="

# 引数チェック
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "使用方法: $0 [options]"
    echo ""
    echo "オプション:"
    echo "  --token ADDRESS      トークンコントラクトアドレス指定"
    echo "  --user ADDRESS       ユーザーアドレス指定"
    echo "  --remote1 ADDRESS    Chain1のRemote Tokenアドレス指定"
    echo "  --remote2 ADDRESS    Chain2のRemote Tokenアドレス指定"
    echo "  --help, -h           このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0"
    echo "  $0 --token 0x123... --user 0xabc..."
    exit 0
fi

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --token)
            TOKEN_CONTRACT="$2"
            shift 2
            ;;
        --user)
            USER_ADDRESS="$2"
            shift 2
            ;;
        --remote1)
            REMOTE_TOKEN_CHAIN1="$2"
            shift 2
            ;;
        --remote2)
            REMOTE_TOKEN_CHAIN2="$2"
            shift 2
            ;;
        *)
            echo "不明なオプション: $1"
            exit 1
            ;;
    esac
done

# 必要なコマンドの確認
if ! command -v cast &> /dev/null; then
    echo "エラー: cast コマンドが見つかりません"
    echo "Foundryをインストールしてください: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

echo "対象アドレス: $USER_ADDRESS"
echo "トークンコントラクト: $TOKEN_CONTRACT"
echo ""

# トークン基本情報の確認
echo "1. トークン基本情報:"
echo -n "  Name: "
NAME=$(cast call $TOKEN_CONTRACT "name()" --rpc-url $RPC_URL_C_CHAIN 2>/dev/null || echo "取得失敗")
echo "$NAME"

echo -n "  Symbol: "
SYMBOL=$(cast call $TOKEN_CONTRACT "symbol()" --rpc-url $RPC_URL_C_CHAIN 2>/dev/null || echo "取得失敗")
echo "$SYMBOL"

echo -n "  Decimals: "
DECIMALS=$(cast call $TOKEN_CONTRACT "decimals()" --rpc-url $RPC_URL_C_CHAIN 2>/dev/null || echo "18")
echo "$DECIMALS"

echo ""
echo "2. 各チェーンでの残高:"

# C-Chainでの残高確認
echo "C-Chain:"
BALANCE_C=$(cast call $TOKEN_CONTRACT "balanceOf(address)" $USER_ADDRESS --rpc-url $RPC_URL_C_CHAIN 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  Raw Balance: $BALANCE_C"
    if [ "$BALANCE_C" != "0x0" ] && [ "$BALANCE_C" != "" ]; then
        BALANCE_FORMATTED=$(cast to-unit $BALANCE_C ether 2>/dev/null || echo "変換失敗")
        echo "  Formatted: $BALANCE_FORMATTED tokens"
    else
        echo "  Formatted: 0 tokens"
    fi
else
    echo "  残高取得失敗 - RPC接続またはコントラクトアドレスを確認してください"
fi

# Chain1での残高確認（Remote Tokenが設定されている場合）
echo ""
echo "Chain1:"
if [ -n "$REMOTE_TOKEN_CHAIN1" ]; then
    BALANCE_CHAIN1=$(cast call $REMOTE_TOKEN_CHAIN1 "balanceOf(address)" $USER_ADDRESS --rpc-url $RPC_URL_CHAIN1 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "  Raw Balance: $BALANCE_CHAIN1"
        if [ "$BALANCE_CHAIN1" != "0x0" ] && [ "$BALANCE_CHAIN1" != "" ]; then
            BALANCE_FORMATTED=$(cast to-unit $BALANCE_CHAIN1 ether 2>/dev/null || echo "変換失敗")
            echo "  Formatted: $BALANCE_FORMATTED tokens"
        else
            echo "  Formatted: 0 tokens"
        fi
    else
        echo "  残高取得失敗 - RPC接続またはコントラクトアドレスを確認してください"
    fi
else
    echo "  Remote Tokenアドレスが設定されていません"
    echo "  使用方法: $0 --remote1 [REMOTE_TOKEN_ADDRESS]"
fi

# Chain2での残高確認（Remote Tokenが設定されている場合）
echo ""
echo "Chain2:"
if [ -n "$REMOTE_TOKEN_CHAIN2" ]; then
    BALANCE_CHAIN2=$(cast call $REMOTE_TOKEN_CHAIN2 "balanceOf(address)" $USER_ADDRESS --rpc-url $RPC_URL_CHAIN2 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "  Raw Balance: $BALANCE_CHAIN2"
        if [ "$BALANCE_CHAIN2" != "0x0" ] && [ "$BALANCE_CHAIN2" != "" ]; then
            BALANCE_FORMATTED=$(cast to-unit $BALANCE_CHAIN2 ether 2>/dev/null || echo "変換失敗")
            echo "  Formatted: $BALANCE_FORMATTED tokens"
        else
            echo "  Formatted: 0 tokens"
        fi
    else
        echo "  残高取得失敗 - RPC接続またはコントラクトアドレスを確認してください"
    fi
else
    echo "  Remote Tokenアドレスが設定されていません"
    echo "  使用方法: $0 --remote2 [REMOTE_TOKEN_ADDRESS]"
fi

echo ""
echo "=========================================="
echo "確認完了!"
echo ""
echo "注意事項:"
echo "- Remote Tokenアドレスは avalanche ictt describe --local で確認できます"
echo "- 残高が0の場合は、まずトークンをmintしてください"
echo "- RPC接続エラーの場合は、ノードの起動状況を確認してください"
echo "=========================================="