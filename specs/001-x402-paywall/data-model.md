# Data Model: x402 Paywall Dapp with Avalanche ICM

**Feature**: 001-x402-paywall
**Phase**: 1 (Design & Contracts)
**Date**: 2025-11-16

## Overview

This document defines the data models and entities for the x402 paywall system. Entities are stored across multiple layers: on-chain (Dispatch/Echo), off-chain (backend cache), and ephemeral (request/response).

---

## Entity Catalog

| Entity | Storage Location | Purpose |
|--------|------------------|---------|
| Content | Backend (off-chain) | Premium content metadata and data |
| Payment | Dispatch chain (on-chain) | Payment transaction records |
| Access | Echo chain (on-chain) | Access control permissions (source of truth) |
| Buyer | Wallet address (external) | User identity via blockchain address |
| Payment Authorization | Ephemeral (signature) | ERC-3009 authorization message |
| Cross-Chain Message | ICM (in-flight) | Payment notification from Dispatch to Echo |

---

## 1. Content

**Purpose**: Represents premium digital content that requires payment to access.

### Attributes

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | `string` | Unique content identifier (e.g., "article-123") | Required, unique, alphanumeric |
| `title` | `string` | Content display title | Required, max 200 chars |
| `description` | `string` | Short summary of content | Optional, max 500 chars |
| `price` | `number` (string in contract) | Price in payment token units (e.g., "0.5" USDC) | Required, > 0 |
| `contentType` | `string` | MIME type or category (e.g., "article", "video", "data") | Required |
| `contentData` | `any` | Actual content payload (JSON, HTML, binary, etc.) | Required |
| `createdAt` | `timestamp` | Content creation timestamp | Auto-generated |
| `published` | `boolean` | Whether content is available for purchase | Default: true |

### Storage

- **Backend database or file system**: Stores content metadata and data
- **Not stored on-chain**: Too expensive; only access control is on-chain

### Validation Rules

- `id` must be unique across all content
- `price` must be parseable as positive decimal number
- `contentData` access gated by checking Echo chain `Access` entity

### State Transitions

```
Created (published=false) → Published (published=true) → Archived (published=false)
```

### Example

```json
{
  "id": "article-123",
  "title": "Advanced Avalanche ICM Patterns",
  "description": "Deep dive into cross-chain messaging patterns",
  "price": "0.5",
  "contentType": "article",
  "contentData": {
    "format": "markdown",
    "body": "# Advanced Patterns\n\n..."
  },
  "createdAt": "2025-11-16T10:00:00Z",
  "published": true
}
```

---

## 2. Payment

**Purpose**: Records a payment transaction on Dispatch chain.

### Attributes (On-Chain)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `buyer` | `address` | Wallet address of the buyer | Required, valid Ethereum address |
| `contentId` | `bytes32` | Keccak256 hash of content ID string | Required |
| `amount` | `uint256` | Payment amount in token base units (e.g., wei) | Required, > 0 |
| `paymentTxHash` | `bytes32` | Transaction hash of the ERC-3009 transfer | Recorded on-chain |
| `timestamp` | `uint256` | Block timestamp of payment | Auto-generated |
| `settled` | `bool` | Whether payment has been recorded | Default: true after settlement |

### Storage

- **Dispatch chain**: `PaymentRegistry` contract mapping
  ```solidity
  mapping(address buyer => mapping(bytes32 contentId => Payment)) public payments;
  ```

### Validation Rules

- `buyer` must be a valid address (not zero address)
- `contentId` must be keccak256 hash of valid content ID
- `amount` must match expected price for content
- Transaction must be confirmed on Dispatch chain

### Lifecycle

1. **Authorized**: User signs ERC-3009 authorization (off-chain)
2. **Executed**: Facilitator calls `transferWithAuthorization` → tokens transferred
3. **Settled**: `PaymentRegistry.settlePayment` records payment and sends ICM message
4. **Relayed**: ICM relayer delivers message to Echo chain

### Example (On-Chain Storage)

```solidity
struct Payment {
    address buyer;
    bytes32 contentId;
    uint256 amount;
    bytes32 paymentTxHash;
    uint256 timestamp;
    bool settled;
}
```

---

## 3. Access

**Purpose**: Represents permission to view specific content, stored on Echo chain as source of truth.

### Attributes (On-Chain)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `buyer` | `address` | Wallet address of the buyer | Required, valid Ethereum address |
| `contentId` | `bytes32` | Keccak256 hash of content ID string | Required |
| `granted` | `bool` | Whether access is granted | Default: false, set to true after payment |
| `grantedAt` | `uint256` | Block timestamp when access was granted | Auto-generated |
| `sourceChain` | `bytes32` | Chain ID where payment originated (Dispatch) | Immutable |
| `paymentTxHash` | `bytes32` | Original payment transaction hash | Immutable, for audit trail |

