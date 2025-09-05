# Simple ERC721 NFT for Avalanche L1

OpenZeppelinのERC721を継承したシンプルなNFTコントラクトをAvalanche L1にデプロイするプロジェクトです。

## 概要

このプロジェクトには以下が含まれています：

- **SimpleNFT.sol**: 誰でもmintできるパブリックなNFTコントラクト
- **デプロイスクリプト**: Avalanche L1へのデプロイ用スクリプト
- **テストコード**: コントラクトの包括的なテスト

## 前提条件

- [Foundry](https://github.com/foundry-rs/foundry)のインストール
- [Avalanche CLI](https://docs.avax.network/tooling/avalanche-cli#installation)のインストール
- Node.js & npm（オプション）

## セットアップ

1. 依存関係のインストール:
```bash
cd simple-erc721
forge install
```

2. 環境設定:
```bash
# .envファイルの作成
make setup-env
# または
cp .env.example .env
```

3. コントラクトのビルド:
```bash
make build
# または
forge build
```

4. テストの実行:
```bash
make test
# または
forge test
```

## Avalanche L1へのデプロイ手順

### 1. Avalanche L1の作成と起動

```bash
# L1の作成
avalanche blockchain create myL1

# 設定例：
# - Subnet-EVM
# - ChainID: 12345（任意の数値）
# - Token Symbol: AVAX
# - VM Version: latest

# ローカルネットワークでL1をデプロイ
avalanche blockchain deploy myL1 --local
```

### 2. RPC URLとプライベートキーの確認

デプロイ後に表示される情報から以下を確認：
- RPC URL: `http://127.0.0.1:9650/ext/bc/[BLOCKCHAIN_ID]/rpc`
- Funded Address のプライベートキー

### 3. 環境変数の設定

```bash
# .env.exampleをコピーして.envを作成
cp .env.example .env

# .envファイルを編集して以下を設定：
# - AVALANCHE_L1_RPC_URL: L1デプロイ時に表示されたRPC URL
# - PRIVATE_KEY: Funded Addressのプライベートキー
```

### 4. コントラクトのデプロイ

#### Makefileを使用（推奨）

```bash
# ローカルL1にデプロイ
make deploy-l1

# またはFujiテストネットにデプロイ
make deploy-fuji

# デプロイ後、表示されたアドレスを環境変数に設定
export NFT_ADDRESS=<deployed_address>
```

#### 手動でデプロイ

```bash
# 環境変数を読み込み
source .env

# ローカルL1にデプロイ（foundry.tomlのRPC設定を使用）
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url avalanche_l1 \
  --broadcast

# またはFujiテストネットにデプロイ
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url avalanche_fuji \
  --broadcast
```

### 5. デプロイの確認

デプロイが成功すると、コンソールに以下が表示されます：
```
SimpleNFT deployed at: 0x...
Name: Simple NFT
Symbol: SNFT
Base URI: https://api.example.com/metadata/
NFT_ADDRESS updated in .env file
```

デプロイ後、NFTアドレスは自動的に`.env`ファイルに保存されます。

## コントラクトの使用方法

### Makefileを使用した操作（推奨）

```bash
# NFTをmint（自分のアドレスに）
# デプロイ後は.envファイルからNFT_ADDRESSが自動的に読み込まれます
make mint

# 特定のアドレスにmint
make mint 0x1234...

# バッチmint（デフォルト5個）
make mint-batch

# 特定のアドレスに10個mint
make mint-batch 0x1234... 10

# NFT情報の確認
make nft-info

# 総供給量の確認
make total-supply

# 残高確認（自分の残高）
make balance

# 特定アドレスの残高確認
make balance 0x1234...

# トークンの所有者確認
make owner-of 0

# トークンURIの確認
make token-uri 0
```

### Cast（Foundry）を使用した手動操作

```bash
# 環境変数の設定
source .env
export NFT_ADDRESS="0x..." # デプロイ時に表示されたアドレス
export USER_ADDRESS="0x..." # NFTを受け取るアドレス

# NFTをmint
cast send $NFT_ADDRESS "mint(address)" $USER_ADDRESS \
  --rpc-url avalanche_l1 \
  --private-key $PRIVATE_KEY

# バッチmint（5個）
cast send $NFT_ADDRESS "mintBatch(address,uint256)" $USER_ADDRESS 5 \
  --rpc-url avalanche_l1 \
  --private-key $PRIVATE_KEY

# 総供給量の確認
cast call $NFT_ADDRESS "totalSupply()" --rpc-url avalanche_l1

# NFTの所有者確認
cast call $NFT_ADDRESS "ownerOf(uint256)" 0 --rpc-url avalanche_l1

# トークンURIの確認
cast call $NFT_ADDRESS "tokenURI(uint256)" 0 --rpc-url avalanche_l1
```

## トランザクション確認

### Makefileを使用した確認（推奨）

```bash
# トランザクション数（nonce）の確認
make tx-count
make tx-count 0x1234...

# 最新ブロック情報
make latest-block

# 現在のブロック番号
make block-number

# 現在のガス価格
make gas-price

# 特定のトランザクション詳細
make tx 0xabc123...

# トランザクションレシート
make receipt 0xabc123...
```

### Castコマンドを直接使用

```bash
# アドレスのトランザクション履歴確認
cast nonce <address> --rpc-url avalanche_l1

# ブロック情報
cast block latest --rpc-url avalanche_l1
cast block-number --rpc-url avalanche_l1

# トランザクション詳細
cast tx <tx_hash> --rpc-url avalanche_l1
cast receipt <tx_hash> --rpc-url avalanche_l1
```

### その他の確認方法

```bash
# Avalanche CLIでネットワークログを確認
avalanche network logs

# チェーンの状態確認
avalanche network status
```

## テストネットへのデプロイ

Fuji（Avalanche Testnet）にデプロイする場合：

```bash
# .envファイルにFuji用の設定を追加
# AVALANCHE_FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
# PRIVATE_KEY=your_private_key  

# 環境変数を読み込み
source .env

# Fujiにデプロイ
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url avalanche_fuji \
  --broadcast
```

## プロジェクト構造

```
simple-erc721/
├── src/
│   └── SimpleNFT.sol          # NFTコントラクト
├── script/
│   └── Deploy.s.sol           # デプロイスクリプト
├── test/
│   └── SimpleNFT.t.sol        # テストコード
├── lib/                       # 依存関係
├── foundry.toml              # Foundry設定
├── Makefile                  # Make コマンド定義
├── .env.example              # 環境変数テンプレート
└── README.md                 # このファイル
```

## カスタマイズ

### ベースURIの変更

```solidity
// Deploy.s.solでbaseURIを変更
string memory baseURI = "https://your-api.com/metadata/";
```

### mint制限の追加

現在は誰でもmintできますが、制限を追加する場合は`SimpleNFT.sol`を修正してください。

## 参考リンク

- [Avalanche Docs](https://docs.avax.network/)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)