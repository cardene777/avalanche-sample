# API Specification

**x402 Paywall DApp - RESTful API**

---

## Backend API (Port 4000)

### Base URL
```
http://localhost:4000
```

---

### 1. Get Content by ID

**Endpoint**: `GET /api/content/:id`

**Description**: x402プロトコルに従って有料コンテンツを取得します。購入者がアクセス権を持っている場合はコンテンツURLを返し、持っていない場合は402エラーと支払い情報を返します。

**Headers**:
- `X-BUYER-ADDRESS` (required): 購入者のEthereumアドレス

**Path Parameters**:
- `id` (string): コンテンツID

**Response 200 OK** (アクセス権あり):
```json
{
  "id": "premium-guide-avalanche-icm",
  "title": "Complete Guide to Avalanche Interchain Messaging",
  "description": "Learn how to build cross-chain applications...",
  "contentUrl": "https://example.com/content/premium-guide.pdf",
  "metadata": {
    "category": "Tutorial",
    "tags": ["avalanche", "icm", "cross-chain"],
    "createdAt": 1731772800
  }
}
```

**Response 402 Payment Required** (アクセス権なし):

Headers:
```
X-PAYMENT: {"tokenAddress":"0x...","amount":"1000000000000000000","recipient":"0x...","contentId":"premium-guide-avalanche-icm","facilitatorUrl":"http://localhost:5000"}
```

Body:
```json
{
  "error": "Payment Required",
  "message": "You need to pay to access this content",
  "content": {
    "id": "premium-guide-avalanche-icm",
    "title": "Complete Guide to Avalanche Interchain Messaging",
    "description": "Learn how to build cross-chain applications...",
    "price": "1000000000000000000",
    "preview": "Avalanche Interchain Messaging (ICM) enables..."
  },
  "paymentRequired": {
    "tokenAddress": "0x1234567890123456789012345678901234567890",
    "amount": "1000000000000000000",
    "recipient": "0x0000000000000000000000000000000000000001",
    "contentId": "premium-guide-avalanche-icm",
    "facilitatorUrl": "http://localhost:5000"
  }
}
```

**Response 400 Bad Request**:
```json
{
  "error": "Missing X-BUYER-ADDRESS header",
  "message": "Buyer wallet address is required"
}
```

**Response 404 Not Found**:
```json
{
  "error": "Content not found",
  "message": "No content found with id: invalid-id"
}
```

**Example**:
```bash
curl -H "X-BUYER-ADDRESS: 0xABCDEF1234567890ABCDEF1234567890ABCDEF12" \
     http://localhost:4000/api/content/premium-guide-avalanche-icm
```

---

### 2. List All Content

**Endpoint**: `GET /api/content`

**Description**: 利用可能な全コンテンツの一覧を取得します（公開情報のみ）。

**Response 200 OK**:
```json
{
  "content": [
    {
      "id": "premium-guide-avalanche-icm",
      "title": "Complete Guide to Avalanche Interchain Messaging",
      "description": "Learn how to build cross-chain applications...",
      "price": "1000000000000000000",
      "preview": "Avalanche Interchain Messaging (ICM) enables...",
      "metadata": {
        "category": "Tutorial",
        "tags": ["avalanche", "icm", "cross-chain"],
        "createdAt": 1731772800
      }
    },
    {
      "id": "exclusive-video-erc3009",
      "title": "Mastering ERC-3009 Gasless Payments",
      "description": "Video course on implementing ERC-3009...",
      "price": "500000000000000000",
      "preview": "ERC-3009 introduces a gasless payment mechanism...",
      "metadata": {
        "category": "Video Course",
        "tags": ["ethereum", "erc3009", "gasless"],
        "createdAt": 1731772800
      }
    }
  ],
  "total": 2
}
```

**Example**:
```bash
curl http://localhost:4000/api/content
```

---

### 3. Health Check

**Endpoint**: `GET /health`

**Description**: バックエンドサービスとEchoチェーンの接続状態を確認します。

**Response 200 OK**:
```json
{
  "status": "ok",
  "timestamp": "2025-11-17T08:00:00.000Z",
  "services": {
    "echo": {
      "connected": true,
      "blockNumber": 123456,
      "rpcUrl": "https://subnets.avax.network/echo/testnet/rpc"
    }
  },
  "contentCount": 4
}
```

**Response 500 Internal Server Error**:
```json
{
  "status": "error",
  "error": "Echo chain connection failed"
}
```

**Example**:
```bash
curl http://localhost:4000/health
```

---

## Facilitator API (Port 5000)

### Base URL
```
http://localhost:5000
```

---

### 1. Submit Payment Authorization

**Endpoint**: `POST /api/payment/authorize`

**Description**: ユーザーが署名した支払い認証を受け取り、ガス代不要でトークン転送を実行します。

**Request Body**:
```json
{
  "from": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
  "to": "0x0000000000000000000000000000000000000001",
  "value": "1000000000000000000",
  "validAfter": "1731772800",
  "validBefore": "1731776400",
  "nonce": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "signature": {
    "v": 27,
    "r": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
    "s": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  },
  "contentId": "premium-guide-avalanche-icm"
}
```

