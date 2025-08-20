#!/bin/bash

# Warp Precompileの動作確認スクリプト

echo "=== Warp Precompile Test ==="

# 環境変数を設定
source /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20/.env

echo "Testing Warp API availability..."

# Chain1のWarp APIエンドポイントを確認
echo -e "\n1. Checking Chain1 Warp API:"
curl -s -X POST --data '{
  "jsonrpc":"2.0",
  "id":1,
  "method":"warp_getBlockSignature",
  "params":{
    "blockID": "0x0000000000000000000000000000000000000000000000000000000000000001"
  }
}' -H 'content-type:application/json;' http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/warp | jq .

# Chain2のWarp APIエンドポイントを確認
echo -e "\n2. Checking Chain2 Warp API:"
curl -s -X POST --data '{
  "jsonrpc":"2.0",
  "id":1,
  "method":"warp_getBlockSignature",
  "params":{
    "blockID": "0x0000000000000000000000000000000000000000000000000000000000000001"
  }
}' -H 'content-type:application/json;' http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/warp | jq .

# ノードのバージョン確認
echo -e "\n3. Checking node version:"
curl -s -X POST --data '{
  "jsonrpc":"2.0",
  "id":1,
  "method":"info.getNodeVersion"
}' -H 'content-type:application/json;' http://127.0.0.1:9650/ext/info | jq .

echo -e "\n=== Test Complete ==="