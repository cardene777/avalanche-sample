# トークン転送ガイド

## 概要

Chain1とChain2間でERC20トークンを転送するための完全ガイドです。

## 前提条件

1. `.env`ファイルが設定済み（デプロイ後の値が保存されている）
2. AWM Relayerが稼働中
3. Chain1とChain2が起動済み

## 手順

### 1. 環境確認

```bash
# ノード状態確認
ps aux | grep avalanchego | wc -l
# 期待値: 4以上

# AWM Relayer確認
ps aux | grep icm-relayer | wc -l
# 期待値: 1以上
```

### 2. トークンMint

```bash
# Chain1でmint（デフォルト）
make mint

# Chain2でmint
make mint CHAIN=2

# 特定のアドレスに特定量をmint
make mint CHAIN=1 TO=0x1234... AMOUNT=5000000000000000000000

# 詳細は docs/MAKEFILE_USAGE.md を参照
```

### 3. 残高確認

```bash
# 両チェーンの残高確認
make balance

# 特定チェーンの特定アドレス
make balance CHAIN=1 ADDRESS=0x1234...

# 詳細は docs/MAKEFILE_USAGE.md を参照
```

### 4. クロスチェーン転送

```bash
# Chain1からChain2へ転送
make transfer FROM=1 TO=2

# カスタム量とアドレスで転送
make transfer FROM=1 TO=2 ADDRESS=0x1234... TRANSFER_AMOUNT=200000000000000000000

# 詳細は docs/MAKEFILE_USAGE.md を参照
```

### 5. 転送後の残高確認

```bash
# 転送完了を待つ（約10-30秒）
sleep 15

# 両チェーンの残高を確認
make balance
```

## Makefileコマンドリファレンス

詳細な使用方法については [MAKEFILE_USAGE.md](./MAKEFILE_USAGE.md) を参照してください。

### よく使うコマンド

```bash
# トークン操作
make mint CHAIN=1                     # Chain1でmint
make balance                          # 残高確認
make transfer FROM=1 TO=2             # 転送

# パラメータ指定の例
make mint CHAIN=2 TO=0x1234... AMOUNT=5000000000000000000000
make balance CHAIN=1 ADDRESS=0x1234...
make transfer FROM=1 TO=2 ADDRESS=0x1234... TRANSFER_AMOUNT=100000000000000000000
```

## トラブルシューティング

### よくあるエラーと解決方法

#### 1. "insufficient balance"エラー
- 原因: トークンが不足
- 解決: 上記のMint手順を実行

#### 2. "timeout waiting for message"エラー
- 原因: AWM Relayerが動作していない
- 解決: `~/awm-relayer-direct.log`を確認し、必要に応じて再起動

#### 3. RPC接続エラー
- 原因: ノードが起動していない
- 解決: `ps aux | grep avalanchego`で確認し、必要に応じてノードを起動

## 重要な注意事項

1. **Mint権限**: TeleporterERC20のmint関数は誰でも呼べる設定になっています（本番環境では要変更）
2. **ガス代**: 各チェーンでの操作にはガス代が必要です
3. **AWM Relayer**: クロスチェーン転送にはAWM Relayerが必須です