### Storage

- **Echo chain**: `ContentAccessManager` contract mapping
  ```solidity
  mapping(address buyer => mapping(bytes32 contentId => bool)) public access;
  ```

### Validation Rules

- `buyer` must be non-zero address
- `contentId` must be valid keccak256 hash
- Can only be set to `true` by `receiveTeleporterMessage` from authorized sender

### Constitutional Principle

**Principle I: On-chain as Source of Truth**
- Echo chain's `ContentAccessManager.access[buyer][contentId]` is the **single source of truth**
- Backend database (if used) can cache for performance but must defer to on-chain state
- In case of discrepancy, on-chain state always wins

### Lifecycle

1. **Non-existent**: `access[buyer][contentId] == false` (default)
2. **Granted**: Payment message received via ICM, set to `true`
3. **Revoked**: (Optional future feature, not in v1)

### Example (On-Chain Storage)

```solidity
mapping(address => mapping(bytes32 => bool)) public access;

// Query
bool hasAccess = contentAccessManager.access(buyerAddress, keccak256("article-123"));
```

---

## 4. Buyer

**Purpose**: A user identified by their wallet address who may purchase and access content.

### Attributes

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `address` | `address` | Ethereum-compatible wallet address | Required, unique |
| `nonces` | `mapping(bytes32 => bool)` | Used nonces for ERC-3009 (on-chain, in token contract) | Managed by ERC3009PaymentToken |

### Storage

- **No dedicated storage**: Buyer is represented by their wallet address
- **Nonces**: Tracked in `ERC3009PaymentToken` contract on Dispatch chain

### Validation Rules

- Must have valid wallet (Core, MetaMask, etc.)
- Must sign EIP-712 messages for ERC-3009 authorizations
- Nonces must be unique and unused

### Implicit Relationships

- **Payments**: `Payment.buyer == Buyer.address`
- **Access**: `Access.buyer == Buyer.address`

---

## 5. Payment Authorization

**Purpose**: An ERC-3009 signature authorizing token transfer, created by buyer and submitted to facilitator.

### Attributes (EIP-712 Typed Data)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `from` | `address` | Buyer's wallet address | Required |
| `to` | `address` | Payment recipient (merchant/content owner) | Required |
| `value` | `uint256` | Transfer amount in token base units | Required, > 0 |
| `validAfter` | `uint256` | Timestamp after which authorization is valid | Required, <= block.timestamp |
| `validBefore` | `uint256` | Timestamp before which authorization is valid | Required, > block.timestamp |
| `nonce` | `bytes32` | Unique identifier to prevent replay | Required, unused |
| `v` | `uint8` | ECDSA signature component | Required |
| `r` | `bytes32` | ECDSA signature component | Required |
| `s` | `bytes32` | ECDSA signature component | Required |

### Storage

- **Ephemeral**: Exists only during signature generation and submission
- **Not stored**: Once used, nonce is marked as spent in `ERC3009PaymentToken`

### EIP-712 Domain

```typescript
const domain = {
  name: "ERC3009PaymentToken",
  version: "1",
  chainId: DISPATCH_CHAIN_ID,
  verifyingContract: ERC3009_TOKEN_ADDRESS
};

const types = {
  TransferWithAuthorization: [
    { name: "from", type: "address" },
    { name: "to", type: "address" },
    { name: "value", type: "uint256" },
    { name: "validAfter", type: "uint256" },
    { name: "validBefore", type: "uint256" },
    { name: "nonce", type: "bytes32" }
  ]
};
```

### Validation Rules

- Signature must be valid for `from` address
- `validAfter <= now < validBefore`
- `nonce` must not have been used before
- `value` must match expected payment amount

### Lifecycle

1. **Generated**: Frontend creates EIP-712 message and prompts wallet signature
2. **Signed**: User approves in wallet, signature (v, r, s) returned
3. **Submitted**: Frontend sends authorization to facilitator
4. **Validated**: Facilitator checks parameters and signature
5. **Executed**: Facilitator calls `transferWithAuthorization` on-chain
6. **Spent**: Nonce marked as used, cannot be replayed

---

## 6. Cross-Chain Message

**Purpose**: An ICM message sent from Dispatch to Echo containing payment information to grant access.

### Attributes (ICM Message Payload)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `buyer` | `address` | Buyer's wallet address | Required |
| `contentId` | `bytes32` | Content identifier (keccak256 hash) | Required |
| `amount` | `uint256` | Payment amount | Required |
| `paymentTxHash` | `bytes32` | Original payment transaction hash | Required |
| `timestamp` | `uint256` | Payment timestamp on Dispatch | Auto-generated |

