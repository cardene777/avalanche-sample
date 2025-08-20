# ICM ERC20 - Avalanche Cross-Chain Token Transfer

Chain1とChain2間でERC20トークンを転送するプロジェクトです。

## クイックスタート

### 1. 初回セットアップ

```bash
# .envファイルを確認・編集（必要に応じて）
cat .env

# TeleporterERC20をデプロイ
make deploy
```

### 2. トークン操作

```bash
# Chain1でトークンをMint（デフォルト: 1000トークン）
make mint

# 特定のチェーン・アドレスを指定してMint
make mint CHAIN=2 TO=0x1234... AMOUNT=5000000000000000000000

# 残高確認（両チェーン）
make balance

# 特定のチェーン・アドレスの残高確認
make balance CHAIN=1 ADDRESS=0x1234...

# Chain1からChain2へ転送（デフォルト: 100トークン）
make transfer FROM=1 TO=2

# 特定のアドレス・金額で転送
make transfer FROM=1 TO=2 ADDRESS=0x1234... TRANSFER_AMOUNT=50000000000000000000
```

### 使用可能なコマンド

```bash
make help  # 全コマンド一覧を表示
```

## ドキュメント

- [Makefile使用ガイド](./docs/MAKEFILE_USAGE.md) - 全コマンドの詳細説明
- [セットアップガイド](./docs/SETUP_GUIDE.md) - 初期設定
- [トークン転送ガイド](./docs/TOKEN_TRANSFER_GUIDE.md) - 詳細な転送手順
- [TeleporterERC20デプロイガイド](./docs/TELEPORTER_DEPLOY_GUIDE.md) - デプロイ手順
- [クリーンアップガイド](./docs/CLEANUP_GUIDE.md) - 環境のリセット

## プロジェクト構造

```
icm-erc20/
├── contract/               # Solidityコントラクト
├── scripts/               # ユーティリティスクリプト
│   ├── create-relayer-config-direct.sh  # AWM Relayer設定
│   ├── mint-and-transfer.sh            # Mint補助スクリプト
│   └── complete-cleanup.sh             # クリーンアップ
└── docs/                  # ドキュメント
```

## 重要なアドレス

| 項目 | Chain1 | Chain2 |
|------|--------|--------|
| Token | 0x8b3bc4270be2abbb25bc04717830bd1cc493a461 | 0xa4dff80b4a1d748bf28bc4a271ed834689ea3407 |
| Bridge | 0x5aa01b3b5877255ce50cc55e8986a7a5fe29c70e | 0x52c84043cd9c865236f11d9fc9f56aa003c1f922 |