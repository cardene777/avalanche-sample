# Research: x402 Paywall Dapp with Avalanche ICM

**Feature**: 001-x402-paywall
**Phase**: 0 (Outline & Research)
**Date**: 2025-11-16

## Overview

This document consolidates research findings for implementing an x402-based paywall system using Avalanche ICM for cross-chain payment and access management between Dispatch and Echo L1 testnets.

---

## 1. ERC-3009: TransferWithAuthorization

### Decision

Use **ERC-3009 `transferWithAuthorization`** for gasless payments, allowing users to authorize token transfers via EIP-712 signatures without holding gas tokens.

### Rationale

- **Gasless UX**: Users sign authorization messages off-chain; facilitator executes on-chain transactions and pays gas
- **Security**: EIP-712 typed structured data signing provides domain separation and prevents replay attacks
- **Nonce management**: Each authorization includes a unique nonce to prevent double-spending
- **Time-bound**: `validAfter` and `validBefore` parameters limit authorization validity window
- **USDC compatibility**: ERC-3009 is used by Circle's USDC, providing proven implementation reference

### Implementation Pattern

```solidity
// Payment token contract (Dispatch chain)
interface IERC3009 {
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
```

**Frontend signature generation**:
- Use ethers.js `_signTypedData` with EIP-712 domain and Authorization typehash
- Include payment parameters (from, to, amount, validAfter, validBefore, nonce)
- Submit signature components (v, r, s) to facilitator

**Facilitator execution**:
- Validate signature parameters
- Call `transferWithAuthorization` on ERC3009PaymentToken contract
- Pay gas on behalf of user
- Return transaction hash as payment proof

### Alternatives Considered

- **Meta-transactions (ERC-2771)**: More complex, requires trusted forwarder infrastructure
- **Gasless relay networks (GSN)**: External dependency, adds complexity and potential centralization
- **Traditional approve/transferFrom**: Requires two transactions, poor UX

**Rejected because**: ERC-3009 provides the simplest, most proven pattern for gasless token transfers with clear security guarantees.

---

## 2. Avalanche ICM / TeleporterMessenger Integration

### Decision

Use **`ava-labs/icm-contracts`** official implementation for all cross-chain messaging between Dispatch and Echo.

### Rationale

- **Security-audited**: Official Avalanche contracts with community review
- **Maintained**: Active development and version management via TeleporterRegistry
- **Proven**: Used in production by Avalanche ecosystem projects
- **Constitutional requirement**: Constitution mandates use of official ICM contracts (Principle V)

### Implementation Pattern

**Sending messages (Dispatch → Echo)**:
```solidity
// PaymentRegistry on Dispatch
import "@ava-labs/icm-contracts/contracts/teleporter/ITeleporterMessenger.sol";

contract PaymentRegistry {
    ITeleporterMessenger public immutable teleporterMessenger;
    bytes32 public immutable echoChainID;
    address public immutable contentAccessManagerOnEcho;

    function settlePayment(address buyer, bytes32 contentId, uint256 amount) external {
        bytes memory messageData = abi.encode(buyer, contentId, amount, block.timestamp);

        teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: echoChainID,
                destinationAddress: contentAccessManagerOnEcho,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: messageData
            })
        );
    }
}
```

**Receiving messages (Echo)**:
```solidity
// ContentAccessManager on Echo
import "@ava-labs/icm-contracts/contracts/teleporter/ITeleporterReceiver.sol";

contract ContentAccessManager is ITeleporterReceiver {
    ITeleporterMessenger public immutable teleporterMessenger;
    bytes32 public immutable dispatchChainID;
    address public immutable paymentRegistryOnDispatch;

    mapping(address => mapping(bytes32 => bool)) public access;

    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external {
        // Security checks (Constitutional requirement: Principle VI)
        require(msg.sender == address(teleporterMessenger), "Only Teleporter");
        require(originChainID == dispatchChainID, "Invalid origin chain");
        require(originSenderAddress == paymentRegistryOnDispatch, "Invalid sender");

        (address buyer, bytes32 contentId, uint256 amount, uint256 timestamp) =
            abi.decode(message, (address, bytes32, uint256, uint256));

        access[buyer][contentId] = true;
        emit AccessGranted(buyer, contentId, amount, timestamp);
    }
}
```

