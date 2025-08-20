#!/bin/bash

echo "=== AWM Relayer Status Check ==="
echo ""

# Relayerプロセスの確認
echo "Checking AWM Relayer process..."
RELAYER_PID=$(ps aux | grep -E "[a]wm-relayer|[r]elayer" | grep -v grep | head -1)
if [ -n "$RELAYER_PID" ]; then
    echo "✓ AWM Relayer is running:"
    echo "$RELAYER_PID" | head -1
else
    echo "✗ AWM Relayer is not running"
    echo ""
    echo "To check if relayer should be running:"
    echo "1. Check avalanche-cli network status: avalanche network status"
    echo "2. Look for AWM relayer configuration"
fi

echo ""
echo "Checking AWM Relayer logs..."
# 最新のネットワーク実行ディレクトリを探す
LATEST_RUN=$(ls -td ~/.avalanche-cli/runs/network_* 2>/dev/null | head -1)
if [ -n "$LATEST_RUN" ]; then
    echo "Latest network run: $LATEST_RUN"
    
    # AWM Relayerのログファイルを探す
    RELAYER_LOG=$(find "$LATEST_RUN" -name "*relayer*.log" -o -name "*awm*.log" 2>/dev/null | head -1)
    if [ -n "$RELAYER_LOG" ]; then
        echo "Found relayer log: $RELAYER_LOG"
        echo ""
        echo "=== Last 20 lines of AWM Relayer log ==="
        tail -20 "$RELAYER_LOG"
    else
        echo "No AWM Relayer log found in $LATEST_RUN"
    fi
else
    echo "No network run directory found"
fi

echo ""
echo "=== Network Status ==="
avalanche network status 2>/dev/null || echo "Failed to get network status"