#!/bin/bash
# create-warp-blockchain.sh

set -e

CHAIN_NAME=$1
if [ -z "$CHAIN_NAME" ]; then
  echo "使用方法: $0 <chain_name>"
  echo "例: $0 mychain"
  exit 1
fi

echo "=========================================="
echo "Warp API対応ブロックチェーンを作成中..."
echo "チェーン名: $CHAIN_NAME"
echo "=========================================="

# 1. ブロックチェーン作成
echo "1. ブロックチェーンを作成中..."
avalanche blockchain create $CHAIN_NAME

# 2. 設定確認
echo "2. 設定を確認中..."
avalanche blockchain describe $CHAIN_NAME

# 3. ローカルデプロイ
echo "3. ローカルネットワークにデプロイ中..."
avalanche blockchain deploy $CHAIN_NAME --local

# 4. Warp API動作確認
echo "4. Warp API動作確認中..."
sleep 5

# ブロックチェーンIDを取得
BLOCKCHAIN_ID=$(avalanche blockchain describe $CHAIN_NAME --local | grep "Blockchain ID" | cut -d: -f2 | tr -d ' ')
if [ -z "$BLOCKCHAIN_ID" ]; then
  echo "警告: ブロックチェーンIDが取得できませんでした"
else
  echo "ブロックチェーンID: $BLOCKCHAIN_ID"
  
  # RPC接続テスト
  RPC_URL="http://127.0.0.1:9650/ext/bc/$BLOCKCHAIN_ID/rpc"
  echo "RPC URL: $RPC_URL"
  
  RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion"}' \
    $RPC_URL)
  
  if echo "$RESPONSE" | grep -q "result"; then
    echo "✓ RPC接続確認: OK"
    echo "レスポンス: $RESPONSE"
  else
    echo "✗ RPC接続確認: 失敗"
    echo "レスポンス: $RESPONSE"
  fi
fi

echo "=========================================="
echo "ブロックチェーン作成完了!"
echo "チェーン名: $CHAIN_NAME"
echo "次のステップ:"
echo "1. AWM Relayerの設定"
echo "2. ICMメッセージテスト"
echo "=========================================="