**Response 200 OK**:
```json
{
  "success": true,
  "transactionHash": "0xabc123def456...",
  "blockNumber": 789012,
  "paymentSettled": true,
  "message": "Payment processed successfully"
}
```

**Response 400 Bad Request**:
```json
{
  "error": "Invalid signature",
  "message": "Signature verification failed"
}
```

**Response 409 Conflict**:
```json
{
  "error": "Nonce already used",
  "message": "This payment authorization has already been processed"
}
```

**Response 500 Internal Server Error**:
```json
{
  "error": "Transaction failed",
  "message": "Failed to execute transferWithAuthorization"
}
```

**Example**:
```bash
curl -X POST http://localhost:5000/api/payment/authorize \
  -H "Content-Type: application/json" \
  -d '{
    "from": "0xABCD...",
    "to": "0x0000...",
    "value": "1000000000000000000",
    "validAfter": "1731772800",
    "validBefore": "1731776400",
    "nonce": "0x1234...",
    "signature": {
      "v": 27,
      "r": "0xabcd...",
      "s": "0x1234..."
    },
    "contentId": "premium-guide-avalanche-icm"
  }'
```

---

### 2. Get Payment Status

**Endpoint**: `GET /api/payment/status/:txHash`

**Description**: トランザクションハッシュから支払いステータスを確認します。

**Path Parameters**:
- `txHash` (string): トランザクションハッシュ

**Response 200 OK**:
```json
{
  "transactionHash": "0xabc123def456...",
  "status": "confirmed",
  "blockNumber": 789012,
  "timestamp": 1731772800,
  "from": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
  "to": "0x0000000000000000000000000000000000000001",
  "amount": "1000000000000000000",
  "settled": true
}
```

**Response 404 Not Found**:
```json
{
  "error": "Transaction not found",
  "message": "No payment found with transaction hash: 0x..."
}
```

**Example**:
```bash
curl http://localhost:5000/api/payment/status/0xabc123def456...
```

---

### 3. Health Check

**Endpoint**: `GET /health`

**Description**: Facilitatorサービスの稼働状態を確認します。

**Response 200 OK**:
```json
{
  "status": "ok",
  "timestamp": "2025-11-17T08:00:00.000Z",
  "services": {
    "dispatch": {
      "connected": true,
      "blockNumber": 456789,
      "rpcUrl": "https://subnets.avax.network/dispatch/testnet/rpc"
    }
  },
  "walletAddress": "0x1234567890123456789012345678901234567890",
  "balance": "10000000000000000000"
}
```

**Example**:
```bash
curl http://localhost:5000/health
```

---

## EIP-712 Typed Data Structure

### transferWithAuthorization

```typescript
{
  types: {
    EIP712Domain: [
      { name: "name", type: "string" },
      { name: "version", type: "string" },
      { name: "chainId", type: "uint256" },
      { name: "verifyingContract", type: "address" }
    ],
    TransferWithAuthorization: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "value", type: "uint256" },
      { name: "validAfter", type: "uint256" },
      { name: "validBefore", type: "uint256" },
      { name: "nonce", type: "bytes32" }
    ]
  },
  domain: {
    name: "PaymentToken",
    version: "1",
    chainId: 123456,
    verifyingContract: "0x1234567890123456789012345678901234567890"
  },
  primaryType: "TransferWithAuthorization",
  message: {
    from: "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
    to: "0x0000000000000000000000000000000000000001",
    value: "1000000000000000000",
    validAfter: "1731772800",
    validBefore: "1731776400",
    nonce: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  }
}
```

---

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 200 | OK | リクエスト成功 |
| 400 | Bad Request | 不正なリクエスト（必須パラメータ欠如、無効なアドレスなど） |
| 402 | Payment Required | 支払いが必要（x402プロトコル） |
| 404 | Not Found | リソースが見つからない |
| 409 | Conflict | 競合（nonce重複など） |
| 500 | Internal Server Error | サーバーエラー |

---

## Rate Limiting (Future)

本番環境では以下のレート制限を推奨：

- `GET /api/content/*`: 100 requests/minute per IP
- `POST /api/payment/authorize`: 10 requests/minute per wallet address
- `GET /health`: 無制限

---

## CORS Configuration

開発環境:
```
Access-Control-Allow-Origin: *
```

本番環境:
```
Access-Control-Allow-Origin: https://your-frontend-domain.com
```

---

## Webhook Events (Future)

将来的に実装予定のWebhook:

### Payment Confirmed
```json
{
  "event": "payment.confirmed",
  "timestamp": 1731772800,
  "data": {
    "transactionHash": "0xabc...",
    "buyer": "0xABCD...",
    "contentId": "premium-guide-avalanche-icm",
    "amount": "1000000000000000000"
  }
}
```

### Access Granted
```json
{
  "event": "access.granted",
  "timestamp": 1731772850,
  "data": {
    "buyer": "0xABCD...",
    "contentId": "premium-guide-avalanche-icm",
    "grantedAt": 1731772850
  }
}
```
