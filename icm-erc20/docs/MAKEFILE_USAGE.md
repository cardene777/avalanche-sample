# Makefile 使用ガイド

このガイドでは、ICM ERC20プロジェクトのMakefileコマンドの詳細な使用方法を説明します。

## 概要

Makefileを使用することで、複雑なコマンドをシンプルに実行できます。すべてのコマンドは`.env`ファイルの設定を自動的に読み込みます。

## コマンド一覧

### 1. デプロイ

```bash
make deploy
```
Chain1とChain2にTeleporterERC20をデプロイし、相互接続を設定します。

### 2. mint - トークンの発行

#### 基本使用法
```bash
make mint  # Chain1にデフォルト量（1000トークン）をmint
```

#### パラメータ指定
```bash
# Chain2にmint
make mint CHAIN=2

# 特定のアドレスにmint
make mint TO=0x1234567890123456789012345678901234567890

# カスタム量でmint（wei単位）
make mint AMOUNT=5000000000000000000000  # 5000トークン

# すべてのパラメータを指定
make mint CHAIN=2 TO=0x1234... AMOUNT=2000000000000000000000
```

#### パラメータ説明
- `CHAIN`: 対象チェーン（1 または 2）デフォルト: 1
- `TO`: 受信者アドレス。デフォルト: DEFAULT_RECIPIENT（.envで定義）
- `AMOUNT`: mint量（wei単位）。デフォルト: 1000 * 10^18

### 3. balance - 残高確認

#### 基本使用法
```bash
make balance  # 両チェーンのデフォルトアドレスの残高を確認
```

#### パラメータ指定
```bash
# Chain1のみ確認
make balance CHAIN=1

# Chain2の特定アドレスを確認
make balance CHAIN=2 ADDRESS=0x1234...

# 特定アドレスの両チェーン残高
make balance ADDRESS=0x1234567890123456789012345678901234567890
```

#### パラメータ説明
- `CHAIN`: 対象チェーン（1、2、または all）デフォルト: all
- `ADDRESS`: 確認するアドレス。デフォルト: DEFAULT_RECIPIENT

### 4. transfer - クロスチェーン転送

#### 基本使用法
```bash
make transfer FROM=1 TO=2  # Chain1からChain2へデフォルト量（100トークン）を転送
```

#### パラメータ指定
```bash
# Chain2からChain1へ転送
make transfer FROM=2 TO=1

# 特定のアドレスへ転送
make transfer FROM=1 TO=2 ADDRESS=0x1234...

# カスタム量で転送
make transfer FROM=1 TO=2 TRANSFER_AMOUNT=200000000000000000000  # 200トークン

# すべてのパラメータを指定
make transfer FROM=1 TO=2 ADDRESS=0x1234... TRANSFER_AMOUNT=50000000000000000000
```

#### パラメータ説明
- `FROM`: 送信元チェーン（1 または 2）デフォルト: 1
- `TO`: 送信先チェーン（1 または 2）必須パラメータ
- `ADDRESS`: 受信者アドレス。デフォルト: DEFAULT_RECIPIENT
- `TRANSFER_AMOUNT`: 転送量（wei単位）。デフォルト: 100 * 10^18

### 5. その他のコマンド

```bash
make help   # ヘルプメッセージを表示
make clean  # キャッシュとビルドファイルをクリーン
```

## 実践的な使用例

### シナリオ1: 基本的なトークン操作

```bash
# 1. Chain1でトークンをmint
make mint

# 2. 残高を確認
make balance

# 3. Chain2へ50トークンを転送
make transfer FROM=1 TO=2 TRANSFER_AMOUNT=50000000000000000000

# 4. 転送後の残高を確認
make balance
```

### シナリオ2: 複数アドレスの管理

```bash
# アドレスAにmint
make mint TO=0xAAAA... AMOUNT=1000000000000000000000

# アドレスBにmint
make mint TO=0xBBBB... AMOUNT=2000000000000000000000

# 各アドレスの残高確認
make balance ADDRESS=0xAAAA...
make balance ADDRESS=0xBBBB...

# アドレスAからアドレスCへ転送
make transfer FROM=1 TO=2 ADDRESS=0xCCCC... TRANSFER_AMOUNT=500000000000000000000
```

### シナリオ3: Chain2での操作

```bash
# Chain2でmint
make mint CHAIN=2 AMOUNT=10000000000000000000000

# Chain2の残高確認
make balance CHAIN=2

# Chain2からChain1へ転送
make transfer FROM=2 TO=1 TRANSFER_AMOUNT=1000000000000000000000
```

## トラブルシューティング

### "Error: FROM must be 1 or 2"
- `FROM`パラメータは1または2のみ指定可能です

### "Error: TO must be 2 when FROM is 1"
- Chain1から転送する場合、宛先は必ずChain2（TO=2）である必要があります

### 転送が失敗する場合
1. 送信元チェーンに十分な残高があるか確認：`make balance CHAIN=<FROM>`
2. AWM Relayerが稼働しているか確認：`ps aux | grep icm-relayer`
3. `.env`ファイルの設定が正しいか確認

## wei単位について

すべての金額はwei単位で指定します：
- 1 トークン = 1,000,000,000,000,000,000 wei (10^18 wei)
- 100 トークン = 100,000,000,000,000,000,000 wei
- 1000 トークン = 1,000,000,000,000,000,000,000 wei

## 環境変数

Makefileは`.env`ファイルから以下の変数を読み込みます：
- `PRIVATE_KEY`: トランザクション署名用の秘密鍵
- `CHAIN1_RPC_URL`, `CHAIN2_RPC_URL`: 各チェーンのRPC URL
- `CHAIN1_TOKEN_ADDRESS`, `CHAIN2_TOKEN_ADDRESS`: 各チェーンのトークンアドレス
- `CHAIN1_BLOCKCHAIN_ID`, `CHAIN2_BLOCKCHAIN_ID`: 各チェーンのID
- `DEFAULT_RECIPIENT`: デフォルトの受信者アドレス