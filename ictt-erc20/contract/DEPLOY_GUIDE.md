# デプロイガイド

## このガイドでできること

このガイドでは、**Avalanche ICTT（Interchain Token Transfer）** を使用して、Fuji C-Chain（Home）からDispatch Testnet（Remote）へERC20トークンをクロスチェーン送信するデモを実現します。

**具体的な流れ**:
1. Fuji C-ChainにERC20トークン（SampleERC20）とTokenHomeコントラクトをデプロイ
2. Dispatch TestnetにTokenRemoteコントラクトをデプロイ
3. Fuji側で100トークンをミント
4. Fuji C-Chain → Dispatch Testnetへ1トークンを送信
5. Dispatch側で受信を確認

これにより、AvalancheのInterchain Messaging（ICM）を使ったクロスチェーントークン転送の動作を確認できます。

## 🚀 クイックスタート（Makefileを使用）

```bash
# 1. 環境設定
cp .env.example .env
vim .env  # PRIVATE_KEYを設定

# 2. Fuji側デプロイ & 初期化
make deploy-fuji        # 出力されたアドレスを.envに追加
make initialize-fuji

# 3. Dispatch側デプロイ & 初期化
make deploy-dispatch    # 出力されたアドレスを.envに追加
make initialize-dispatch

# 4. リモート登録
make register-remote

# 5. トークンミント＆送信
make mint AMOUNT=100
make send AMOUNT=1

# 6. 残高確認
make balance-dispatch
```

---

## 目次

