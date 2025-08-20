#!/bin/bash

echo "最新のネットワークでAWM Relayerを起動します..."

# 1. 最新のネットワークディレクトリを特定
LATEST_NETWORK=$(ls -dt ~/.avalanche-cli/runs/network_* 2>/dev/null | head -1)

if [ -z "$LATEST_NETWORK" ]; then
    echo "エラー: ネットワークディレクトリが見つかりません"
    exit 1
fi

echo "最新のネットワーク: $LATEST_NETWORK"

# 2. AWM Relayer設定ファイルを探す
RELAYER_CONFIG="$LATEST_NETWORK/icm-relayer-config.json"

if [ ! -f "$RELAYER_CONFIG" ]; then
    echo "エラー: AWM Relayer設定ファイルが見つかりません: $RELAYER_CONFIG"
    echo "avalanche local deploy コマンドでネットワークを作成してください"
    exit 1
fi

# 3. 現在実行中のRelayerを確認
if pgrep -f "icm-relayer" > /dev/null; then
    echo "警告: AWM Relayerが既に実行中です"
    echo "既存のプロセスを停止しますか？(y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        pkill -f "icm-relayer"
        sleep 2
    else
        echo "起動をキャンセルしました"
        exit 0
    fi
fi

# 4. AWM Relayerのバイナリを確認
RELAYER_BIN=$(find ~/.avalanche-cli/bin/icm-relayer -name "icm-relayer" -type f | head -1)

if [ -z "$RELAYER_BIN" ] || [ ! -x "$RELAYER_BIN" ]; then
    echo "エラー: AWM Relayerバイナリが見つかりません"
    echo "avalanche-cliをインストールしてください"
    exit 1
fi

echo "AWM Relayerバイナリ: $RELAYER_BIN"

# 5. AWM Relayerを起動
echo "AWM Relayerを起動中..."
echo "設定ファイル: $RELAYER_CONFIG"

# バックグラウンドで起動
nohup "$RELAYER_BIN" --config-file "$RELAYER_CONFIG" > ~/awm-relayer.log 2>&1 &

echo "AWM RelayerをPID $! で起動しました"
echo "ログファイル: ~/awm-relayer.log"

# 6. 起動確認
sleep 3
if pgrep -f "icm-relayer" > /dev/null; then
    echo "✅ AWM Relayerが正常に起動しました"
    echo ""
    echo "ログを確認するには:"
    echo "  tail -f ~/awm-relayer.log"
else
    echo "❌ AWM Relayerの起動に失敗しました"
    echo "ログを確認してください:"
    tail -20 ~/awm-relayer.log
fi