#!/bin/bash

echo "Avalanche環境の完全クリーンアップを開始します..."
echo ""
echo "このスクリプトは以下を実行します："
echo "1. 全てのAvalancheプロセスを停止"
echo "2. ローカルネットワークデータを削除"
echo "3. 実行ログを削除"
echo "4. サブネット設定を削除"
echo ""
echo "続行しますか？ (y/n)"
read -r response
if [[ "$response" != "y" ]]; then
    echo "キャンセルしました"
    exit 0
fi

# 1. プロセスの停止
echo ""
echo "=== ステップ1: プロセスの停止 ==="
echo "Avalancheプロセスを停止中..."
pkill -f "avalanchego" || true
pkill -f "icm-relayer" || true
sleep 3

# 残っているプロセスを確認
remaining=$(ps aux | grep -E "(avalanchego|icm-relayer)" | grep -v grep | wc -l)
if [ $remaining -gt 0 ]; then
    echo "警告: まだプロセスが残っています。強制終了します..."
    pkill -9 -f "avalanchego" || true
    pkill -9 -f "icm-relayer" || true
    sleep 2
fi

# 2. ローカルネットワークデータの削除
echo ""
echo "=== ステップ2: ローカルネットワークデータの削除 ==="
if [ -d ~/.avalanche-cli/local ]; then
    echo "ローカルネットワークデータを削除中..."
    rm -rf ~/.avalanche-cli/local/*
    echo "✓ ローカルデータを削除しました"
fi

# 3. 実行ログの削除
echo ""
echo "=== ステップ3: 実行ログの削除 ==="
if [ -d ~/.avalanche-cli/runs ]; then
    echo "実行ログを削除中..."
    rm -rf ~/.avalanche-cli/runs/*
    echo "✓ 実行ログを削除しました"
fi

# 4. サブネット設定の削除
echo ""
echo "=== ステップ4: サブネット設定の削除 ==="
if [ -d ~/.avalanche-cli/subnets ]; then
    echo "サブネット設定を削除中..."
    rm -rf ~/.avalanche-cli/subnets/*
    echo "✓ サブネット設定を削除しました"
fi

# 5. その他のクリーンアップ
echo ""
echo "=== ステップ5: その他のクリーンアップ ==="
# localNetworks.jsonをリセット
if [ -f ~/.avalanche-cli/localNetworks.json ]; then
    echo "{}" > ~/.avalanche-cli/localNetworks.json
    echo "✓ localNetworks.jsonをリセットしました"
fi

# ホームディレクトリのログファイルを削除
if [ -f ~/awm-relayer.log ]; then
    rm ~/awm-relayer.log
    echo "✓ AWM Relayerログを削除しました"
fi

# 6. 最終確認
echo ""
echo "=== クリーンアップ完了 ==="
echo ""
echo "プロセス状態:"
ps aux | grep -E "(avalanchego|icm-relayer)" | grep -v grep || echo "✓ Avalanche関連のプロセスは実行されていません"
echo ""
echo "ディレクトリ状態:"
echo "~/.avalanche-cli/local/: $(ls ~/.avalanche-cli/local 2>/dev/null | wc -l) items"
echo "~/.avalanche-cli/runs/: $(ls ~/.avalanche-cli/runs 2>/dev/null | wc -l) items"
echo "~/.avalanche-cli/subnets/: $(ls ~/.avalanche-cli/subnets 2>/dev/null | wc -l) items"