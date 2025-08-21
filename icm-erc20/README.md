# ICM ERC20 Testnet

Avalanche ICM（Interchain Messaging）を使用したERC20トークンのクロスチェーン転送実装です。

## セットアップ

1. 依存関係のインストール

```bash
forge install
```

2. 環境変数の設定

```bash
cp .env.example .env
# .envファイルを編集して秘密鍵などを設定
```

3. ビルド

```bash
make build
```

4. テスト実行

```bash
make test
```

## 自動デプロイとコマンド実行

### コントラクトのデプロイ

```bash
# 全てのコントラクトをデプロイ
make deploy-all

# トークンコントラクトのみデプロイ
make deploy-tokens

# SimpleSender/SimpleReceiverコントラクトのみデプロイ
make deploy-simple-contracts

# ※ デプロイ後、アドレスは自動的に.envファイルに更新されます
```

### 個別デプロイ

```bash
# TeleporterERC20のデプロイ
# Fuji C-Chain
make deploy-teleporter-c
# Fuji Dispatch
make deploy-teleporter-dispatch

# SimpleSender/SimpleReceiverのデプロイ
# SimpleSender on Fuji C-Chain
make deploy-sender-c
SimpleReceiver on Fuji Dispatch
make deploy-receiver-dispatch
```

### トークン操作

```bash
# Mint
# Fuji C-Chainでmint (100トークン)
make mint-c
# Fuji Dispatchでmint (100トークン)
make mint-dispatch

# 残高確認
# Fuji C-Chainの残高（デフォルトはSENDER_ADDRESS）
make balance-c
# 特定のアドレスの残高を確認
make balance-c 0x1234...
# または環境変数で指定
ADDRESS=0x1234... make balance-c

# Fuji Dispatchの残高（デフォルトはSENDER_ADDRESS）
make balance-dispatch
# 特定のアドレスの残高を確認
make balance-dispatch 0x1234...
# または環境変数で指定
ADDRESS=0x1234... make balance-dispatch

# クロスチェーン転送
# C-Chain → Dispatch (10トークン)
make send-tokens-c-to-dispatch
# Dispatch → C-Chain (10トークン)
make send-tokens-dispatch-to-c
```

### シンプルメッセージ送信

```bash
# メッセージ送信
make send-message-c-to-dispatch

# 受信確認
make check-message-dispatch
```

## 手動実行方法

### 環境変数読み込み

```bash
source .env
```

### 残高の確認

```bash
# Check balance on Fuji C-Chain
cast balance $FUNDED_ADDRESS --rpc-url fuji-c

# Check balance on Dispatch
cast balance $FUNDED_ADDRESS --rpc-url fuji-dispatch
```

### デプロイ (手動)

- Fuji C

```bash
forge create --rpc-url fuji-c --private-key $PK src/TeleporterERC20.sol:TeleporterERC20 --broadcast --constructor-args "FujiCToken" "FCT" "0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf"
```

- Fuji Dispatch

```bash
forge create --rpc-url fuji-dispatch --private-key $PK src/TeleporterERC20.sol:TeleporterERC20 --broadcast --constructor-args "FujiDispatchToken" "FDT" "0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf"
```

### トークン操作 (手動)

環境変数にデプロイしたアドレスが設定されている前提（.envファイルに自動更新されます）：

**ウォレットアドレス:**
- `SENDER_ADDRESS`: トークン送付元のウォレットアドレス
- `RECEIVER_ADDRESS`: トークン送付先のウォレットアドレス

**TeleporterERC20トークンコントラクト:**
- `FUJI_C_TOKEN_ADDRESS`: Fuji C-Chain上のTeleporterERC20トークンコントラクト
- `FUJI_DISPATCH_TOKEN_ADDRESS`: Fuji Dispatch上のTeleporterERC20トークンコントラクト

**SimpleSender/SimpleReceiverコントラクト:**
- `FUJI_C_SIMPLE_SENDER_CONTRACT_ADDRESS`: Fuji C-Chain上のSimpleSenderコントラクト
- `FUJI_DISPATCH_SIMPLE_RECEIVER_CONTRACT_ADDRESS`: Fuji Dispatch上のSimpleReceiverコントラクト

```bash
# Mint on Fuji C-Chain
cast send --rpc-url fuji-c --private-key $PK $FUJI_C_TOKEN_ADDRESS "mint(address,uint256)" $SENDER_ADDRESS 100000000000000000000

# Check balance
cast call --rpc-url fuji-c $FUJI_C_TOKEN_ADDRESS "balanceOf(address)(uint256)" $SENDER_ADDRESS

# Send tokens from C-Chain to Dispatch
cast send --rpc-url fuji-c --private-key $PK $FUJI_C_TOKEN_ADDRESS "sendTokens(bytes32,address,address,uint256)" $FUJI_DISPATCH_BLOCKCHAIN_ID_HEX $FUJI_DISPATCH_TOKEN_ADDRESS $RECEIVER_ADDRESS 10000000000000000000
```

## 利用可能なMakeコマンド

```bash
make help  # 全コマンドの一覧を表示
```

### 基本コマンド
- `make build` - コントラクトのビルド
- `make test` - テストの実行
- `make coverage` - テストカバレッジ
- `make format` - コードフォーマット
- `make clean` - ビルドアーティファクトのクリーン

### デプロイコマンド
- `make deploy-all` - 全コントラクトのデプロイ
- `make deploy-tokens` - TeleporterERC20トークンコントラクトのみデプロイ
- `make deploy-simple-contracts` - SimpleSender/SimpleReceiverコントラクトのみデプロイ
- `make deploy-teleporter-c` - TeleporterERC20をFuji C-Chainにデプロイ
- `make deploy-teleporter-dispatch` - TeleporterERC20をFuji Dispatchにデプロイ
- `make deploy-sender-c` - SimpleSenderをFuji C-Chainにデプロイ
- `make deploy-receiver-dispatch` - SimpleReceiverをFuji Dispatchにデプロイ

### トークン操作
- `make mint-c` - Fuji C-Chainでトークンをmint
- `make mint-dispatch` - Fuji Dispatchでトークンをmint
- `make balance-c` - Fuji C-Chainの残高確認
- `make balance-dispatch` - Fuji Dispatchの残高確認
- `make send-tokens-c-to-dispatch` - C-ChainからDispatchへトークン送信
- `make send-tokens-dispatch-to-c` - DispatchからC-Chainへトークン送信

### メッセージ操作
- `make send-message-c-to-dispatch` - C-ChainからDispatchへメッセージ送信
- `make check-message-dispatch` - Dispatchで最後のメッセージを確認

## Faucet

https://core.app/tools/testnet-faucet/?subnet=dispatch&token=dispatch

## References

- [Testnet Teleporter Address Explorer](https://testnet.snowtrace.io/address/0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
- [Avalanche Academy Interchain Messaging](https://build.avax.network/academy/interchain-messaging)
- [Avalanche Academy Interchain Token Transfer](https://build.avax.network/academy/interchain-token-transfer)
- [avalanche-starter-kit](https://github.com/ava-labs/avalanche-starter-kit/tree/interchain-messaging)
- [icm-contracts](https://github.com/ava-labs/icm-contracts/tree/main)