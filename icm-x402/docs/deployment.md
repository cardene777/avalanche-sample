# Deployment Guide

**x402 Paywall DApp - デプロイ手順書**

---

## 前提条件

### 必要なツール
- **Node.js**: 20以上
- **Bun**: 1.2以上（パッケージマネージャー）
- **Docker**: 20以上
- **Docker Compose**: 2.0以上
- **Git**: 2.30以上

### 必要なアカウント・資金
- **Dispatch L1 Testnet**: テストトークン（ガス代用）
- **Echo L1 Testnet**: テストトークン（ガス代用）
- **Facilitator用ウォレット**: 秘密鍵（ガス代支払い用）

---

## ステップ1: 環境変数の設定

### 1-1. ルート`.env`ファイル作成

```bash
cd icm-x402
cp .env.example .env
```

### 1-2. `.env`を編集

```bash
# Dispatch Chain (Payment Layer)
DISPATCH_RPC_URL=https://subnets.avax.network/dispatch/testnet/rpc
DISPATCH_CHAIN_ID=123456
DISPATCH_TELEPORTER_MESSENGER=0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf

# Echo Chain (Access Control Layer)
ECHO_RPC_URL=https://subnets.avax.network/echo/testnet/rpc
ECHO_CHAIN_ID=789012
ECHO_TELEPORTER_MESSENGER=0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf

# Facilitator Wallet (ガス代支払い用)
FACILITATOR_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# Contract Addresses (デプロイ後に更新)
PAYMENT_TOKEN_ADDRESS=
PAYMENT_REGISTRY_ADDRESS=
CONTENT_ACCESS_MANAGER_ADDRESS=
```

**⚠️ 重要**: `FACILITATOR_PRIVATE_KEY`は本番環境では**絶対に**Gitにコミットしないでください。

---

## ステップ2: スマートコントラクトのデプロイ

### 2-1. 依存関係のインストール

```bash
cd contracts
bun install
```

### 2-2. Hardhat設定確認

`hardhat.config.ts`を確認：

```typescript
networks: {
  dispatch: {
    url: process.env.DISPATCH_RPC_URL,
    accounts: [process.env.FACILITATOR_PRIVATE_KEY],
    chainId: parseInt(process.env.DISPATCH_CHAIN_ID || "123456")
  },
  echo: {
    url: process.env.ECHO_RPC_URL,
    accounts: [process.env.FACILITATOR_PRIVATE_KEY],
    chainId: parseInt(process.env.ECHO_CHAIN_ID || "789012")
  }
}
```

### 2-3. デプロイ実行

#### オプション1: 一括デプロイ（推奨）

```bash
bun run deploy
```

このコマンドは以下を実行します：
1. Dispatch ChainにERC3009PaymentTokenをデプロイ
2. Dispatch ChainにPaymentRegistryをデプロイ
3. Echo ChainにContentAccessManagerをデプロイ
4. コントラクトアドレスを`.env`に自動追記

#### オプション2: 個別デプロイ

```bash
# 1. PaymentToken (Dispatch)
bun hardhat run scripts/deploy-token.ts --network dispatch

# 2. ContentAccessManager (Echo)
bun hardhat run scripts/deploy-content-access-manager.ts --network echo

# 3. PaymentRegistry (Dispatch)
bun hardhat run scripts/deploy-payment-registry.ts --network dispatch
```

### 2-4. デプロイ結果の確認

デプロイ後、以下のように出力されます：

```
====================================
Deployment Summary
====================================
ERC3009PaymentToken: 0x1234567890123456789012345678901234567890
PaymentRegistry: 0xabcdefabcdefabcdefabcdefabcdefabcdefabcd
ContentAccessManager: 0x9876543210987654321098765432109876543210
====================================
```

これらのアドレスを`.env`ファイルに記録してください。

---

## ステップ3: バックエンドサービスのデプロイ

### 3-1. Backend環境変数

```bash
cd ../backend
cp .env.example .env
```

`.env`を編集：

