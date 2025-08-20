#!/bin/bash

echo "Creating AWM Relayer configuration for chain1 and chain2..."

CONFIG_FILE="/tmp/icm-relayer-config-chains.json"

cat > "$CONFIG_FILE" << 'EOF'
{
  "log-level": "info",
  "storage-location": "/Users/cardene/.avalanche-cli/runs/LocalNetwork/local-relayer/icm-relayer-storage",
  "redis-url": "",
  "api-port": 0,
  "metrics-port": 0,
  "db-write-interval-seconds": 10,
  "p-chain-api": {
    "base-url": "http://127.0.0.1:9650",
    "query-parameters": {},
    "http-headers": null
  },
  "info-api": {
    "base-url": "http://127.0.0.1:9650",
    "query-parameters": {},
    "http-headers": null
  },
  "source-blockchains": [
    {
      "subnet-id": "2W9boARgCWL25z6pMFNtkCfNA5v28VGg9PmBgUJfuKndEdhrvw",
      "blockchain-id": "AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "ws-endpoint": {
        "base-url": "ws://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/ws",
        "query-parameters": null,
        "http-headers": null
      },
      "message-contracts": {
        "0x0000000000000000000000000000000000000000": {
          "message-format": "off-chain-registry",
          "settings": {
            "teleporter-registry-address": "0xed05465DF81D2dB756C414B3730adFB8b04a4C98"
          }
        },
        "0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf": {
          "message-format": "teleporter",
          "settings": {
            "reward-address": "0xCed574499248A8066BD52c8a4403ba26cf37badA"
          }
        }
      },
      "supported-destinations": null,
      "process-historical-blocks-from-height": 0,
      "allowed-origin-sender-addresses": null,
      "warp-api-endpoint": {
        "base-url": "http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/warp",
        "query-parameters": null,
        "http-headers": null
      }
    },
    {
      "subnet-id": "WnBEQ8gTQC629vc3VfmwV1v6ZddimLtrdgcmLBN3bugA3RTMd",
      "blockchain-id": "a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "ws-endpoint": {
        "base-url": "ws://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/ws",
        "query-parameters": null,
        "http-headers": null
      },
      "message-contracts": {
        "0x0000000000000000000000000000000000000000": {
          "message-format": "off-chain-registry",
          "settings": {
            "teleporter-registry-address": "0xed05465DF81D2dB756C414B3730adFB8b04a4C98"
          }
        },
        "0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf": {
          "message-format": "teleporter",
          "settings": {
            "reward-address": "0xCed574499248A8066BD52c8a4403ba26cf37badA"
          }
        }
      },
      "supported-destinations": null,
      "process-historical-blocks-from-height": 0,
      "allowed-origin-sender-addresses": null,
      "warp-api-endpoint": {
        "base-url": "http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/warp",
        "query-parameters": null,
        "http-headers": null
      }
    }
  ],
  "destination-blockchains": [
    {
      "subnet-id": "2W9boARgCWL25z6pMFNtkCfNA5v28VGg9PmBgUJfuKndEdhrvw",
      "blockchain-id": "AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "kms-key-id": "",
      "kms-aws-region": "",
      "account-private-key": "0906f35f671b1f35dd0f4cd1851d1b5128bfdc059aea8ecea0c4d5e848663f53",
      "block-gas-limit": 0
    },
    {
      "subnet-id": "WnBEQ8gTQC629vc3VfmwV1v6ZddimLtrdgcmLBN3bugA3RTMd",
      "blockchain-id": "a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "kms-key-id": "",
      "kms-aws-region": "",
      "account-private-key": "0906f35f671b1f35dd0f4cd1851d1b5128bfdc059aea8ecea0c4d5e848663f53",
      "block-gas-limit": 0
    }
  ],
  "process-missed-blocks": false,
  "decider-url": "",
  "signature-cache-size": 1048576,
  "manually-tracked-peers": null,
  "allow-private-ips": true,
  "initial-connection-timeout-seconds": 60
}
EOF

echo "Configuration created at: $CONFIG_FILE"

# Start AWM Relayer
RELAYER_BIN="/Users/cardene/.avalanche-cli/bin/icm-relayer/icm-relayer-v1.6.6/icm-relayer"

if [ -f "$RELAYER_BIN" ]; then
    echo "Starting AWM Relayer..."
    # Kill existing relayer if running
    pkill -f "icm-relayer" 2>/dev/null || true
    sleep 2
    
    # Start new relayer
    nohup "$RELAYER_BIN" --config-file "$CONFIG_FILE" > ~/awm-relayer-chains.log 2>&1 &
    echo "AWM Relayer started with PID $!"
    echo "Logs: ~/awm-relayer-chains.log"
else
    echo "Error: AWM Relayer binary not found at $RELAYER_BIN"
fi