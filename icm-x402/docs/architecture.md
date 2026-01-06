# System Architecture

**x402 Paywall DApp with Avalanche ICM**

---

## Overview

このシステムは、**Avalanche Interchain Messaging (ICM)** を使用したクロスチェーン有料コンテンツ配信プラットフォームです。

### Key Components

```
┌─────────────┐
│   Browser   │ ← ユーザー
└──────┬──────┘
       │
       ├─── GET /api/content/:id (X-BUYER-ADDRESS header)
       │
       v
┌─────────────────────────────────────────────────────────┐
│                    Backend (Port 4000)                  │
│  - Content API (x402 protocol)                          │
│  - Access Checker (queries Echo chain)                  │
│  - Payment Helper (EIP-712 signing)                     │
└────────────────────┬───────────────────┬────────────────┘
                     │                   │
        ┌────────────┘                   └────────────┐
        v                                             v
┌─────────────────┐                         ┌─────────────────┐
│  Echo L1 Chain  │                         │ Dispatch L1     │
│  (Access)       │                         │ (Payment)       │
│                 │                         │                 │
│ ContentAccess   │ ←─── ICM Message ────  │ PaymentRegistry │
│ Manager         │      (Teleporter)       │                 │
└─────────────────┘                         └────────┬────────┘
                                                     │
                                            ┌────────┴────────┐
                                            │                 │
                                            v                 v
                                    ┌──────────────┐  ┌─────────────┐
                                    │ ERC3009Token │  │ Facilitator │
                                    │              │  │ (Port 5000) │
                                    └──────────────┘  └─────────────┘
```

---

## Architecture Layers

### 1. Frontend Layer (Port 3000)
- **Technology**: Next.js 14+, React, TailwindCSS
- **Responsibilities**:
  - コンテンツ一覧表示
  - ウォレット接続 (MetaMask, Core Wallet)
  - EIP-712署名の生成
  - 支払いフローのUI

### 2. Backend Layer (Port 4000)
- **Technology**: Node.js 20, Express, TypeScript
- **Responsibilities**:
  - **x402 Protocol**: HTTP 402 Payment Required実装
  - **Access Control**: Echoチェーンへの問い合わせ
  - **Content Delivery**: アクセス権がある場合のみコンテンツURLを返す

**API Endpoints**:
- `GET /api/content/:id` - コンテンツ取得（x402）
- `GET /api/content` - コンテンツ一覧
- `GET /health` - ヘルスチェック

### 3. Facilitator Layer (Port 5000)
- **Technology**: Node.js 20, Express, TypeScript
- **Responsibilities**:
  - **Gasless Payment**: ユーザーの署名を受け取り、代わりにガス代を支払って送信
  - **ERC-3009 Execution**: `transferWithAuthorization`の実行
  - **Payment Settlement**: PaymentRegistryへの記録

**API Endpoints**:
- `POST /api/payment/authorize` - 支払い認証受付
- `GET /api/payment/status/:txHash` - 支払いステータス確認

### 4. Relayer Layer (Background Service)
- **Technology**: Node.js 20, TypeScript
- **Responsibilities**:
  - ICMメッセージの中継監視
  - DispatchからEchoへのメッセージ配信確認
  - エラーハンドリングとリトライ

### 5. Smart Contract Layer

#### Dispatch Chain (Payment Layer)

**ERC3009PaymentToken.sol**
```solidity
function transferWithAuthorization(
    address from,      // 支払い元（ユーザー）
    address to,        // 支払い先（コンテンツプロバイダー）
    uint256 value,     // 金額
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v, bytes32 r, bytes32 s  // EIP-712署名
) external
```

**PaymentRegistry.sol**
```solidity
function settlePayment(
    address buyer,
    bytes32 contentId,
    uint256 amount,
    bytes32 paymentTxHash
) external onlyOwner
```
- 支払い記録を保存
- ICMメッセージをEchoチェーンに送信

#### Echo Chain (Access Control Layer)

**ContentAccessManager.sol**
```solidity
function receiveTeleporterMessage(
    bytes32 originChainID,
    address originSenderAddress,
    bytes calldata message
) external override
```
- ICMメッセージを受信
- アクセス権を付与
- **唯一の真実の情報源** (Single Source of Truth)

---

## Data Flow

### Flow 1: コンテンツアクセス要求

```
1. User → Backend: GET /api/content/premium-guide
   Header: X-BUYER-ADDRESS: 0xABC...

2. Backend → Echo Chain: hasAccess(0xABC..., "premium-guide")

3. Echo Chain → Backend: false (アクセス権なし)

4. Backend → User: 402 Payment Required
   Header: X-PAYMENT: {tokenAddress, amount, recipient, ...}
   Body: {paymentRequired: {...}}
```

### Flow 2: ガス代不要の支払い

