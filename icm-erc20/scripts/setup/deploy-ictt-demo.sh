#!/bin/bash

echo "=== ICTT Deployment Demo ==="
echo ""
echo "This script will deploy ICTT between C-Chain and a custom L1"
echo ""

# 1. Deploy ERC20 on C-Chain
echo "1. Deploying ERC20 on C-Chain..."
cd /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20/contract
source .env

# Check if token already deployed
TOKEN_ADDRESS=$(cat broadcast/DeployC.s.sol/1337/run-latest.json 2>/dev/null | grep -A1 "contractAddress" | tail -1 | sed 's/.*"0x/0x/' | sed 's/".*//')

if [ -z "$TOKEN_ADDRESS" ]; then
    echo "   Deploying new token..."
    forge script script/DeployC.s.sol:DeployC --broadcast --rpc-url http://127.0.0.1:9650/ext/bc/C/rpc --private-key $PRIVATE_KEY
    TOKEN_ADDRESS=$(cat broadcast/DeployC.s.sol/1337/run-latest.json | grep -A1 "contractAddress" | tail -1 | sed 's/.*"0x/0x/' | sed 's/".*//')
fi

echo "   Token deployed at: $TOKEN_ADDRESS"

# 2. Check balance
echo ""
echo "2. Checking token balance..."
BALANCE=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC --rpc-url http://127.0.0.1:9650/ext/bc/C/rpc)
echo "   Balance: $BALANCE"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: avalanche ictt deploy"
echo "2. Select Local Network"
echo "3. Select C-Chain as Home chain"
echo "4. Deploy a new Home for the token"
echo "5. Select 'An ERC-20 token'"
echo "6. Enter token address: $TOKEN_ADDRESS"
echo "7. Select a destination L1 chain"