#!/bin/bash

# 環境変数を読み込む
source .env

echo "=== Teleporter Status Check ==="
echo ""

# Teleporter Messengerアドレス
TELEPORTER_ADDRESS="0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf"

# Chain1の情報
echo "Chain1 Teleporter Status:"
echo "Getting latest teleporter message ID..."
LATEST_MESSAGE_ID_CHAIN1=$(cast call "$TELEPORTER_ADDRESS" "getNextMessageID(bytes32)(uint256)" "$CHAIN2_BLOCKCHAIN_ID" --rpc-url "$CHAIN1_RPC_URL")
echo "Latest message ID to Chain2: $LATEST_MESSAGE_ID_CHAIN1"

echo ""
echo "Chain2 Teleporter Status:"
echo "Getting received message nonce..."
# チェック: Chain2がChain1からのメッセージを何個受信したか
RECEIVED_NONCE=$(cast call "$TELEPORTER_ADDRESS" "getReceiptQueueSize(bytes32)(uint256)" "$CHAIN1_BLOCKCHAIN_ID" --rpc-url "$CHAIN2_RPC_URL" 2>/dev/null || echo "0")
echo "Receipt queue size from Chain1: $RECEIVED_NONCE"

# 最後に受信したメッセージIDを確認
LAST_RECEIVED=$(cast call "$TELEPORTER_ADDRESS" "getRelayerRewardAddress(bytes32,uint256)(address)" "$CHAIN1_BLOCKCHAIN_ID" "1" --rpc-url "$CHAIN2_RPC_URL" 2>/dev/null || echo "No messages received")
echo "Relayer reward check: $LAST_RECEIVED"

echo ""
echo "Token Contract Remote Address Check:"
# Chain2のトークンコントラクトがChain1のアドレスを認識しているか確認
REMOTE_ADDRESS=$(cast call "$CHAIN2_TOKEN_ADDRESS" "_remoteTeleporterAddresses(bytes32)(address)" "$CHAIN1_BLOCKCHAIN_ID" --rpc-url "$CHAIN2_RPC_URL" 2>/dev/null || echo "Not set")
echo "Chain2 token recognizes Chain1 token at: $REMOTE_ADDRESS"