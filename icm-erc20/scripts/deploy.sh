#!/bin/bash

# デプロイスクリプト
# 使用方法: ./scripts/deploy.sh <contract_type> <chain_name>

set -e

# 引数チェック
if [ $# -lt 2 ]; then
    echo "Usage: $0 <contract_type> <chain_name>"
    echo "contract_type: teleporter, sender, receiver"
    echo "chain_name: fuji-c, fuji-dispatch"
    exit 1
fi

CONTRACT_TYPE=$1
CHAIN_NAME=$2

# 環境変数の読み込み
source .env

# チェーン名の検証とRPC URLの設定
case $CHAIN_NAME in
    "fuji-c")
        RPC_URL="https://api.avax-test.network/ext/bc/C/rpc"
        CHAIN_ID="0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5"
        ;;
    "fuji-dispatch")
        RPC_URL="https://subnets.avax.network/dispatch/testnet/rpc"
        CHAIN_ID="0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7"
        ;;
    *)
        echo "Invalid chain name: $CHAIN_NAME"
        exit 1
        ;;
esac

# コントラクトタイプによってデプロイスクリプトを選択
case $CONTRACT_TYPE in
    "teleporter")
        echo "Deploying TeleporterERC20 to $CHAIN_NAME..."
        CHAIN_NAME=$CHAIN_NAME forge script script/DeployTeleporterERC20.s.sol:DeployTeleporterERC20Script \
            --rpc-url $RPC_URL \
            --broadcast \
            -vvv \
            --json > deploy_output.json
        
        # デプロイしたアドレスを抽出
        DEPLOYED_ADDRESS=$(cat deploy_output.json | jq -r '.returns.deployed.value')
        echo "TeleporterERC20 deployed to: $DEPLOYED_ADDRESS"
        
        # 環境変数ファイルに保存
        if [ "$CHAIN_NAME" = "fuji-c" ]; then
            echo "export FUJI_C_TOKEN_ADDRESS=$DEPLOYED_ADDRESS" >> .env.deployed
        else
            echo "export FUJI_DISPATCH_TOKEN_ADDRESS=$DEPLOYED_ADDRESS" >> .env.deployed
        fi
        ;;
        
    "sender")
        echo "Deploying SimpleSender to $CHAIN_NAME..."
        CONTRACT_TYPE=sender forge script script/DeploySimpleContracts.s.sol:DeploySimpleContractsScript \
            --rpc-url $RPC_URL \
            --broadcast \
            -vvv \
            --json > deploy_output.json
        
        DEPLOYED_ADDRESS=$(cat deploy_output.json | jq -r '.returns.deployed.value')
        echo "SimpleSender deployed to: $DEPLOYED_ADDRESS"
        
        if [ "$CHAIN_NAME" = "fuji-c" ]; then
            echo "export FUJI_C_SENDER_ADDRESS=$DEPLOYED_ADDRESS" >> .env.deployed
        else
            echo "export FUJI_DISPATCH_SENDER_ADDRESS=$DEPLOYED_ADDRESS" >> .env.deployed
        fi
        ;;
        
    "receiver")
        echo "Deploying SimpleReceiver to $CHAIN_NAME..."
        CONTRACT_TYPE=receiver forge script script/DeploySimpleContracts.s.sol:DeploySimpleContractsScript \
            --rpc-url $RPC_URL \
            --broadcast \
            -vvv \
            --json > deploy_output.json
        
        DEPLOYED_ADDRESS=$(cat deploy_output.json | jq -r '.returns.deployed.value')
        echo "SimpleReceiver deployed to: $DEPLOYED_ADDRESS"
        
        if [ "$CHAIN_NAME" = "fuji-c" ]; then
            echo "export FUJI_C_RECEIVER_ADDRESS=$DEPLOYED_ADDRESS" >> .env.deployed
        else
            echo "export FUJI_DISPATCH_RECEIVER_ADDRESS=$DEPLOYED_ADDRESS" >> .env.deployed
        fi
        ;;
        
    *)
        echo "Invalid contract type: $CONTRACT_TYPE"
        exit 1
        ;;
esac

echo "Deployment completed!"
echo "Run 'source .env.deployed' to load the deployed addresses"