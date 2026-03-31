# ICTT ERC20 コントラクト

## 概要

このプロジェクトは、Avalanche Interchain Messaging（ICM）を使用したクロスチェーンERC20トークン転送を実現するコントラクト群です。
Foundryを使用して開発されています。

## プロジェクト構成

### コントラクト

- **ERC20TokenHome**: 送信元チェーン（Home）側のコントラクト
- **ERC20TokenRemote**: 受信先チェーン（Remote）側のコントラクト
- **SampleERC20**: 誰でもミント可能なサンプルERC20トークン

### テストファイル

- `test/ERC20TokenHomeTests.t.sol`: TokenHomeコントラクトのテスト
- `test/ERC20TokenRemoteTests.t.sol`: TokenRemoteコントラクトのテスト
- `test/ExampleERC20DecimalsTests.t.sol`: ERC20のdecimals機能のテスト

詳細なテスト項目については[TEST.md](./TEST.md)を参照してください。

## Foundryについて

**Foundryは、Rustで書かれた高速でポータブル、モジュラーなEthereumアプリケーション開発ツールキットです。**

Foundryの構成要素：

- **Forge**: Ethereum テスティングフレームワーク（Truffle、Hardhat、DappToolsに相当）
- **Cast**: EVMスマートコントラクトとのやり取り、トランザクション送信、チェーンデータ取得用のスイスアーミーナイフ
- **Anvil**: ローカルEthereumノード（Ganache、Hardhat Networkに相当）
- **Chisel**: 高速で実用的、詳細なSolidity REPL

## ドキュメント

https://book.getfoundry.sh/

## 使い方

### ビルド

```shell
forge build
```

### テスト

```shell
# すべてのテストを実行
forge test

# 詳細出力でテストを実行
forge test -vv

# 特定のテストを実行
forge test --match-test testDecimals
```

### フォーマット

```shell
forge fmt
```

### ガススナップショット

```shell
forge snapshot
```

### ローカルノードの起動（Anvil）

```shell
anvil
```

### デプロイ

```shell
# Home側（ERC20 + TokenHome）
forge script script/Deploy.s.sol:DeployHome --rpc-url home --broadcast

# Remote側（TokenRemote）
forge script script/Deploy.s.sol:DeployRemote --rpc-url remote --broadcast
```

詳細なコマンドは[COMMAND.md](./COMMAND.md)を参照してください。

### Cast（チェーンとのやり取り）

```shell
cast <subcommand>
```

### ヘルプ

```shell
forge --help
anvil --help
cast --help
```

## RPC設定

`foundry.toml`に以下のRPCエンドポイントが定義されています：

| エイリアス | 説明 |
|-----------|------|
| `home` | Homeチェーン（`.env`の`HOME_RPC_URL`から読み込み） |
| `remote` | Remoteチェーン（`.env`の`REMOTE_RPC_URL`から読み込み） |
| `fuji` | Avalanche Fuji C-Chain（パブリック） |
| `dispatch` | Dispatch Testnet（パブリック） |
| `local` | ローカルノード |

`.env`に`HOME_RPC_URL`、`HOME_BLOCKCHAIN_ID`、`HOME_TELEPORTER_REGISTRY`と、`REMOTE_*`の対応する設定を追加してください。

## 依存関係

- Solidity 0.8.30
- OpenZeppelin Contracts v5.4.0
- OpenZeppelin Contracts Upgradeable v5.4.0
- Forge Standard Library

## 参考リンク

- [Avalanche Interchain Messaging](https://build.avax.network/academy/interchain-messaging)
- [ICM Contracts Repository](https://github.com/ava-labs/icm-contracts)
- [Foundry Book](https://book.getfoundry.sh/)