### Relayer Strategy

**ICM Relayer service**:
- Monitors `SendCrossChainMessage` events on Dispatch TeleporterMessenger
- Calls `receiveCrossChainMessage` on Echo TeleporterMessenger
- Runs as Docker container with access to both chain RPCs
- Can use Avalanche's official relayer implementation or custom Node.js wrapper

### Alternatives Considered

- **Custom message passing**: Implement own cross-chain communication
- **Layerzero/Wormhole**: Third-party cross-chain messaging protocols

**Rejected because**: Constitution mandates official ICM contracts, and custom implementations introduce security risks and maintenance burden.

---

## 3. x402 Protocol Implementation

### Decision

Implement **x402 HTTP-based payment protocol** for content API, following the `402 Payment Required` → `X-PAYMENT` → retry flow.

### Rationale

- **Standards-based**: x402 provides machine-readable payment requirements
- **Client compatibility**: Future x402 clients can consume the API without modification
- **Constitutional requirement**: Principle II mandates x402 compliance for all HTTP flows
- **Simple integration**: Frontend can use generic x402 wrapper library

### HTTP Flow Pattern

**1st Request (Unpaid)**:
```http
GET /api/content/article-123
Authorization: Bearer <user-token>

HTTP/1.1 402 Payment Required
Content-Type: application/json

{
  "x402Version": 1,
  "paymentRequirements": [
    {
      "network": "avalanche-dispatch-testnet",
      "tokenAddress": "0x...",
      "amount": "0.5",
      "recipient": "0x...",
      "reference": "content:article-123"
    }
  ],
  "facilitator": "https://facilitator.example.com/x402"
}
```

**2nd Request (Paid)**:
```http
GET /api/content/article-123
Authorization: Bearer <user-token>
X-PAYMENT: <payment-proof-jwt>

HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "article-123",
  "title": "Premium Content",
  "body": "..."
}
```

### Payment Proof Format

**Facilitator issues signed JWT** after successful payment:
```json
{
  "buyer": "0x...",
  "contentId": "article-123",
  "amount": "0.5",
  "txHash": "0x...",
  "timestamp": 1700000000,
  "signature": "..."
}
```

Resource Server validates by:
1. Verify JWT signature (issued by facilitator)
2. Check Echo chain: `ContentAccessManager.access[buyer][contentId] == true`
3. Grant access if both checks pass

### Alternatives Considered

- **Custom payment headers**: Proprietary protocol
- **OAuth2-based payment**: Overloading authentication protocol

**Rejected because**: x402 is purpose-built for HTTP-layer payments and enables broader client compatibility.

---

## 4. Docker Compose Orchestration

### Decision

Use **Docker Compose** with 4 services: `frontend`, `backend`, `facilitator`, `icm-relayer`.

### Rationale

- **Single-command setup**: `docker compose up` starts entire stack (Constitutional Principle VII)
- **Consistent environments**: Dev/test/demo use identical configuration
- **Network isolation**: Services communicate via Docker networks
- **Environment-based config**: RPC URLs, contract addresses via `.env` files

### Service Architecture

```yaml
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_BACKEND_URL=http://backend:4000
      - NEXT_PUBLIC_FACILITATOR_URL=http://facilitator:5000
    depends_on:
      - backend
      - facilitator

  backend:
    build: ./backend
    ports:
      - "4000:4000"
    environment:
      - ECHO_RPC_URL=${ECHO_RPC_URL}
      - CONTENT_ACCESS_MANAGER_ADDRESS=${CONTENT_ACCESS_MANAGER_ADDRESS}
    volumes:
      - ./backend/content:/app/content

  facilitator:
    build: ./facilitator
    ports:
      - "5000:5000"
    environment:
      - DISPATCH_RPC_URL=${DISPATCH_RPC_URL}
      - ERC3009_TOKEN_ADDRESS=${ERC3009_TOKEN_ADDRESS}
      - PAYMENT_REGISTRY_ADDRESS=${PAYMENT_REGISTRY_ADDRESS}
      - FACILITATOR_PRIVATE_KEY=${FACILITATOR_PRIVATE_KEY}

  icm-relayer:
    build: ./relayer
    environment:
      - DISPATCH_RPC_URL=${DISPATCH_RPC_URL}
      - ECHO_RPC_URL=${ECHO_RPC_URL}
      - DISPATCH_TELEPORTER_ADDRESS=${DISPATCH_TELEPORTER_ADDRESS}
      - ECHO_TELEPORTER_ADDRESS=${ECHO_TELEPORTER_ADDRESS}
```

