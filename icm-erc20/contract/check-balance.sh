#!/bin/bash

# 環境変数を読み込む
source .env

# デフォルト値
ACCOUNT="${ACCOUNT:-0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC}"

echo "=== Balance Check ==="
echo "Account: $ACCOUNT"
echo ""

# 残高を初期化
BALANCE1="0"
BALANCE2="0"

# Chain1の残高を確認
if [ -n "$CHAIN1_TOKEN_ADDRESS" ] && [ -n "$CHAIN1_RPC_URL" ]; then
    BALANCE1_RAW=$(cast call "$CHAIN1_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$ACCOUNT" --rpc-url "$CHAIN1_RPC_URL" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$BALANCE1_RAW" ]; then
        # castの出力から数値部分のみを抽出（[1e21]のような表記を除去）
        BALANCE1=$(echo "$BALANCE1_RAW" | sed 's/\[.*\]//g' | tr -d ' ')
        if [ "$BALANCE1" != "0" ]; then
            BALANCE1_ETHER=$(echo "scale=2; $BALANCE1 / 1000000000000000000" | bc 2>/dev/null || echo "0")
        else
            BALANCE1_ETHER="0"
        fi
        echo "Chain1 Balance: $BALANCE1_ETHER tokens"
    else
        echo "Chain1 Balance: Error fetching balance"
        BALANCE1="0"
    fi
else
    echo "Chain1: Not configured"
fi

# Chain2の残高を確認
if [ -n "$CHAIN2_TOKEN_ADDRESS" ] && [ -n "$CHAIN2_RPC_URL" ]; then
    BALANCE2_RAW=$(cast call "$CHAIN2_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$ACCOUNT" --rpc-url "$CHAIN2_RPC_URL" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$BALANCE2_RAW" ]; then
        # castの出力から数値部分のみを抽出（[1e21]のような表記を除去）
        BALANCE2=$(echo "$BALANCE2_RAW" | sed 's/\[.*\]//g' | tr -d ' ')
        if [ "$BALANCE2" != "0" ]; then
            BALANCE2_ETHER=$(echo "scale=2; $BALANCE2 / 1000000000000000000" | bc 2>/dev/null || echo "0")
        else
            BALANCE2_ETHER="0"
        fi
        echo "Chain2 Balance: $BALANCE2_ETHER tokens"
    else
        echo "Chain2 Balance: Error fetching balance"
        BALANCE2="0"
    fi
else
    echo "Chain2: Not configured"
fi

# 合計を計算
if [ "$BALANCE1" != "0" ] || [ "$BALANCE2" != "0" ]; then
    TOTAL=$(echo "$BALANCE1 + $BALANCE2" | bc 2>/dev/null || echo "0")
    if [ "$TOTAL" != "0" ]; then
        TOTAL_ETHER=$(echo "scale=2; $TOTAL / 1000000000000000000" | bc 2>/dev/null || echo "0")
    else
        TOTAL_ETHER="0"
    fi
    echo ""
    echo "Total Balance: $TOTAL_ETHER tokens"
fi