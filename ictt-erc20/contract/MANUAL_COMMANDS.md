# 手動実行コマンド一覧

Makefileを使わずに、各ステップを個別に実行するためのコマンド集です。

## 前提条件

```bash
cd ictt-erc20/contract

# .envファイルを作成
cp .env.example .env

# PRIVATE_KEYを設定
vim .env

# 環境変数を読み込み（以降のコマンドで必要）
source .env
```

---

## Step 1: Fuji側デプロイ

```bash
forge script script/Deploy.s.sol:DeployFujiHome --rpc-url fuji --broadcast
```

出力されたアドレスを`.env`に追加し、再読み込み：

```bash
# .envに追加
TOKEN_ADDRESS=0x...
TOKEN_HOME_ADDRESS=0x...

# 再読み込み
source .env
```

---

## Step 2: Fuji側TokenHome初期化

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

cast send $TOKEN_HOME_ADDRESS \
  "initialize(address,address,uint256,address,uint8)" \
  0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228 \
  $DEPLOYER \
  1 \
  $TOKEN_ADDRESS \
  18 \
  --rpc-url fuji \
  --private-key $PRIVATE_KEY
```

---

## Step 3: Dispatch側デプロイ

```bash
forge script script/Deploy.s.sol:DeployDispatchRemote --rpc-url dispatch --broadcast
```

出力されたアドレスを`.env`に追加し、再読み込み：

```bash
# .envに追加
REMOTE_TOKEN_TRANSFERRER_ADDRESS=0x...

# 再読み込み
source .env
```

---

## Step 4: Dispatch側TokenRemote初期化

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

cast send $REMOTE_TOKEN_TRANSFERRER_ADDRESS \
  "initialize((address,address,uint256,bytes32,address,uint8),string,string,uint8)" \
  "(0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228,$DEPLOYER,1,$TOKEN_HOME_BLOCKCHAIN_ID,$TOKEN_HOME_ADDRESS,18)" \
  "Bridged Token" \
  "bSMPL" \
  18 \
  --rpc-url dispatch \
  --private-key $PRIVATE_KEY
```

---

## Step 5: リモート登録

```bash
cast send $REMOTE_TOKEN_TRANSFERRER_ADDRESS \
  "registerWithHome((address,uint256))" \
  "(0x0000000000000000000000000000000000000000,0)" \
  --rpc-url dispatch \
  --private-key $PRIVATE_KEY
```

**注意**: 登録完了まで10秒〜数分待ってください。

---

## Step 6: トークンミント

```bash
forge script script/Token.s.sol:MintToken --rpc-url fuji --broadcast
```

デフォルトで100トークンをミントします。量を変更する場合は`.env`に`MINT_AMOUNT`を設定してください。

---

## Step 7: トークン送信

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)

# 1. トークン承認（1トークン = 1000000000000000000 wei）
cast send $TOKEN_ADDRESS \
  "approve(address,uint256)" \
  $TOKEN_HOME_ADDRESS \
  1000000000000000000 \
  --rpc-url fuji \
  --private-key $PRIVATE_KEY

# 2. 承認確認
cast call $TOKEN_ADDRESS "allowance(address,address)(uint256)" $DEPLOYER $TOKEN_HOME_ADDRESS --rpc-url fuji

# 3. トークン送信
cast send $TOKEN_HOME_ADDRESS \
  "send((bytes32,address,address,address,uint256,uint256,uint256,address),uint256)" \
  "($DISPATCH_BLOCKCHAIN_ID,$REMOTE_TOKEN_TRANSFERRER_ADDRESS,$DEPLOYER,$TOKEN_ADDRESS,0,0,250000,0x0000000000000000000000000000000000000000)" \
  1000000000000000000 \
  --rpc-url fuji \
  --private-key $PRIVATE_KEY
```

**注意**: クロスチェーン送信完了まで10秒〜数分待ってください。

---

## Step 8: 残高確認

### Fuji側残高

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url fuji
```

### Dispatch側残高

```bash
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
cast call $REMOTE_TOKEN_TRANSFERRER_ADDRESS "balanceOf(address)(uint256)" $DEPLOYER --rpc-url dispatch
```

---

## 単位変換

wei → ether に変換：

```bash
cast from-wei <wei値>
```

例：
```bash
cast from-wei 1000000000000000000
# 出力: 1.000000000000000000
```

---

## トラブルシューティング

### Dispatch側の残高が0

クロスチェーンメッセージの処理に時間がかかります。数分待ってから再度確認してください。



