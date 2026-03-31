# コマンド一覧

ICTT ERC20のデプロイ・操作に必要な全コマンドをまとめたドキュメントです。

---

## 目次

1. [環境設定](#環境設定)
2. [Makefileコマンド](#makefileコマンド)
3. [手動コマンド](#手動コマンド)
4. [トラブルシューティング](#トラブルシューティング)

---

## 環境設定

### 基本設定

```bash
cd ictt-erc20/contract

# .envファイルを作成
cp .env.example .env

# 設定を編集
vim .env
```

### .envの構成

```bash
# デプロイ用のプライベートキー
PRIVATE_KEY=your_private_key_here

# Home Chain（トークンの発行元）
HOME_RPC_URL=https://your-home-rpc-url
HOME_BLOCKCHAIN_ID=0x...
HOME_TELEPORTER_REGISTRY=0x...

# Remote Chain（転送先）
REMOTE_RPC_URL=https://your-remote-rpc-url
REMOTE_BLOCKCHAIN_ID=0x...
REMOTE_TELEPORTER_REGISTRY=0x...

# デプロイ済みコントラクトアドレス
TOKEN_ADDRESS=0x...
HOME_ADDRESS=0x...
REMOTE_ADDRESS=0x...
```

### RPC設定一覧（foundry.toml）

| エイリアス | 説明 |
|-----------|------|
| `home` | Homeチェーン（.envから読み込み） |
| `remote` | Remoteチェーン（.envから読み込み） |
| `fuji` | Avalanche Fuji C-Chain（パブリック） |
| `dispatch` | Dispatch Testnet（パブリック） |
| `local` | ローカルノード |

---

## Makefileコマンド

### コマンド一覧

```bash
make help  # 全コマンドを表示
```

### セットアップ

| コマンド | 説明 |
|---------|------|
| `make install` | 依存関係をインストール |
| `make build` | コントラクトをビルド |
| `make test` | テストを実行 |
| `make clean` | ビルド成果物を削除 |
| `make fmt` | コードフォーマット |

### デプロイ

| コマンド | 説明 |
|---------|------|
| `make deploy-home` | Home側（ERC20 + TokenHome）をデプロイ |
| `make deploy-remote` | Remote側（TokenRemote）をデプロイ |

### 初期化

| コマンド | 説明 |
|---------|------|
| `make initialize-home` | Home側TokenHomeを初期化 |
| `make initialize-remote` | Remote側TokenRemoteを初期化 |
| `make register-remote` | TokenRemoteをTokenHomeに登録 |

### トークン操作

| コマンド | 説明 |
|---------|------|
| `make mint` | トークンをミント（デフォルト100トークン） |
| `make send` | トークンを送信（デフォルト1トークン） |
| `make balance-home` | Home側の残高確認 |
| `make balance-remote` | Remote側の残高確認 |

### カスタマイズ

```bash
# ミント量を変更
make mint MINT_AMOUNT=500000000000000000000

# 送信量を変更
make send SEND_AMOUNT=10000000000000000000
```

---

## 手動コマンド

Makefileを使わずに各ステップを個別に実行する場合のコマンド集です。

### 前提条件

```bash
# 環境変数を読み込み
source .env
```

### デプロイスクリプト

```bash
# ERC20のみデプロイ
forge script script/Deploy.s.sol:DeployERC20 --rpc-url home --broadcast

# ERC20デプロイ + Mint
forge script script/Deploy.s.sol:DeployERC20AndMint --rpc-url home --broadcast

# Home側（ERC20 + TokenHome）デプロイ
forge script script/Deploy.s.sol:DeployHome --rpc-url home --broadcast

# Remote側デプロイ
forge script script/Deploy.s.sol:DeployRemote --rpc-url remote --broadcast
```

### Mint

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

cast send $TOKEN_ADDRESS \
  "mint(address,uint256)" \
  $DEPLOYER \
  100000000000000000000 \
  --rpc-url home \
  --private-key $PRIVATE_KEY
```

### Home側TokenHome初期化

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

cast send $HOME_ADDRESS \
  "initialize(address,address,uint256,address,uint8)" \
  $HOME_TELEPORTER_REGISTRY \
  $DEPLOYER \
  1 \
  $TOKEN_ADDRESS \
  18 \
  --rpc-url home \
  --private-key $PRIVATE_KEY
```

### Remote側TokenRemote初期化

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

cast send $REMOTE_ADDRESS \
  "initialize((address,address,uint256,bytes32,address,uint8),string,string,uint8)" \
  "($REMOTE_TELEPORTER_REGISTRY,$DEPLOYER,1,$HOME_BLOCKCHAIN_ID,$HOME_ADDRESS,18)" \
  "Bridged Token" \
  "bSMPL" \
  18 \
  --rpc-url remote \
  --private-key $PRIVATE_KEY
```

### リモート登録

```bash
cast send $REMOTE_ADDRESS \
  "registerWithHome((address,uint256))" \
  "(0x0000000000000000000000000000000000000000,0)" \
  --rpc-url remote \
  --private-key $PRIVATE_KEY
```

**注意**: 登録完了まで10秒〜数分待ってください。

### トークン送信（Home → Remote）

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

# 1. トークン承認
cast send $TOKEN_ADDRESS \
  "approve(address,uint256)" \
  $HOME_ADDRESS \
  1000000000000000000 \
  --rpc-url home \
  --private-key $PRIVATE_KEY

# 2. トークン送信
cast send $HOME_ADDRESS \
  "send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
  "($REMOTE_BLOCKCHAIN_ID,$REMOTE_ADDRESS,$DEPLOYER,$TOKEN_ADDRESS,0,0,250000,0x0000000000000000000000000000000000000000)" \
  1000000000000000000 \
  --rpc-url home \
  --private-key $PRIVATE_KEY
```

### 残高確認

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

# Home側
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url home

# Remote側
cast call $REMOTE_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url remote
```

### 単位変換

```bash
# wei → ether
cast from-wei 1000000000000000000
# 出力: 1.000000000000000000
```

---

## 一括実行スクリプト

Mint → Send → 残高確認を一括で実行するスクリプトです。

```bash
./script/test-transfer.sh \
  --token 0xaeee02718bd39f2d386ecb4b5d6d2eef18d308c1 \
  --home 0x21760e1396167d9b17ba217a24c04f6efde3bff5 \
  --remote 0xa0ec11ede631550d64c79d03757b742a6f9ada4f \
  --remote-blockchain-id 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5
```

### 処理内容
1. 初期残高確認（Home/Remote）
2. Mint（100トークン）
3. Mint後残高確認（Home/Remote）
4. Approve + Send（50トークン）
5. Send後残高確認（Home/Remote、最大60秒待機）

### 必須引数
| 引数 | 説明 |
|-----|------|
| `--token` | ERC20トークンコントラクトアドレス |
| `--home` | TokenHomeコントラクトアドレス |
| `--remote` | TokenRemoteコントラクトアドレス |
| `--remote-blockchain-id` | Remote側のBlockchain ID |

※ `PRIVATE_KEY`は`.env`から読み込み

---

## アドレス指定コマンド（コピペ用）

以下のアドレスで直接実行できるコマンド例です。

| コントラクト | アドレス | チェーン |
|------------|---------|---------|
| Token | 0xaeee02718bd39f2d386ecb4b5d6d2eef18d308c1 | Home (Custom) |
| Home | 0x21760e1396167d9b17ba217a24c04f6efde3bff5 | Home (Custom) |
| Remote | 0xa0ec11ede631550d64c79d03757b742a6f9ada4f | Remote (Fuji) |

### Mint（100トークン）

```bash
cast send 0xaeee02718bd39f2d386ecb4b5d6d2eef18d308c1 \
  "mint(address,uint256)" \
  $(cast wallet address --private-key $PRIVATE_KEY) \
  100000000000000000000 \
  --rpc-url home \
  --private-key $PRIVATE_KEY
```

### Transfer（1トークン、Home → Remote）

```bash
# 1. approve
cast send 0xaeee02718bd39f2d386ecb4b5d6d2eef18d308c1 \
  "approve(address,uint256)" \
  0x21760e1396167d9b17ba217a24c04f6efde3bff5 \
  1000000000000000000 \
  --rpc-url home \
  --private-key $PRIVATE_KEY

# 2. send
cast send 0x21760e1396167d9b17ba217a24c04f6efde3bff5 \
  "send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
  "(0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5,0xa0ec11ede631550d64c79d03757b742a6f9ada4f,$(cast wallet address --private-key $PRIVATE_KEY),0xaeee02718bd39f2d386ecb4b5d6d2eef18d308c1,0,0,250000,0x0000000000000000000000000000000000000000)" \
  1000000000000000000 \
  --rpc-url home \
  --private-key $PRIVATE_KEY
```

### 残高確認

```bash
# Home側（Custom）
cast call 0xaeee02718bd39f2d386ecb4b5d6d2eef18d308c1 \
  "balanceOf(address)(uint256)" \
  $(cast wallet address --private-key $PRIVATE_KEY) \
  --rpc-url home

# Remote側（Fuji）
cast call 0xa0ec11ede631550d64c79d03757b742a6f9ada4f \
  "balanceOf(address)(uint256)" \
  $(cast wallet address --private-key $PRIVATE_KEY) \
  --rpc-url remote
```

---

## トラブルシューティング

### "PRIVATE_KEYが設定されていません" エラー

`.env`ファイルに`PRIVATE_KEY`を設定してください。

### デプロイが途中で失敗した場合

1. `.env`ファイルを確認して、途中まで保存されたアドレスを確認
2. 失敗したステップから手動コマンドで再開

### Remote側の残高が0のまま

クロスチェーンメッセージの処理に時間がかかります（10秒〜3分）。
数分待ってから`make balance-remote`で再度確認してください。

### ガス不足エラー

各チェーンのFaucetからテストネットトークンを取得してください。

---

## 参考リンク

- [Avalanche ICM Documentation](https://docs.avax.network/cross-chain/teleporter/overview)
- [Avalanche Academy - Interchain Messaging](https://build.avax.network/academy/interchain-messaging)
- [Foundry Book](https://book.getfoundry.sh/)
- [ICM Contracts Repository](https://github.com/ava-labs/icm-contracts)