```
1. User → Browser Wallet: EIP-712署名要求
   TypedData: {from, to, value, validAfter, validBefore, nonce}

2. Browser Wallet → User: 署名生成 (v, r, s)

3. User → Facilitator: POST /api/payment/authorize
   Body: {from, to, value, ..., signature: {v, r, s}}

4. Facilitator → Dispatch Chain: transferWithAuthorization(...)
   ※ Facilitatorがガス代を支払う

5. Dispatch Chain: トークン転送実行

6. Facilitator → PaymentRegistry: settlePayment(...)

7. PaymentRegistry → TeleporterMessenger: sendCrossChainMessage(...)
```

### Flow 3: クロスチェーンアクセス付与

```
1. TeleporterMessenger (Dispatch) → TeleporterMessenger (Echo): ICM送信

2. TeleporterMessenger (Echo) → ContentAccessManager: receiveTeleporterMessage(...)

3. ContentAccessManager: アクセス権を付与
   mapping: access[buyer][contentId] = true

4. User → Backend: GET /api/content/premium-guide (再試行)

5. Backend → Echo Chain: hasAccess(0xABC..., "premium-guide")

6. Echo Chain → Backend: true (アクセス権あり)

7. Backend → User: 200 OK
   Body: {contentUrl: "https://..."}
```

---

## Security Considerations

### 1. Signature Verification (EIP-712)
- ユーザーの署名を厳密に検証
- Domain Separator、ChainID、Verifying Contractを確認
- Nonce管理でリプレイ攻撃を防止

### 2. ICM Message Validation
```solidity
require(msg.sender == address(teleporterMessenger), "Invalid messenger");
require(originChainID == dispatchChainID, "Invalid origin chain");
require(originSenderAddress == paymentRegistryAddress, "Invalid sender");
```

### 3. Access Control
- PaymentRegistry: `onlyOwner` (Facilitatorのみ)
- ContentAccessManager: ICMメッセージのみ受付
- Backend: Echoチェーンの状態のみを信頼

### 4. Nonce Management
- 各ユーザーごとに一意のnonceを使用
- 使用済みnonceの再利用を防止
- `authorizationState[authorizer][nonce] = true`

---

## Scaling Considerations

### Horizontal Scaling
- **Backend**: ステートレス設計、複数インスタンスでロードバランス可能
- **Facilitator**: ワーカープール、複数署名者で並列処理
- **Relayer**: 複数リレイヤーでメッセージ監視

### Caching Strategy
- Content metadata: Redis/Memcached
- Access status: 短時間キャッシュ (30秒程度)
- Chain RPC: connection pooling

### Database (Future)
現在はin-memoryですが、本番環境では：
- **Content Store**: PostgreSQL / MongoDB
- **Payment Records**: PostgreSQL (トランザクション対応)
- **Access Logs**: TimescaleDB / ClickHouse

---

## Monitoring & Observability

### Health Checks
- `GET /health` - 各サービスの稼働状態
- Echo/Dispatch Chain RPC接続確認
- Block height監視

### Metrics (推奨)
- Payment success rate
- ICM message delivery time
- Content access latency
- Error rates by endpoint

### Logging
- Structured logging (JSON)
- Request/Response logging
- Payment transaction logs
- ICM message tracking

---

## Deployment Architecture

```
┌─────────────────────────────────────────┐
│          Docker Compose                 │
│                                         │
│  ┌──────────┐  ┌──────────┐            │
│  │ Frontend │  │ Backend  │            │
│  │  :3000   │  │  :4000   │            │
│  └──────────┘  └──────────┘            │
│                                         │
│  ┌──────────┐  ┌──────────┐            │
│  │Facilitator│  │ Relayer  │            │
│  │  :5000   │  │(background)           │
│  └──────────┘  └──────────┘            │
└─────────────────────────────────────────┘
           │
           ├──── Dispatch L1 Testnet
           │     (https://subnets.avax.network/dispatch/testnet/rpc)
           │
           └──── Echo L1 Testnet
                 (https://subnets.avax.network/echo/testnet/rpc)
```

---

## Technology Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| Smart Contracts | Solidity | 0.8.20 |
| Contract Framework | Hardhat | 2.27+ |
| Backend Runtime | Node.js | 20+ |
| Language | TypeScript | 5.0+ |
| Backend Framework | Express | 4.21+ |
| Frontend Framework | Next.js | 14+ |
| Blockchain Library | ethers.js | 6.15+ |
| Package Manager | Bun | 1.2+ |
| Container | Docker | 20+ |
| Base Image | Alpine Linux | 3.18+ |

---

## References

- [Avalanche ICM Documentation](https://docs.avax.network/cross-chain)
- [ERC-3009 Specification](https://eips.ethereum.org/EIPS/eip-3009)
- [EIP-712 Typed Data](https://eips.ethereum.org/EIPS/eip-712)
- [HTTP 402 Payment Required](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/402)
