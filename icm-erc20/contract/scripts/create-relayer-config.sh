#!/bin/bash

echo "AWM Relayer設定ファイルを作成します..."

# 設定ファイルのパス
CONFIG_FILE="/Users/cardene/.avalanche-cli/runs/network_20250819_155154/icm-relayer-config.json"

# 設定内容を作成
cat > "$CONFIG_FILE" << 'EOF'
{
  "log-level": "info",
  "storage-location": "/Users/cardene/.avalanche-cli/runs/LocalNetwork/local-relayer/icm-relayer-storage",
  "redis-url": "",
  "api-port": 0,
  "metrics-port": 9092,
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
      "blockchain-id": "uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:55064/ext/bc/uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "ws-endpoint": {
        "base-url": "ws://127.0.0.1:55064/ext/bc/uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE/ws",
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
        "base-url": "http://127.0.0.1:55064/ext/bc/uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE/warp",
        "query-parameters": null,
        "http-headers": null
      }
    },
    {
      "subnet-id": "nS2vQLtAmXH7VgzNQk786uxrgqHx8Hv8wixEFFpVDaXJEpzz8",
      "blockchain-id": "i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:55159/ext/bc/i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "ws-endpoint": {
        "base-url": "ws://127.0.0.1:55159/ext/bc/i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry/ws",
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
        "base-url": "http://127.0.0.1:55159/ext/bc/i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry/warp",
        "query-parameters": null,
        "http-headers": null
      }
    }
  ],
  "destination-blockchains": [
    {
      "subnet-id": "2W9boARgCWL25z6pMFNtkCfNA5v28VGg9PmBgUJfuKndEdhrvw",
      "blockchain-id": "uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:55064/ext/bc/uDjiypK4NWNSRUwEtGhhvc4woRdAfUH4q9sjv2vsQUF9rm3KE/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "kms-key-id": "",
      "kms-aws-region": "",
      "account-private-key": "f41bd26f6b0be05dc4153d9b32e329bd8f9efe297deb7326919ecbceed2393f8",
      "block-gas-limit": 0
    },
    {
      "subnet-id": "nS2vQLtAmXH7VgzNQk786uxrgqHx8Hv8wixEFFpVDaXJEpzz8",
      "blockchain-id": "i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry",
      "vm": "evm",
      "rpc-endpoint": {
        "base-url": "http://127.0.0.1:55159/ext/bc/i5sBmqc6EvbLpakDWfC9zAb4MEu5cN981qBo51GBjzfLQZPry/rpc",
        "query-parameters": null,
        "http-headers": null
      },
      "kms-key-id": "",
      "kms-aws-region": "",
      "account-private-key": "f41bd26f6b0be05dc4153d9b32e329bd8f9efe297deb7326919ecbceed2393f8",
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

echo "設定ファイルを作成しました: $CONFIG_FILE"

# AWM Relayerを起動
./scripts/start-latest-relayer.sh