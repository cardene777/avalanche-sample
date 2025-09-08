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

## コマンド実行方法

全てのコマンドは引数でチェーンを指定する方式に統一されています。

### 利用可能なチェーン

- `c-chain` - Fuji C-Chain
- `dispatch` - Fuji Dispatch
- `l1-1` - ローカルL1チェーン 1
- `l1-2` - ローカルL1チェーン 2

### コントラクトのデプロイ

#### 全てのコントラクトをデプロイ

```bash
# Fujiテストネットへデプロイ
make deploy-all fuji

# ローカルチェーンへデプロイ
make deploy-all local
```

#### 個別のコントラクトをデプロイ

```bash
# TeleporterERC20トークンをデプロイ
make deploy-token c-chain
make deploy-token dispatch
make deploy-token l1-1
make deploy-token l1-2

# SimpleSenderをデプロイ（送信元チェーンのみ）
make deploy-sender c-chain
make deploy-sender l1-1

# SimpleReceiverをデプロイ（受信先チェーンのみ）
make deploy-receiver dispatch
make deploy-receiver l1-2
```

デプロイ後、アドレスは自動的に.envファイルに更新されます。

### トークン操作

#### Mint（100トークン）

```bash
make mint c-chain
make mint dispatch
make mint l1-1
make mint l1-2
```

#### 残高確認

```bash
# デフォルトアドレス（SENDER_ADDRESS）の残高確認
make balance c-chain
make balance l1-1

# 特定アドレスの残高確認
make balance c-chain 0x1234...
make balance l1-2 0x5678...
```

#### クロスチェーン転送（10トークン）

```bash
# Fujiテストネット間
make send-tokens c-chain dispatch
make send-tokens dispatch c-chain

# ローカルチェーン間
make send-tokens l1-1 l1-2
make send-tokens l1-2 l1-1

# クロス環境転送も可能（設定が正しければ）
make send-tokens c-chain l1-1
```

### シンプルメッセージ送信

#### メッセージ送信

```bash
# Fujiテストネット
make send-message c-chain dispatch

# ローカルチェーン
make send-message l1-1 l1-2
```

#### メッセージ確認

```bash
make check-message dispatch
make check-message l1-2
```

## ローカルL1環境での実行

### 前提条件

2つのローカルL1を起動し、ICMを有効化する必要があります。

```bash
# L1の作成（例）
avalanche blockchain create myL1
avalanche blockchain create myL2

# ローカルにデプロイ（ICMを有効化）
avalanche blockchain deploy myL1 --local
avalanche blockchain deploy myL2 --local

# ICMの設定（相互接続）
# デプロイ後に表示される情報をもとにICMを設定
```

### 環境変数の設定

.envファイルにローカルL1の設定を追加：

```bash
# avalanche blockchain describeコマンドでRPC URLとBlockchain IDを確認
avalanche blockchain describe myL1
avalanche blockchain describe myL2

# .envファイルを更新
# LOCAL_L1_1_RPC_URL=http://127.0.0.1:9650/ext/bc/{L1-1のBlockchainID}/rpc
# LOCAL_L1_2_RPC_URL=http://127.0.0.1:9650/ext/bc/{L1-2のBlockchainID}/rpc
# LOCAL_L1_1_BLOCKCHAIN_ID_HEX=0x{L1-1のBlockchainIDの16進数}
# LOCAL_L1_2_BLOCKCHAIN_ID_HEX=0x{L1-2のBlockchainIDの16進数}
```

**重要**: ローカル環境では、自動的にAvalancheのプリファンドされたテストアカウント（ewoqキー）が使用されます。.envファイルの`PK`は使用されません。

### ローカル環境でのコマンド実行例

```bash
# 全てのコントラクトをデプロイ
make deploy-all local

# トークンをmint
make mint l1-1
make mint l1-2

# 残高確認
make balance l1-1
make balance l1-2

# クロスチェーン転送
make send-tokens l1-1 l1-2
make send-tokens l1-2 l1-1

# メッセージ送信と確認
make send-message l1-1 l1-2
make check-message l1-2
```

## 手動実行方法（参考）

### 環境変数読み込み

```bash
source .env
```

### トークンのデプロイ（手動）

```bash
# Fuji C-Chain
forge create --rpc-url fuji-c --private-key $PK src/TeleporterERC20.sol:TeleporterERC20 --broadcast --constructor-args "FujiCToken" "FCT" "0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf"

# Fuji Dispatch
forge create --rpc-url fuji-dispatch --private-key $PK src/TeleporterERC20.sol:TeleporterERC20 --broadcast --constructor-args "FujiDispatchToken" "FDT" "0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf"
```

### トークン操作（手動）

環境変数にデプロイしたアドレスが設定されている前提：

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
- `make deploy-all [fuji|local]` - 全コントラクトのデプロイ
- `make deploy-token [chain]` - TeleporterERC20トークンコントラクトのデプロイ
- `make deploy-sender [chain]` - SimpleSenderコントラクトのデプロイ
- `make deploy-receiver [chain]` - SimpleReceiverコントラクトのデプロイ

### トークン操作
- `make mint [chain]` - 100トークンをmint
- `make balance [chain] [address]` - 残高確認
- `make send-tokens [from-chain] [to-chain]` - 10トークンを転送

### メッセージ操作
- `make send-message [from-chain] [to-chain]` - テストメッセージを送信
- `make check-message [chain]` - 最後に受信したメッセージを確認

## Faucet

https://core.app/tools/testnet-faucet/?subnet=dispatch&token=dispatch

## References

- [Testnet Teleporter Address Explorer](https://testnet.snowtrace.io/address/0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
- [Avalanche Academy Interchain Messaging](https://build.avax.network/academy/interchain-messaging)
- [Avalanche Academy Interchain Token Transfer](https://build.avax.network/academy/interchain-token-transfer)
- [avalanche-starter-kit](https://github.com/ava-labs/avalanche-starter-kit/tree/interchain-messaging)
- [icm-contracts](https://github.com/ava-labs/icm-contracts/tree/main)