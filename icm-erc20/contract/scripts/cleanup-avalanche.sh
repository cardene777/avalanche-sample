#!/bin/bash

echo "Avalancheプロセスのクリーンアップを開始します..."

# 1. AWM Relayerを停止
echo "AWM Relayerを停止中..."
pkill -f "icm-relayer" || true

# 2. Avalancheノードを停止
echo "Avalancheノードを停止中..."
pkill -f "avalanchego" || true

# 3. プロセスが完全に停止するまで待機
echo "プロセスの停止を待機中..."
sleep 3

# 4. 残っているプロセスがないか確認
remaining_processes=$(ps aux | grep -E "(avalanchego|icm-relayer)" | grep -v grep | wc -l)
if [ $remaining_processes -gt 0 ]; then
    echo "警告: まだ実行中のプロセスがあります:"
    ps aux | grep -E "(avalanchego|icm-relayer)" | grep -v grep
    echo "強制終了を試みます..."
    pkill -9 -f "avalanchego" || true
    pkill -9 -f "icm-relayer" || true
    sleep 2
fi

# 5. 古いネットワークディレクトリを削除（オプション）
echo "古いネットワークディレクトリを削除しますか？(y/n)"
read -r response
if [[ "$response" == "y" ]]; then
    echo "古いネットワークディレクトリを削除中..."
    # 古い実行ディレクトリを削除
    find ~/.avalanche-cli/runs -name "network_*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
    echo "1日以上前のネットワークディレクトリを削除しました"
fi

# 6. 最終確認
echo ""
echo "クリーンアップ完了。現在のプロセス状態:"
ps aux | grep -E "(avalanchego|icm-relayer)" | grep -v grep || echo "Avalanche関連のプロセスは実行されていません"

echo ""
echo "現在のネットワークディレクトリ:"
ls -la ~/.avalanche-cli/runs/network_* 2>/dev/null | tail -5 || echo "ネットワークディレクトリが見つかりません"