### ICM Metadata

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `originChainID` | `bytes32` | Dispatch chain ID | Validated on receipt |
| `originSenderAddress` | `address` | PaymentRegistry contract address | Validated on receipt |
| `destinationChainID` | `bytes32` | Echo chain ID | Set by sender |
| `destinationAddress` | `address` | ContentAccessManager contract address | Set by sender |

### Storage

- **In-flight**: Stored in TeleporterMessenger contract state during relay
- **Not persisted**: Once delivered and processed, message is not stored permanently

### Lifecycle

1. **Created**: `PaymentRegistry.settlePayment` encodes message
2. **Sent**: `TeleporterMessenger.sendCrossChainMessage` emits event on Dispatch
3. **Relayed**: ICM relayer detects event and calls `receiveCrossChainMessage` on Echo
4. **Received**: `ContentAccessManager.receiveTeleporterMessage` validates and processes
5. **Applied**: `access[buyer][contentId]` set to `true` on Echo chain

### Security Validation (Constitutional Principle VI)

```solidity
function receiveTeleporterMessage(
    bytes32 originChainID,
    address originSenderAddress,
    bytes calldata message
) external {
    // Security checks
    require(msg.sender == address(teleporterMessenger), "Only Teleporter");
    require(originChainID == dispatchChainID, "Invalid origin chain");
    require(originSenderAddress == paymentRegistryOnDispatch, "Invalid sender");

    // Decode and apply
    (address buyer, bytes32 contentId, , , ) = abi.decode(message, (...));
    access[buyer][contentId] = true;
}
```

---

## Entity Relationships

```
Buyer (address)
  ├─> Payment Authorization (ephemeral signature)
  │     └─> Payment (Dispatch chain)
  │           └─> Cross-Chain Message (ICM)
  │                 └─> Access (Echo chain) ★ SOURCE OF TRUTH
  │
  └─> Content (Backend storage)
        └─> Access check (Echo chain query)
              └─> Grant or Deny (HTTP 200 / 402)
```

### Flow Summary

1. **User requests content** → Backend checks `Access` on Echo chain
2. **If no access** → Return HTTP 402 with payment requirements
3. **User signs authorization** → Submits to Facilitator
4. **Facilitator executes payment** → Records in `PaymentRegistry` on Dispatch
5. **PaymentRegistry sends ICM message** → Relayed to Echo
6. **ContentAccessManager receives message** → Grants `Access` on Echo
7. **User retries with X-PAYMENT header** → Backend checks Echo, grants content

---

## State Consistency

### Source of Truth: Echo Chain

**Constitutional Principle I**: Echo chain `ContentAccessManager.access` is the **single source of truth**.

### Eventual Consistency

- **Dispatch → Echo**: Payment on Dispatch → Access on Echo (delay: ~30 seconds per SC-003)
- **Backend cache**: Optional, read-only, must refresh from Echo periodically

### Conflict Resolution

If backend cache conflicts with Echo chain:
1. Query Echo chain directly
2. Update cache to match
3. Log discrepancy for audit

---

## Data Flow Diagram

```
┌─────────────┐
│   Buyer     │
│  (Wallet)   │
└──────┬──────┘
       │
       │ 1. GET /api/content/:id
       ▼
┌─────────────────────┐
│  Backend (API)      │
│  - Query Echo chain │  ───┐
│  - Check access     │     │
└─────────────────────┘     │
       │                    │ 2. Read access[buyer][contentId]
       │ HTTP 402           │
       ▼                    ▼
┌─────────────────────┐  ┌──────────────────────┐
│  Frontend           │  │  Echo Chain          │
│  - x402 client      │  │  ContentAccessManager│
│  - EIP-712 signer   │  │  ★ SOURCE OF TRUTH   │
└──────┬──────────────┘  └──────────────────────┘
       │                           ▲
       │ 3. Sign authorization     │
       ▼                           │ 6. ICM message
┌─────────────────────┐            │    grants access
│  Facilitator        │            │
│  - Validate sig     │            │
│  - Execute payment  │            │
└──────┬──────────────┘            │
       │                           │
       │ 4. transferWithAuthorization
       ▼                           │
┌─────────────────────┐            │
│  Dispatch Chain     │            │
│  ERC3009Token       │            │
│  PaymentRegistry    │────────────┘
└─────────────────────┘  5. sendCrossChainMessage
```

---

## Notes

- All on-chain storage uses `bytes32` for `contentId` (keccak256 hash of string ID)
- Backend storage can use human-readable string IDs (e.g., "article-123")
- Payment amounts use token base units (e.g., USDC with 6 decimals: "0.5" USDC = 500000 base units)
- Cross-chain message relay time target: <30 seconds (Success Criterion SC-003)
