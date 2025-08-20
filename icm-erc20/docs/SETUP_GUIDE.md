# セットアップガイド

## 前提条件

- Avalanche CLI インストール済み
- Foundry (forge, cast) インストール済み
- ローカルネットワーク起動済み

## 初期セットアップ

### 1. ネットワーク起動

```bash
# プライマリネットワーク起動
avalanche network start

# Chain1とChain2の起動
# (既に起動済みの場合はスキップ)
```

### 2. AWM Relayer設定

```bash
# AWM Relayer設定スクリプト実行
cd /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20
./scripts/create-relayer-config-direct.sh

# ログ確認
tail -f ~/awm-relayer-direct.log
```

### 3. 環境変数設定

`.env`ファイルまたはシェルで設定：

```bash
export PRIVATE_KEY=0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
export CHAIN1_RPC=http://127.0.0.1:52580/ext/bc/AuMfnjkj2xDWZ7GXmn4Ao5itfabyQzJszXSCt9LGzQaBSLZGE/rpc
export CHAIN2_RPC=http://127.0.0.1:52696/ext/bc/a5rUdMSZGBvAQKxxsK8PdVKBJrKC1n9qv9vRvW4rir54oDuRB/rpc
```

## コントラクトアドレス一覧

保存しておくべき重要なアドレス：

```bash
# Chain1
CHAIN1_TOKEN=0x8b3bc4270be2abbb25bc04717830bd1cc493a461
CHAIN1_BRIDGE=0x5aa01b3b5877255ce50cc55e8986a7a5fe29c70e

# Chain2
CHAIN2_TOKEN=0xa4dff80b4a1d748bf28bc4a271ed834689ea3407
CHAIN2_BRIDGE=0x52c84043cd9c865236f11d9fc9f56aa003c1f922
```

## 次のステップ

[TOKEN_TRANSFER_GUIDE.md](./TOKEN_TRANSFER_GUIDE.md)を参照して、トークン転送を開始してください。