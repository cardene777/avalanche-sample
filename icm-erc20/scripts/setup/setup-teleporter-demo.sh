#!/bin/bash

echo "=== Teleporter Token Bridge Demo Setup ==="
echo ""

# 1. Deploy existing teleporterchain1 and teleporterchain2
echo "1. Deploying teleporterchain1..."
cd /Users/cardene/.avalanche-cli/local/teleporterchain1-local-node-local-network
/Users/cardene/.avalanche-cli/bin/avalanchego/avalanchego-v1.13.4/avalanchego --config-file NodeID-94NpMoNZxxYbL37qntjwn5LNvTuz7KT8W/flags.json > avalanchego.log 2>&1 &
CHAIN1_PID=$!
echo "   Started with PID: $CHAIN1_PID"

echo "2. Deploying teleporterchain2..."
cd /Users/cardene/.avalanche-cli/local/teleporterchain2-local-node-local-network
/Users/cardene/.avalanche-cli/bin/avalanchego/avalanchego-v1.13.4/avalanchego --config-file NodeID-Fz2e4aJvvHEcTXi6eXaPJbpHhDpmUc9bC/flags.json > avalanchego.log 2>&1 &
CHAIN2_PID=$!
echo "   Started with PID: $CHAIN2_PID"

# Wait for chains to be ready
echo ""
echo "3. Waiting for chains to be ready..."
sleep 10

# 4. Start AWM Relayer
echo "4. Starting AWM Relayer..."
cd /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20/contract
cp /Users/cardene/.avalanche-cli/runs/network_20250819_155154/icm-relayer-config.json /tmp/icm-relayer-config.json 2>/dev/null || true

# Find AWM Relayer binary
RELAYER_BIN=$(find ~/.avalanche-cli/bin/icm-relayer -name "icm-relayer" -type f | head -1)
if [ -n "$RELAYER_BIN" ]; then
    nohup "$RELAYER_BIN" --config-file /tmp/icm-relayer-config.json > ~/awm-relayer.log 2>&1 &
    echo "   AWM Relayer started"
else
    echo "   Warning: AWM Relayer not found"
fi

echo ""
echo "5. Chain Information:"
echo "   Chain1 RPC: http://127.0.0.1:55064/ext/bc/uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE/rpc"
echo "   Chain2 RPC: http://127.0.0.1:55159/ext/bc/i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry/rpc"
echo ""
echo "6. Deployed Contracts:"
echo "   Chain1 Token: 0x8B3BC4270BE2abbB25BC04717830bd1Cc493a461"
echo "   Chain2 Token: 0xa4DfF80B4a1D748BF28BC4A271eD834689Ea3407"
echo ""
echo "Setup complete!"