```bash
PORT=4000
NODE_ENV=production

ECHO_RPC_URL=https://subnets.avax.network/echo/testnet/rpc
CONTENT_ACCESS_MANAGER_ADDRESS=0x9876543210987654321098765432109876543210

DISPATCH_RPC_URL=https://subnets.avax.network/dispatch/testnet/rpc
PAYMENT_TOKEN_ADDRESS=0x1234567890123456789012345678901234567890

FACILITATOR_URL=http://facilitator:5000

TOKEN_NAME=PaymentToken
TOKEN_VERSION=1
DISPATCH_CHAIN_ID=123456

CORS_ORIGIN=http://localhost:3000
```

### 3-2. Backendビルド

```bash
bun install
bun run build
```

### 3-3. Facilitator環境変数

```bash
cd ../facilitator
cp .env.example .env
```

`.env`を編集：

```bash
PORT=5000
NODE_ENV=production

DISPATCH_RPC_URL=https://subnets.avax.network/dispatch/testnet/rpc
PAYMENT_TOKEN_ADDRESS=0x1234567890123456789012345678901234567890
PAYMENT_REGISTRY_ADDRESS=0xabcdefabcdefabcdefabcdefabcdefabcdefabcd

FACILITATOR_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

TOKEN_NAME=PaymentToken
TOKEN_VERSION=1
DISPATCH_CHAIN_ID=123456

CORS_ORIGIN=http://localhost:3000
```

### 3-4. Facilitatorビルド

```bash
bun install
bun run build
```

---

## ステップ4: Docker Composeでデプロイ

### 4-1. Docker Compose設定確認

`docker-compose.yml`を確認：

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "4000:4000"
    env_file:
      - ./backend/.env
    restart: unless-stopped

  facilitator:
    build: ./facilitator
    ports:
      - "5000:5000"
    env_file:
      - ./facilitator/.env
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    env_file:
      - ./frontend/.env
    restart: unless-stopped
    depends_on:
      - backend
      - facilitator

  relayer:
    build: ./relayer
    env_file:
      - ./relayer/.env
    restart: unless-stopped
```

### 4-2. Docker Composeで起動

```bash
cd ../  # プロジェクトルートに戻る
docker-compose up -d
```

### 4-3. サービス稼働確認

```bash
# すべてのサービスが起動しているか確認
docker-compose ps

# ログ確認
docker-compose logs -f

# 個別サービスのログ確認
docker-compose logs -f backend
docker-compose logs -f facilitator
```

### 4-4. ヘルスチェック

```bash
# Backend
curl http://localhost:4000/health

# Facilitator
curl http://localhost:5000/health

# Frontend
curl http://localhost:3000
```

---

## ステップ5: 動作確認

### 5-1. コンテンツ一覧取得

```bash
curl http://localhost:4000/api/content
```

期待される出力:
```json
{
  "content": [
    {
      "id": "premium-guide-avalanche-icm",
      "title": "Complete Guide to Avalanche Interchain Messaging",
      "price": "1000000000000000000",
      ...
    }
  ],
  "total": 4
}
```

### 5-2. アクセス権確認（未払い）

```bash
curl -H "X-BUYER-ADDRESS: 0xYourWalletAddress" \
     http://localhost:4000/api/content/premium-guide-avalanche-icm
```

期待される出力:
```json
{
  "error": "Payment Required",
  ...
  "paymentRequired": {
    "tokenAddress": "0x...",
    "amount": "1000000000000000000",
    ...
  }
}
```

### 5-3. 支払いテスト

フロントエンドまたはCLIツールで：
1. EIP-712署名を生成
2. Facilitatorに送信
3. トランザクション確認
4. 再度コンテンツアクセス → 200 OK

---

## トラブルシューティング

### コントラクトデプロイ失敗

**症状**: `Error: insufficient funds for gas`

**解決策**:
```bash
# ウォレット残高確認
cast balance 0xYourAddress --rpc-url $DISPATCH_RPC_URL

# Testnet faucetから取得
# https://faucet.avax.network/
```

### Backend起動失敗

**症状**: `Echo chain RPC connection failed`

**解決策**:
```bash
# RPC URL確認
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  $ECHO_RPC_URL