1. [事前準備](#1-事前準備)
2. [環境設定](#2-環境設定)
3. [デプロイ（Makefile使用）](#3-デプロイmakefile使用)
4. [リモートチェーンの登録](#4-リモートチェーンの登録)
5. [トークンのミント](#5-トークンのミント)
6. [トークンの送信](#6-トークンの送信)

---

## 1. 事前準備

### 必要なもの

- Node.js v18以上
- Foundry（forge, cast）
- テストネット用のAVAXトークン（ガス代）
- 秘密鍵

### テストネットAVAXの取得

**Fuji C-Chain**:
- [Avalanche Faucet](https://faucet.avax.network/)

**Dispatch Testnet**:
- Dispatchの公式ドキュメントを参照してください

### Relayerについて

Fuji TestnetとDispatch TestnetにはRelayerが既に稼働しています。クロスチェーンメッセージは自動的に中継されるため、Relayerを起動する必要はありません。

---

## 2. 環境設定

### 2.1 環境変数ファイルの作成

```bash
# .env.exampleをコピー
cp .env.example .env

# .envファイルを編集
vim .env
```

### 2.2 最低限の設定

`.env`ファイルに以下を設定：

```bash
# プライベートキー（先頭の0xは不要）
PRIVATE_KEY=your_private_key_here
```

**注意**:
- RPC URLは`foundry.toml`に定義済みです（`fuji`, `dispatch`, `local`）
- デプロイ後のアドレスは自動的に`.env`に追加する必要があります
- 最初はプライベートキーだけでOKです

---

## 3. デプロイ（Makefile使用）

**推奨**: Makefileを使うとコマンドが簡潔で、エラーチェックも自動で行われます。

### 3.1 利用可能なコマンド一覧

```bash
make help
```

主要なコマンド：
- `make deploy-fuji` - Fuji側のデプロイ
- `make initialize-fuji` - Fuji側のTokenHomeを初期化
- `make deploy-dispatch` - Dispatch側のデプロイ
- `make initialize-dispatch` - Dispatch側のTokenRemoteを初期化
- `make register-remote` - リモートチェーンを登録
- `make mint` - トークンをミント
- `make send` - トークンを送信
- `make balance-fuji` - Fuji側の残高確認
- `make balance-dispatch` - Dispatch側の残高確認

### 3.2 Fuji C-Chain側のデプロイ

```bash
make deploy-fuji
```

このコマンドで以下がデプロイされます：
1. **SampleERC20** - 送信するトークン
2. **ERC20TokenHomeUpgradeable** - トークンをロックして他チェーンに送信

### 3.3 デプロイ結果の確認

デプロイが完了すると、コンソールに以下のような出力が表示されます：

```
=== Fuji Home側 デプロイ完了 ===

以下のアドレスを.envファイルに保存してください:

TOKEN_HOME_BLOCKCHAIN_ID= 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5
TOKEN_ADDRESS= 0x961ca8E8a423326d7D36DDCc00AFC2cAF34E463a
TOKEN_HOME_ADDRESS= 0x42D5F416f272AB01953d33f291bE654C21797723
```

### 3.4 .envファイルへの追加

**重要**: 出力されたアドレスを`.env`ファイルに追加してください：

```bash
# .envファイルに以下を追加（コンソール出力からコピー）
TOKEN_HOME_BLOCKCHAIN_ID=0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5
TOKEN_ADDRESS=0x961ca8E8a423326d7D36DDCc00AFC2cAF34E463a
TOKEN_HOME_ADDRESS=0x42D5F416f272AB01953d33f291bE654C21797723
```

### 3.5 Fuji側の初期化

```bash
make initialize-fuji
```

TokenHomeコントラクトを初期化します。この手順は必須です。

### 3.6 Dispatch Testnet側のデプロイ

**前提**: `.env`ファイルに以下が設定されていること
- `TOKEN_HOME_BLOCKCHAIN_ID`
- `TOKEN_HOME_ADDRESS`

```bash
make deploy-dispatch
```

このコマンドで **ERC20TokenRemoteUpgradeable** がデプロイされます。

デプロイ完了後、以下のアドレスを`.env`に追加：

```bash
DISPATCH_BLOCKCHAIN_ID=0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7
REMOTE_TOKEN_TRANSFERRER_ADDRESS=0x25224252498Bc44C3b0f4930e9DF10A427eB8ed5
```

### 3.7 Dispatch側の初期化

```bash
make initialize-dispatch
```

TokenRemoteコントラクトを初期化します。この手順は必須です。

---

## 4. リモートチェーンの登録

Fuji C-Chain側のTokenHomeに、Dispatch Testnetを宛先として登録します。

```bash
make register-remote
```

**成功メッセージ**:
```
=== 登録完了 ===
リモートチェーンが正常に登録されました
```

---

## 5. トークンのミント

自分のアドレスにトークンをミントします。

```bash
# デフォルト（100トークン）
make mint

# カスタム量（例：500トークン）
make mint MINT_AMOUNT=500000000000000000000
```

ミント完了後、残高を確認：

```bash
make balance-fuji
```

**期待される出力**:
```
残高: 100000000000000000000 wei
残高: 100.0 トークン
```

---

## 6. トークンの送信

Fuji C-ChainからDispatch Testnetへトークンを送信します。

### 6.1 トークン送信の実行

```bash
# デフォルト（1トークン、自分宛）
make send

# カスタム量
make send AMOUNT=5000000000000000000

# 別のアドレスへ送信
make send RECIPIENT=0x...
```

**成功メッセージ**:
```
=== トークン送信完了！ ===
数秒〜数分待ってからmake balance-dispatchで確認してください
```

### 6.2 受信の確認

**数秒〜数分待ってから**、Dispatch Testnet側で残高を確認します：

```bash
make balance-dispatch
```

**期待される出力**:
```
残高: 1000000000000000000 wei
残高: 1.0 トークン
```

**注意**: クロスチェーンメッセージの処理には時間がかかります：
- 通常: 10秒〜30秒
- 遅い場合: 1〜3分

---

## 参考リンク

- [Avalanche ICM Documentation](https://docs.avax.network/cross-chain/teleporter/overview)
- [Avalanche Academy - Interchain Messaging](https://build.avax.network/academy/interchain-messaging)
- [Foundry Book](https://book.getfoundry.sh/)
- [Avalanche Faucet](https://faucet.avax.network/)
- [ICM Contracts Repository](https://github.com/ava-labs/icm-contracts)

---

## デプロイチェックリスト

完了したら✅をつけてください：

### 事前準備
- [ ] Foundryがインストールされている（`forge --version`）
- [ ] Fuji C-ChainのテストネットAVAXを持っている
- [ ] Dispatch TestnetのテストネットAVAXを持っている
- [ ] `.env`ファイルが作成されている（`cp .env.example .env`）
- [ ] プライベートキーが設定されている

### デプロイ
- [ ] `make deploy-fuji` が成功した
- [ ] Fujiのアドレスを`.env`に追加した
- [ ] `make initialize-fuji` が成功した
- [ ] `make deploy-dispatch` が成功した
- [ ] Dispatchのアドレスを`.env`に追加した
- [ ] `make initialize-dispatch` が成功した

### 設定とテスト
- [ ] `make register-remote` でリモートチェーンを登録した
- [ ] `make mint` でトークンをミントできた
- [ ] `make balance-fuji` で残高を確認できた
- [ ] `make send` でトークンを送信できた
- [ ] `make balance-dispatch` でDispatch側の残高を確認できた ✨

---

## 次のステップ

デプロイとトークン送信が成功したら、以下を試してみてください：

### 1. 逆方向の送信

Dispatch Testnet → Fuji C-Chainへトークンを送り返す

### 2. SendAndCall機能

トークン送信と同時にスマートコントラクトを呼び出す

### 3. 手数料の設定

プライマリ手数料を設定して、Relayerにインセンティブを提供

### 4. マルチホップ

3つ以上のチェーンを経由したトークン転送

詳細は[TEST.md](./TEST.md)を参照してください。

---

## まとめ

このガイドに従うことで、以下が完了します：

1. ✅ Fuji C-Chainにすべてのコントラクトをデプロイ（`make deploy-fuji`）
2. ✅ Fuji側のTokenHomeを初期化（`make initialize-fuji`）
3. ✅ Dispatch Testnetにすべてのコントラクトをデプロイ（`make deploy-dispatch`）
4. ✅ Dispatch側のTokenRemoteを初期化（`make initialize-dispatch`）
5. ✅ リモートチェーンを登録（`make register-remote`）
6. ✅ トークンをミント（`make mint`）
7. ✅ Fuji → Dispatchへトークンを送信（`make send`）
8. ✅ Dispatch側で受信を確認（`make balance-dispatch`）

おめでとうございます！🎉 クロスチェーントークン転送が成功しました。

**Makefileコマンド一覧**:
```bash
make help                # すべてのコマンドを表示
make deploy-fuji         # Fuji側デプロイ
make initialize-fuji     # Fuji側TokenHome初期化
make deploy-dispatch     # Dispatch側デプロイ
make initialize-dispatch # Dispatch側TokenRemote初期化
make register-remote     # リモート登録
make mint                # トークンミント
make send                # トークン送信
make balance-fuji        # Fuji残高確認
make balance-dispatch    # Dispatch残高確認
```
