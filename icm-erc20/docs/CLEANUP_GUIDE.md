# クリーンアップガイド

## 完全クリーンアップ手順

### 1. プロセス停止

```bash
# AWM Relayer停止
pkill -f icm-relayer

# Avalancheノード停止
pkill -f avalanchego
```

### 2. データ削除

```bash
# ローカルネットワークデータ
rm -rf ~/.avalanche-cli/runs/network_*
rm -rf ~/.avalanche-cli/local/*

# サブネットデータ
rm -rf ~/.avalanche-cli/subnets/*

# ログファイル
rm -f ~/awm-relayer*.log
rm -f ~/chain*.log
```

### 3. 完全リセット

```bash
# 自動クリーンアップスクリプト
./scripts/complete-cleanup.sh
```

## 部分的なクリーンアップ

### AWM Relayerのみリセット

```bash
pkill -f icm-relayer
rm -rf ~/.avalanche-cli/runs/LocalNetwork/local-relayer/icm-relayer-storage
```

### 特定のチェーンのみ削除

```bash
avalanche blockchain delete chain1 --force
avalanche blockchain delete chain2 --force
```