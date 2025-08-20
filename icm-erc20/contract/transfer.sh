#!/bin/bash

# 環境変数を読み込む
source .env

# デフォルト値
RECIPIENT="${RECIPIENT:-0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC}"
AMOUNT="${AMOUNT:-100000000000000000000}" # 100 tokens

# 引数からチェーンを指定
if [ "$1" == "chain1" ]; then
    echo "=== Transferring from Chain1 to Chain2 ==="
    SOURCE_RPC="$CHAIN1_RPC_URL"
    TOKEN_ADDRESS="$CHAIN1_TOKEN_ADDRESS"
    DESTINATION_BLOCKCHAIN_ID="$CHAIN2_BLOCKCHAIN_ID"
    SOURCE_NAME="Chain1"
    DEST_NAME="Chain2"
elif [ "$1" == "chain2" ]; then
    echo "=== Transferring from Chain2 to Chain1 ==="
    SOURCE_RPC="$CHAIN2_RPC_URL"
    TOKEN_ADDRESS="$CHAIN2_TOKEN_ADDRESS"
    DESTINATION_BLOCKCHAIN_ID="$CHAIN1_BLOCKCHAIN_ID"
    SOURCE_NAME="Chain2"
    DEST_NAME="Chain1"
else
    echo "Usage: ./transfer.sh [chain1|chain2]"
    echo "  chain1: Transfer from Chain1 to Chain2"
    echo "  chain2: Transfer from Chain2 to Chain1"
    exit 1
fi

# 転送前の残高を確認
echo ""
echo "Checking balance before transfer..."
BALANCE_BEFORE_RAW=$(cast call "$TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$RECIPIENT" --rpc-url "$SOURCE_RPC")
if [ $? -eq 0 ] && [ -n "$BALANCE_BEFORE_RAW" ]; then
    # castの出力から数値部分のみを抽出（[1e21]のような表記を除去）
    BALANCE_BEFORE=$(echo "$BALANCE_BEFORE_RAW" | sed 's/\[.*\]//g' | tr -d ' ')
    if [ "$BALANCE_BEFORE" != "0" ]; then
        BALANCE_BEFORE_ETHER=$(echo "scale=2; $BALANCE_BEFORE / 1000000000000000000" | bc 2>/dev/null || echo "0")
    else
        BALANCE_BEFORE_ETHER="0"
    fi
    echo "Balance on $SOURCE_NAME: $BALANCE_BEFORE_ETHER tokens"
else
    echo "Error: Failed to fetch balance"
    exit 1
fi

# 転送を実行
echo ""
echo "Executing transfer..."
AMOUNT_ETHER=$(echo "scale=2; $AMOUNT / 1000000000000000000" | bc 2>/dev/null || echo "100")
echo "Amount: $AMOUNT_ETHER tokens"
echo "Recipient: $RECIPIENT"
echo "Destination: $DEST_NAME"

TX_HASH=$(cast send "$TOKEN_ADDRESS" \
    "sendTokens(bytes32,address,uint256)" \
    "$DESTINATION_BLOCKCHAIN_ID" \
    "$RECIPIENT" \
    "$AMOUNT" \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$SOURCE_RPC" \
    --json | jq -r '.transactionHash')

if [ -z "$TX_HASH" ]; then
    echo "Error: Transfer failed"
    exit 1
fi

echo "Transaction hash: $TX_HASH"

# 転送後の残高を確認
echo ""
echo "Checking balance after transfer..."
sleep 2
BALANCE_AFTER_RAW=$(cast call "$TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$RECIPIENT" --rpc-url "$SOURCE_RPC")
if [ $? -eq 0 ] && [ -n "$BALANCE_AFTER_RAW" ]; then
    # castの出力から数値部分のみを抽出（[1e21]のような表記を除去）
    BALANCE_AFTER=$(echo "$BALANCE_AFTER_RAW" | sed 's/\[.*\]//g' | tr -d ' ')
    if [ "$BALANCE_AFTER" != "0" ]; then
        BALANCE_AFTER_ETHER=$(echo "scale=2; $BALANCE_AFTER / 1000000000000000000" | bc 2>/dev/null || echo "0")
    else
        BALANCE_AFTER_ETHER="0"
    fi
    echo "Balance on $SOURCE_NAME: $BALANCE_AFTER_ETHER tokens"
    
    # 送信されたトークン数を計算
    TOKENS_SENT=$(echo "$BALANCE_BEFORE - $BALANCE_AFTER" | bc 2>/dev/null || echo "0")
    if [ "$TOKENS_SENT" != "0" ]; then
        TOKENS_SENT_ETHER=$(echo "scale=2; $TOKENS_SENT / 1000000000000000000" | bc 2>/dev/null || echo "0")
    else
        TOKENS_SENT_ETHER="0"
    fi
    echo "Tokens sent: $TOKENS_SENT_ETHER"
else
    echo "Warning: Failed to fetch balance after transfer"
fi

echo ""
echo "Transfer initiated successfully!"
echo "Note: Check the destination chain balance after AWM Relayer delivers the message"