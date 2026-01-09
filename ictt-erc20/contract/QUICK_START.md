# クイックスタートガイド

このガイドでは、**1コマンド**でICTTクロスチェーントークン転送（デプロイから送信まで）を完了できます。

## 概要

| 従来の方法 | deploy-and-send |
|-----------|-----------------|
| 7コマンド + 手動.env編集 | **1コマンド** |
| 手動でアドレスをコピペ | 自動で.envに保存 |

## 前提条件

- Foundry（forge, cast）がインストール済み
- Fuji C-ChainとDispatch TestnetのテストネットAVAXを保有
- 秘密鍵を用意

## 手順

### Step 1: 環境設定

```bash
cd ictt-erc20/contract

# .envファイルを作成
cp .env.example .env

# 秘密鍵を設定
vim .env
```

`.env`に設定:
```bash
PRIVATE_KEY=your_private_key_here
```

---

### Step 2: デプロイから送信まで実行

```bash
make deploy-and-send
```

または直接スクリプトを実行:

```bash
./script/deploy-and-send.sh
```

---

### 実行される処理

スクリプトは以下を順番に自動実行します:

| ステップ | 処理内容 | チェーン |
|---------|---------|----------|
| 1 | SampleERC20 + TokenHome デプロイ | Fuji |
| 2 | TokenHome 初期化 | Fuji |
| 3 | TokenRemote デプロイ | Dispatch |
| 4 | TokenRemote 初期化 | Dispatch |
| 5 | リモート登録（registerWithHome） | Dispatch |
| 6 | トークンミント（100トークン） | Fuji |
| 7 | トークン送信（1トークン） | Fuji → Dispatch |
| 8 | 残高確認 | 両チェーン |

---

### 出力例

```
=====================================================
[1/8] Fuji側デプロイ
=====================================================

→ SampleERC20 と TokenHome をデプロイ中...
✓ SampleERC20: 0x961ca8E8...
✓ TokenHome: 0x42D5F416...
→ 追加: TOKEN_ADDRESS
→ 追加: TOKEN_HOME_ADDRESS

...

=====================================================
デプロイ完了！
=====================================================

デプロイされたコントラクト:
  - SampleERC20 (Fuji): 0x961ca8E8...
  - TokenHome (Fuji): 0x42D5F416...
  - TokenRemote (Dispatch): 0x25224252...

.envファイルが自動更新されました

✓ 全ての処理が完了しました！
```

---

## カスタマイズ

`.env`ファイルで以下の値を設定することでカスタマイズできます:

```bash
# ミント量を変更（デフォルト: 100トークン）
MINT_AMOUNT=500000000000000000000

# 送信量を変更（デフォルト: 1トークン）
SEND_AMOUNT=10000000000000000000
```

---

## デプロイ後の操作

```bash
# Fuji側残高確認
make balance-fuji

# Dispatch側残高確認
make balance-dispatch

# 追加でトークンをミント
make mint

# 追加でトークンを送信
make send
```

---

## トラブルシューティング

### "PRIVATE_KEYが設定されていません" エラー

`.env`ファイルに`PRIVATE_KEY`を設定してください。

### デプロイが途中で失敗した場合

1. `.env`ファイルを確認して、途中まで保存されたアドレスを確認
2. 従来の方法（DEPLOY_GUIDE.md）を使って、失敗したステップから再開

### Dispatch側の残高が0のまま

クロスチェーンメッセージの処理に時間がかかります（10秒〜3分）。
数分待ってから`make balance-dispatch`で再度確認してください。

---

## 関連ドキュメント

- [MANUAL_COMMANDS.md](./MANUAL_COMMANDS.md) - 手動実行コマンド一覧
- [TEST.md](./TEST.md) - テストガイド
- [Avalanche ICM Documentation](https://docs.avax.network/cross-chain/teleporter/overview)
