#!/bin/bash

# TeleporterERC20のデプロイと設定を行うスクリプト
# このスクリプトは以下の処理を実行します：
# 1. Chain1とChain2にTeleporterERC20トークンをデプロイ
# 2. 各チェーンのトークンを相互に接続設定
# 3. クロスチェーン転送を可能にする

set -e  # エラーが発生したら即座に終了

# 色付きの出力用のカラーコード定義
RED='\033[0;31m'    # エラーメッセージ用
GREEN='\033[0;32m'  # 成功メッセージ用
YELLOW='\033[1;33m' # 警告・情報メッセージ用
NC='\033[0m'        # 色のリセット

echo -e "${GREEN}=== TeleporterERC20 デプロイスクリプト ===${NC}"

# 必須環境変数PRIVATE_KEYの確認
# これはトランザクションの署名に使用される秘密鍵
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY is not set${NC}"
    echo "Please set: export PRIVATE_KEY=0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027"
    exit 1
fi

# 各チェーンのRPC URLを設定
# これらのURLは各チェーンのEthereumJSONRPCエンドポイント
export CHAIN1_RPC_URL="http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/rpc"
export CHAIN2_RPC_URL="http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/rpc"

# 各チェーンのBlockchain IDを取得
# eth_chainIdメソッドを使用してチェーンIDを取得し、64桁の16進数に変換
echo -e "${YELLOW}Getting blockchain IDs...${NC}"

# Chain1のチェーンIDを取得（JSONRPCリクエスト）
CHAIN1_ID=$(curl -s -X POST --data '{
    "jsonrpc": "2.0",
    "method": "eth_chainId",
    "params": [],
    "id": 1
}' -H "Content-Type: application/json" $CHAIN1_RPC_URL | jq -r '.result')

# Chain2のチェーンIDを取得（JSONRPCリクエスト）
CHAIN2_ID=$(curl -s -X POST --data '{
    "jsonrpc": "2.0",
    "method": "eth_chainId",
    "params": [],
    "id": 1
}' -H "Content-Type: application/json" $CHAIN2_RPC_URL | jq -r '.result')

# チェーンIDを64桁の16進数形式のBlockchain IDに変換
# Teleporterはこの形式のIDを使用して異なるチェーンを識別
export CHAIN1_BLOCKCHAIN_ID="0x$(printf '%064x' $((CHAIN1_ID)))"
export CHAIN2_BLOCKCHAIN_ID="0x$(printf '%064x' $((CHAIN2_ID)))"

echo "Chain1 Blockchain ID: $CHAIN1_BLOCKCHAIN_ID"
echo "Chain2 Blockchain ID: $CHAIN2_BLOCKCHAIN_ID"

# Foundryプロジェクトのコントラクトディレクトリに移動
cd /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20/contract

# Chain1にTeleporterERC20をデプロイ
echo -e "\n${YELLOW}Deploying to Chain1...${NC}"
# forge scriptを使用してデプロイスクリプトを実行
# --broadcastフラグで実際にトランザクションを送信
# --slowフラグで各トランザクション後に確認を待つ
DEPLOY_OUTPUT_1=$(forge script script/DeployTeleporterERC20.s.sol:DeployTeleporterERC20 \
    --rpc-url $CHAIN1_RPC_URL \
    --broadcast \
    --slow \
    2>&1)

# デプロイ出力からトークンアドレスを抽出
CHAIN1_TOKEN=$(echo "$DEPLOY_OUTPUT_1" | grep "TeleporterERC20 deployed at:" | awk '{print $NF}')
echo -e "${GREEN}Chain1 Token Address: $CHAIN1_TOKEN${NC}"

# Chain2にTeleporterERC20をデプロイ（同様の処理）
echo -e "\n${YELLOW}Deploying to Chain2...${NC}"
DEPLOY_OUTPUT_2=$(forge script script/DeployTeleporterERC20.s.sol:DeployTeleporterERC20 \
    --rpc-url $CHAIN2_RPC_URL \
    --broadcast \
    --slow \
    2>&1)

CHAIN2_TOKEN=$(echo "$DEPLOY_OUTPUT_2" | grep "TeleporterERC20 deployed at:" | awk '{print $NF}')
echo -e "${GREEN}Chain2 Token Address: $CHAIN2_TOKEN${NC}"

# 取得したトークンアドレスを環境変数にエクスポート
# これらは次の設定ステップで使用される
export CHAIN1_TOKEN_ADDRESS=$CHAIN1_TOKEN
export CHAIN2_TOKEN_ADDRESS=$CHAIN2_TOKEN

# 相互接続の設定
# 各チェーンのトークンに相手チェーンのトークンアドレスを登録
echo -e "\n${YELLOW}Setting up cross-chain connection...${NC}"

# Chain1のトークンにChain2のトークンアドレスを設定
echo "Configuring Chain1..."
# ETH_RPC_URLを設定してスクリプトが現在のチェーンを識別できるようにする
ETH_RPC_URL=$CHAIN1_RPC_URL forge script script/SetupTeleporter.s.sol:SetupTeleporter \
    --rpc-url $CHAIN1_RPC_URL \
    --broadcast \
    --slow

# Chain2のトークンにChain1のトークンアドレスを設定（同様の処理）
echo "Configuring Chain2..."
ETH_RPC_URL=$CHAIN2_RPC_URL forge script script/SetupTeleporter.s.sol:SetupTeleporter \
    --rpc-url $CHAIN2_RPC_URL \
    --broadcast \
    --slow

# デプロイ完了メッセージとアドレスの表示
echo -e "\n${GREEN}=== デプロイ完了 ===${NC}"
echo -e "${GREEN}Chain1 Token: $CHAIN1_TOKEN${NC}"
echo -e "${GREEN}Chain2 Token: $CHAIN2_TOKEN${NC}"

# ユーザーが後で使用できるように環境変数の設定方法を表示
echo -e "\n${YELLOW}以下の内容を.envファイルに追加してください:${NC}"
echo "CHAIN1_RPC_URL=$CHAIN1_RPC_URL"
echo "CHAIN2_RPC_URL=$CHAIN2_RPC_URL"
echo "CHAIN1_BLOCKCHAIN_ID=$CHAIN1_BLOCKCHAIN_ID"
echo "CHAIN2_BLOCKCHAIN_ID=$CHAIN2_BLOCKCHAIN_ID"
echo "CHAIN1_TOKEN_ADDRESS=$CHAIN1_TOKEN"
echo "CHAIN2_TOKEN_ADDRESS=$CHAIN2_TOKEN"