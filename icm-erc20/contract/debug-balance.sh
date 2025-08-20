#!/bin/bash

# 環境変数を読み込む
source .env

# デフォルト値
ACCOUNT="${ACCOUNT:-0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC}"

echo "=== Debug Balance Check ==="
echo "Account: $ACCOUNT"
echo ""

echo "Chain1 Debug:"
echo "Token Address: $CHAIN1_TOKEN_ADDRESS"
echo "RPC URL: $CHAIN1_RPC_URL"
echo ""

# Chain1の残高を確認（生の値）
echo "Running cast call for Chain1..."
BALANCE1_RAW=$(cast call "$CHAIN1_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$ACCOUNT" --rpc-url "$CHAIN1_RPC_URL")
echo "Raw result: $BALANCE1_RAW"

# 10進数に変換
if [ -n "$BALANCE1_RAW" ]; then
    BALANCE1_DEC=$(cast --to-dec "$BALANCE1_RAW")
    echo "Decimal: $BALANCE1_DEC"
    
    # Ether単位に変換
    if [ "$BALANCE1_DEC" != "0" ]; then
        BALANCE1_ETHER=$(echo "scale=6; $BALANCE1_DEC / 1000000000000000000" | bc)
        echo "Ether: $BALANCE1_ETHER tokens"
    fi
fi

echo ""
echo "Chain2 Debug:"
echo "Token Address: $CHAIN2_TOKEN_ADDRESS"
echo "RPC URL: $CHAIN2_RPC_URL"
echo ""

# Chain2の残高を確認（生の値）
echo "Running cast call for Chain2..."
BALANCE2_RAW=$(cast call "$CHAIN2_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$ACCOUNT" --rpc-url "$CHAIN2_RPC_URL")
echo "Raw result: $BALANCE2_RAW"

# 10進数に変換
if [ -n "$BALANCE2_RAW" ]; then
    BALANCE2_DEC=$(cast --to-dec "$BALANCE2_RAW")
    echo "Decimal: $BALANCE2_DEC"
    
    # Ether単位に変換
    if [ "$BALANCE2_DEC" != "0" ]; then
        BALANCE2_ETHER=$(echo "scale=6; $BALANCE2_DEC / 1000000000000000000" | bc)
        echo "Ether: $BALANCE2_ETHER tokens"
    fi
fi