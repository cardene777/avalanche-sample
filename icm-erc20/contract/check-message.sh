#!/bin/bash

# 環境変数を読み込む
source .env

echo "=== Teleporter Message Status Check ==="
echo ""

# 最後のトランザクションハッシュを引数から取得
TX_HASH="${1}"

if [ -z "$TX_HASH" ]; then
    echo "Usage: ./check-message.sh <transaction_hash>"
    echo "Example: ./check-message.sh 0xf7be85cec39cf404b379fea62189a428775fc5844903c61c82f8a68435b8a997"
    exit 1
fi

echo "Checking transaction: $TX_HASH"
echo ""

# Chain1でトランザクションを確認
echo "=== Transaction Receipt on Chain1 ==="
cast receipt "$TX_HASH" --rpc-url "$CHAIN1_RPC_URL" --json | jq '.' || echo "Failed to get receipt"

echo ""
echo "=== Transaction Logs ==="
cast receipt "$TX_HASH" --rpc-url "$CHAIN1_RPC_URL" --json | jq '.logs' || echo "Failed to get logs"

# TeleporterのsendCrossChainMessageイベントを探す
echo ""
echo "=== Looking for Teleporter Events ==="
echo "Searching for SendCrossChainMessage event..."

# Teleporter Messengerアドレス
TELEPORTER_ADDRESS="0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf"

# SendCrossChainMessageイベントのシグネチャ
# event SendCrossChainMessage(
#     bytes32 indexed destinationBlockchainID,
#     uint256 indexed messageID,
#     TeleporterMessage message,
#     TeleporterFeeInfo feeInfo
# )
SEND_EVENT_SIG="0x6a86ee5bf117718141e404a57dd358ce9f3b1e14d803c3ad6e5e0dd20e9b9287"

# ログから該当イベントを探す
echo ""
echo "Filtering logs for SendCrossChainMessage events..."
cast receipt "$TX_HASH" --rpc-url "$CHAIN1_RPC_URL" --json | \
    jq --arg sig "$SEND_EVENT_SIG" '.logs[] | select(.topics[0] == $sig)' || echo "No SendCrossChainMessage event found"