# .envファイルのアドレス確認
grep CONTENT_ACCESS_MANAGER_ADDRESS backend/.env
```

### Facilitator署名エラー

**症状**: `Invalid signature`

**解決策**:
- `TOKEN_NAME`, `TOKEN_VERSION`, `DISPATCH_CHAIN_ID`がコントラクトと一致しているか確認
- EIP-712 domain separatorを確認:
  ```bash
  cast call $PAYMENT_TOKEN_ADDRESS "DOMAIN_SEPARATOR()" --rpc-url $DISPATCH_RPC_URL
  ```

### ICMメッセージ未配信

**症状**: 支払い後もアクセス権が付与されない

**解決策**:
1. Relayerサービスが起動しているか確認
2. Dispatch Chain → Echo ChainのICMメッセージログ確認
3. TeleporterMessengerアドレスが正しいか確認

---

## 本番環境デプロイ

### セキュリティチェックリスト

- [ ] `.env`ファイルをGitignoreに追加
- [ ] Facilitator秘密鍵をセキュアに管理（AWS Secrets Manager等）
- [ ] CORS設定を本番ドメインに限定
- [ ] Rate Limitingを有効化
- [ ] HTTPSを有効化（Nginx/Caddy等）
- [ ] コントラクト監査完了
- [ ] バックアップ戦略の確立

### 推奨インフラ

```
┌─────────────────────────────────────────┐
│           Load Balancer (HTTPS)         │
└────────────────┬────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────v────┐      ┌────v────┐
   │Backend  │      │Frontend │
   │(×3)     │      │(×2)     │
   └─────────┘      └─────────┘
        │
   ┌────v────┐
   │Facilitator│
   │(×2)     │
   └─────────┘
        │
   ┌────v────┐
   │ Relayer │
   │(×1)     │
   └─────────┘
```

### モニタリング

- **Prometheus + Grafana**: メトリクス収集
- **Loki**: ログ集約
- **Alertmanager**: アラート通知
- **Sentry**: エラートラッキング

---

## ロールバック手順

### コントラクトの巻き戻し不可

スマートコントラクトは非アップグレード可能なため、バグがある場合：

1. 新バージョンをデプロイ
2. `.env`のアドレスを更新
3. サービスを再起動

### サービスのロールバック

```bash
# 以前のDockerイメージに戻す
docker-compose down
docker-compose pull <service>:<previous-tag>
docker-compose up -d
```

---

## デプロイチェックリスト

### 事前準備
- [ ] Node.js, Bun, Dockerインストール済み
- [ ] Testnet faucetからガス代取得済み
- [ ] Facilitator秘密鍵準備完了
- [ ] `.env`ファイル設定完了

### コントラクトデプロイ
- [ ] ERC3009PaymentToken デプロイ完了
- [ ] PaymentRegistry デプロイ完了
- [ ] ContentAccessManager デプロイ完了
- [ ] コントラクトアドレスを`.env`に記録

### サービスデプロイ
- [ ] Backend ビルド成功
- [ ] Facilitator ビルド成功
- [ ] Frontend ビルド成功（Phase 5以降）
- [ ] Relayer ビルド成功（Phase 7以降）
- [ ] Docker Compose起動成功

### 動作確認
- [ ] Health checkが成功
- [ ] コンテンツ一覧取得成功
- [ ] 402レスポンス確認
- [ ] 支払いフロー成功
- [ ] アクセス権付与確認

### 本番移行
- [ ] セキュリティ監査完了
- [ ] モニタリング設定完了
- [ ] バックアップ設定完了
- [ ] ドキュメント更新完了

---

## サポート

問題が発生した場合：

1. **ログ確認**: `docker-compose logs -f`
2. **GitHub Issues**: バグレポート提出
3. **Discord/Telegram**: コミュニティサポート
4. **Email**: [email protected]

---

## 次のステップ

- [開発ガイド](./development.md) - ローカル開発環境の構築
- [API仕様書](./api-specification.md) - APIリファレンス
- [アーキテクチャ](./architecture.md) - システム設計詳細
