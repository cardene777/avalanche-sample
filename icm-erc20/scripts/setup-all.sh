#!/bin/bash

# すべてのセットアップを実行する統合スクリプト

set -e

echo "=== Avalanche ICM ERC20 完全セットアップ ==="

# 色付きの出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. プロセスをすべて停止
echo -e "${YELLOW}1. すべてのプロセスを停止中...${NC}"
pkill -f avalanchego || true
pkill -f signature-aggregator || true
pkill -f icm-relayer || true
pkill -f awm-relayer || true
sleep 3

# 2. ネットワークをクリーンアップして起動
echo -e "${YELLOW}2. ネットワークをクリーンアップして起動中...${NC}"
/Users/cardene/bin/avalanche network clean --hard
/Users/cardene/bin/avalanche network start --avalanchego-version v1.13.4

# 3. Chain1を作成してデプロイ
echo -e "${YELLOW}3. Chain1を作成してデプロイ中...${NC}"
# 既存のchain1を削除
rm -rf /Users/cardene/.avalanche-cli/subnets/chain1
# 新しいchain1を作成
cat << EOF > /tmp/chain1-genesis.json
{
  "airdropHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "config": {
    "chainId": 11,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "cancunTime": 0,
    "interchainMessagingEnabled": true,
    "validators-set-signature-enabled": true
  },
  "alloc": {
    "8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC": {
      "balance": "0x295BE96E64066972000000"
    }
  },
  "gasLimit": "0x7A1200",
  "difficulty": "0x0",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "timestamp": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "extraData": "0x"
}
EOF

/Users/cardene/bin/avalanche blockchain create chain1 --force --evm --genesis /tmp/chain1-genesis.json
echo "y" | /Users/cardene/bin/avalanche blockchain deploy chain1 --local

# 4. Chain2を作成してデプロイ
echo -e "${YELLOW}4. Chain2を作成してデプロイ中...${NC}"
# 既存のchain2を削除
rm -rf /Users/cardene/.avalanche-cli/subnets/chain2
# 新しいchain2を作成
cat << EOF > /tmp/chain2-genesis.json
{
  "airdropHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "config": {
    "chainId": 22,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "cancunTime": 0,
    "interchainMessagingEnabled": true,
    "validators-set-signature-enabled": true
  },
  "alloc": {
    "8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC": {
      "balance": "0x295BE96E64066972000000"
    }
  },
  "gasLimit": "0x7A1200",
  "difficulty": "0x0",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "timestamp": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "extraData": "0x"
}
EOF

/Users/cardene/bin/avalanche blockchain create chain2 --force --evm --genesis /tmp/chain2-genesis.json
echo "y" | /Users/cardene/bin/avalanche blockchain deploy chain2 --local

# 5. 新しいエンドポイントを取得して.envを更新
echo -e "${YELLOW}5. 新しいエンドポイントを取得中...${NC}"
CHAIN1_INFO=$(/Users/cardene/bin/avalanche blockchain describe chain1)
CHAIN1_RPC=$(echo "$CHAIN1_INFO" | grep -oE 'http://[^[:space:]]+/rpc' | head -1)
CHAIN1_BLOCKCHAIN_ID=$(echo "$CHAIN1_INFO" | grep "BlockchainID (HEX)" | awk '{print $NF}')

CHAIN2_INFO=$(/Users/cardene/bin/avalanche blockchain describe chain2)  
CHAIN2_RPC=$(echo "$CHAIN2_INFO" | grep -oE 'http://[^[:space:]]+/rpc' | tail -1)
CHAIN2_BLOCKCHAIN_ID=$(echo "$CHAIN2_INFO" | grep "BlockchainID (HEX)" | awk '{print $NF}')

# .envファイルを更新
cat > /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20/.env << EOF
# デプロイヤーの秘密鍵
PRIVATE_KEY=0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027

# Chain1の設定
CHAIN1_RPC_URL=${CHAIN1_RPC}
CHAIN1_BLOCKCHAIN_ID=${CHAIN1_BLOCKCHAIN_ID}
CHAIN1_TOKEN_ADDRESS=

# Chain2の設定
CHAIN2_RPC_URL=${CHAIN2_RPC}
CHAIN2_BLOCKCHAIN_ID=${CHAIN2_BLOCKCHAIN_ID}
CHAIN2_TOKEN_ADDRESS=

# デフォルトの受信者アドレス
DEFAULT_RECIPIENT=0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
EOF

# 6. AWM Relayerを起動
echo -e "${YELLOW}6. AWM Relayerを起動中...${NC}"

# Relayer設定ファイルを作成
cat > /tmp/icm-relayer-config.json << EOF
{
  "logLevel": "debug",
  "storageLocation": "/tmp/awm-relayer-storage",
  "chains": [
    {
      "chainID": "${CHAIN1_BLOCKCHAIN_ID}",
      "endpoint": "${CHAIN1_RPC}",
      "warpEndpoint": "${CHAIN1_RPC%/rpc}/warp"
    },
    {
      "chainID": "${CHAIN2_BLOCKCHAIN_ID}",
      "endpoint": "${CHAIN2_RPC}",
      "warpEndpoint": "${CHAIN2_RPC%/rpc}/warp"
    }
  ],
  "signerPrivateKey": "0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027"
}
EOF

# AWM Relayerを起動
pkill -f awm-relayer || true
nohup /Users/cardene/bin/awm-relayer --config /tmp/icm-relayer-config.json > ~/awm-relayer.log 2>&1 &
echo "AWM Relayer started with PID $!"

# 7. 少し待ってからTeleporterERC20をデプロイ
echo -e "${YELLOW}7. TeleporterERC20をデプロイ中（10秒待機）...${NC}"
sleep 10

cd /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20
./scripts/setup/deploy-teleporter-tokens.sh

echo -e "${GREEN}=== セットアップ完了 ===${NC}"
echo ""
echo "環境情報:"
echo "Chain1 RPC: ${CHAIN1_RPC}"
echo "Chain2 RPC: ${CHAIN2_RPC}"
echo ""
echo "使用方法:"
echo "1. make mint CHAIN=1         - Chain1でトークンをmint"
echo "2. make balance CHAIN=all    - 両チェーンの残高確認"
echo "3. make transfer FROM=1 TO=2 - Chain1からChain2へ転送"
echo ""
echo "AWM Relayerログ: ~/awm-relayer.log"