### Alternatives Considered

- **Kubernetes**: Overkill for local dev, adds complexity
- **Separate manual setup**: Poor developer experience, error-prone

**Rejected because**: Docker Compose provides optimal balance of simplicity and functionality for this use case.

---

## 5. Technology Stack Summary

### Frontend
- **Framework**: Next.js 14+ (App Router)
- **Wallet Integration**: wagmi + viem or ethers.js v6
- **x402 Client**: Custom wrapper or x402-fetch library
- **UI**: React + TailwindCSS (or project preference)

### Backend (Resource Server)
- **Runtime**: Node.js (LTS)
- **Framework**: Express.js or Next.js API routes
- **Blockchain RPC**: ethers.js v6 or viem
- **Avalanche SDK**: @avalabs/avalanchejs

### Facilitator
- **Runtime**: Node.js (LTS)
- **Framework**: Express.js
- **Signature Verification**: ethers.js v6 EIP-712 utilities
- **Blockchain TX**: ethers.js v6 Contract interaction

### ICM Relayer
- **Runtime**: Node.js (LTS) or Avalanche official relayer
- **Event Monitoring**: ethers.js v6 event listeners
- **Message Relay**: Contract calls via ethers.js

### Smart Contracts
- **Language**: Solidity 0.8.x
- **Development**: Hardhat or Foundry
- **Dependencies**: @ava-labs/icm-contracts
- **Testing**: Hardhat tests + Foundry fuzz tests

### Infrastructure
- **Orchestration**: Docker Compose
- **Environment**: .env files for configuration
- **RPC Access**: Public Avalanche testnet RPCs

---

## 6. Security Considerations

### ERC-3009 Signature Security
- **Nonce tracking**: Prevent replay attacks
- **Time bounds**: Limit authorization validity window
- **Domain separation**: EIP-712 domain includes chainId and contract address

### Cross-Chain Message Security
- **Sender validation**: Verify `msg.sender == teleporterMessenger`
- **Origin validation**: Check `originChainID` and `originSenderAddress`
- **Message integrity**: Use `abi.encode` for structured data

### Facilitator Security
- **Private key management**: Use Docker secrets or secure env vars
- **Rate limiting**: Prevent DoS on facilitator endpoints
- **Signature validation**: Verify all ERC-3009 parameters before execution

### Access Control
- **On-chain truth**: Echo chain is single source of truth for access (Principle I)
- **No backend bypass**: Backend reads only, cannot grant access directly

---

## 7. Open Questions & Next Steps

### Resolved
- ✅ Payment token standard: ERC-3009
- ✅ Cross-chain messaging: Avalanche ICM official contracts
- ✅ HTTP protocol: x402
- ✅ Deployment: Docker Compose

### To Be Determined in Phase 1
- Content storage mechanism (database choice, IPFS, etc.)
- Content pricing model (fixed price vs dynamic)
- Payment token decimals and amounts
- Facilitator gas management strategy (prefunded wallet, gas estimator)
- Relayer fee configuration (if using fee-based ICM messages)
- Frontend wallet connection UI library choice

---

## References

- [ERC-3009 Specification](https://eips.ethereum.org/EIPS/eip-3009)
- [Avalanche ICM Documentation](https://docs.avax.network/cross-subnet-communication)
- [ava-labs/icm-contracts Repository](https://github.com/ava-labs/icm-contracts)
- [x402 Protocol Specification](https://github.com/monetha/x402-protocol)
- [EIP-712 Typed Structured Data](https://eips.ethereum.org/EIPS/eip-712)
