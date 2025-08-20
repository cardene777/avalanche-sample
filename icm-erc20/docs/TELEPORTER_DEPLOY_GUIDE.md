# TeleporterERC20 デプロイガイド

## 概要

このガイドでは、TeleporterERC20トークンをChain1とChain2にデプロイし、クロスチェーン転送を可能にする手順を説明します。

## 前提条件

1. Chain1とChain2が起動済み
2. AWM Relayerが稼働中
3. Foundryがインストール済み
4. 環境変数 `PRIVATE_KEY` が設定済み

## デプロイ手順

### 1. 環境変数の設定

```bash
# デプロイヤーの秘密鍵
export PRIVATE_KEY=0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
```

### 2. 自動デプロイスクリプトの実行

```bash
# スクリプトを実行
cd /Users/cardene/Desktop/work/ava/avalanche-sample/icm-erc20
./scripts/setup/deploy-teleporter-tokens.sh
```

このスクリプトは以下を自動で行います：
- Chain1とChain2のBlockchain IDを取得
- 両チェーンにTeleporterERC20をデプロイ
- 相互接続の設定

## デプロイ後の使用方法

### 環境変数の設定

デプロイスクリプトの出力に表示された値を`.env`ファイルに保存します：

```bash
# デプロイ出力の内容を.envファイルに追加
# 例：
echo "CHAIN1_TOKEN_ADDRESS=0xB8a934dcb74d0E3d1DF6Bce0faC12cD8B18801eD" >> .env
echo "CHAIN2_TOKEN_ADDRESS=0xe336d36FacA76840407e6836d26119E1EcE0A2b4" >> .env
```

### Makefileを使用した操作

```bash
# トークンをMint（1000トークン）
make mint1

# 残高確認
make balance

# クロスチェーン転送（100トークン）
make transfer1to2
```

### 残高確認

```bash
# Chain1の残高
cast call $CHAIN1_TOKEN_ADDRESS \
  "balanceOf(address)" \
  0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC \
  --rpc-url $CHAIN1_RPC_URL
```

### クロスチェーン転送

```bash
# Chain1からChain2へ転送
cast send $CHAIN1_TOKEN_ADDRESS \
  "sendTokens(bytes32,address,uint256)" \
  $CHAIN2_BLOCKCHAIN_ID \
  0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC \
  100000000000000000000 \
  --rpc-url $CHAIN1_RPC_URL \
  --private-key $PRIVATE_KEY
```

## トラブルシューティング

### "execution reverted"エラー

1. トークンアドレスが正しいか確認
2. リモートアドレスが設定されているか確認：
   ```bash
   cast call $CHAIN1_TOKEN_ADDRESS \
     "remoteTokenAddresses(bytes32)" \
     $CHAIN2_BLOCKCHAIN_ID \
     --rpc-url $CHAIN1_RPC_URL
   ```

### 転送が完了しない

1. AWM Relayerのログを確認：
   ```bash
   tail -f ~/awm-relayer-direct.log
   ```

2. Teleporter Messengerのアドレスが正しいか確認（0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf）

## 重要な注意事項

- TeleporterERC20のmint関数は誰でも呼べる設定です（本番環境では要変更）
- ガス代の設定に注意（requiredGasLimit: 200000）
- AWM Relayerが稼働していることを確認