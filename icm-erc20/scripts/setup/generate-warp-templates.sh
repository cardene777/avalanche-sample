#!/bin/bash
# generate-warp-templates.sh

TEMPLATE_DIR="$HOME/.avalanche-cli/templates/warp-enabled"
mkdir -p "$TEMPLATE_DIR"

echo "Warp APIテンプレートファイルを生成中..."

# チェーン設定テンプレート
cat > "$TEMPLATE_DIR/chain.json" << 'EOF'
{
  "log-level": "debug",
  "database-type": "leveldb",
  "eth-apis": [
    "eth",
    "eth-filter",
    "net", 
    "admin",
    "web3",
    "internal-eth",
    "internal-blockchain",
    "internal-transaction",
    "internal-debug",
    "internal-account",
    "internal-personal",
    "debug",
    "debug-tracer",
    "debug-file-tracer",
    "debug-handler"
  ],
  "warp-api-enabled": true
}
EOF

# Genesis設定テンプレート
cat > "$TEMPLATE_DIR/genesis.json" << 'EOF'
{
  "config": {
    "chainId": 12345,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "subnetEVMTimestamp": 0,
    "warp-config": {
      "block-format": "off-chain-registry",
      "enabled": true
    }
  },
  "warp-api-enabled": true,
  "alloc": {
    "8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC": {
      "balance": "0x295BE96E64066972000000"
    }
  }
}
EOF

echo "✓ テンプレートファイルが生成されました:"
echo "  - $TEMPLATE_DIR/chain.json"
echo "  - $TEMPLATE_DIR/genesis.json"
echo ""
echo "使用方法:"
echo "  avalanche blockchain create mychain --template warp-enabled"