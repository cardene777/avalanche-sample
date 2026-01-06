# Quickstart: x402 Paywall Dapp with Avalanche ICM

**Feature**: 001-x402-paywall
**Phase**: 1 (Design & Contracts)
**Date**: 2025-11-16

## Overview

This quickstart guide will help you set up and run the x402 paywall system locally using Docker Compose, deploy contracts to Avalanche testnet, and test the complete payment flow.

**Time to complete**: 20-30 minutes

---

## Prerequisites

### Required

- **Docker & Docker Compose**: Install from [docker.com](https://www.docker.com/)
- **Node.js (LTS)**: For contract deployment and testing
- **Wallet (Core or MetaMask)**: Configured for Avalanche Dispatch testnet
- **Test tokens**: AVAX for gas, ERC-3009 test tokens for payments

### Optional

- **Foundry or Hardhat**: For contract development/testing

---

## Step 1: Clone and Configure

### 1.1 Clone Repository

```bash
git clone <repository-url>
cd icm-x402
```

### 1.2 Create Environment File

Create `.env` file in project root:

```bash
# Avalanche Testnet RPCs
DISPATCH_RPC_URL=https://subnets.avax.network/dispatch/testnet/rpc
ECHO_RPC_URL=https://subnets.avax.network/echo/testnet/rpc

# TeleporterMessenger Contract Addresses (deployed on testnets)
DISPATCH_TELEPORTER_ADDRESS=0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf
ECHO_TELEPORTER_ADDRESS=0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf

# Smart Contract Addresses (deploy in Step 2)
ERC3009_TOKEN_ADDRESS=<to-be-deployed>
PAYMENT_REGISTRY_ADDRESS=<to-be-deployed>
CONTENT_ACCESS_MANAGER_ADDRESS=<to-be-deployed>

# Facilitator Configuration
FACILITATOR_PRIVATE_KEY=<your-private-key>
MERCHANT_ADDRESS=<recipient-address-for-payments>

# Frontend Configuration
NEXT_PUBLIC_BACKEND_URL=http://localhost:4000
NEXT_PUBLIC_FACILITATOR_URL=http://localhost:5000
```

**Security Note**: Never commit `.env` with real private keys. Use `.env.example` template.

---

## Step 2: Deploy Smart Contracts

### 2.1 Install Dependencies

```bash
cd contracts
npm install
# or
forge install
```

### 2.2 Deploy ERC3009PaymentToken (Dispatch Chain)

```bash
# Using Hardhat
npx hardhat run scripts/deploy-token.ts --network dispatch-testnet

# Using Foundry
forge script script/DeployToken.s.sol:DeployToken --rpc-url $DISPATCH_RPC_URL --broadcast
```

**Save the deployed token address** to `.env` as `ERC3009_TOKEN_ADDRESS`.

### 2.3 Deploy PaymentRegistry (Dispatch Chain)

```bash
# Pass TeleporterMessenger and ContentAccessManager addresses
npx hardhat run scripts/deploy-payment-registry.ts --network dispatch-testnet
```

**Save the deployed registry address** to `.env` as `PAYMENT_REGISTRY_ADDRESS`.

### 2.4 Deploy ContentAccessManager (Echo Chain)

```bash
# Pass TeleporterMessenger and PaymentRegistry addresses
npx hardhat run scripts/deploy-content-access.ts --network echo-testnet
```

**Save the deployed contract address** to `.env` as `CONTENT_ACCESS_MANAGER_ADDRESS`.

### 2.5 Mint Test Tokens

```bash
# Mint tokens to your test wallet
npx hardhat run scripts/mint-tokens.ts --network dispatch-testnet
```

---

## Step 3: Start Services with Docker Compose

### 3.1 Build and Start All Services

```bash
docker compose up --build
```

This starts 4 services:

| Service | Port | Description |
|---------|------|-------------|
| `frontend` | 3000 | Next.js web application |
| `backend` | 4000 | Resource Server (Content API) |
| `facilitator` | 5000 | x402 Facilitator (Payment processor) |
| `icm-relayer` | N/A | ICM message relayer (background) |

### 3.2 Verify Services are Running

Check health endpoint:

```bash
curl http://localhost:4000/api/debug/health
```

Expected response:

```json
{
  "status": "healthy",
  "components": {
    "backend": {"status": "healthy"},
    "facilitator": {"status": "healthy"},
    "dispatchRpc": {"status": "healthy", "blockNumber": 1234567},
    "echoRpc": {"status": "healthy", "blockNumber": 2345678},
    "icmRelayer": {"status": "healthy"}
  }
}
```

---

## Step 4: Add Sample Content

### 4.1 Create Content via Backend API (or manually)

```bash
# Option 1: Use admin API to create content
curl -X POST http://localhost:4000/api/admin/content \
  -H "Content-Type: application/json" \
  -d '{
    "id": "article-123",
    "title": "Advanced Avalanche ICM Patterns",
    "description": "Deep dive into cross-chain messaging",
    "price": "0.5",
    "contentType": "article",
    "contentData": {
      "format": "markdown",
      "body": "# Advanced Patterns\n\nThis article explores..."
    }
  }'

# Option 2: Manually add to backend/content/ directory
```

---

## Step 5: Test Payment Flow

### 5.1 Open Frontend

Navigate to [http://localhost:3000](http://localhost:3000) in your browser.

### 5.2 Connect Wallet

1. Click "Connect Wallet"
2. Select Core or MetaMask
3. Ensure wallet is connected to **Dispatch testnet**
4. Ensure wallet has test tokens (ERC-3009)

### 5.3 Request Content (First Request - Unpaid)

1. Navigate to content page (e.g., `/content/article-123`)
2. Browser makes `GET /api/content/article-123`
3. Backend checks Echo chain → no access
4. Backend returns **HTTP 402 Payment Required**

Frontend receives:

```json
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
  "facilitator": "http://localhost:5000/x402"
}
```

### 5.4 Sign Payment Authorization

1. x402 client prompts wallet for signature (EIP-712)
2. User reviews and approves signature (no gas cost)
3. Frontend submits authorization to facilitator:

```bash
POST http://localhost:5000/x402/process
{
  "paymentRequirements": {...},
  "authorization": {
    "from": "0x...",
    "to": "0x...",
    "value": "500000",
    "validAfter": 0,
    "validBefore": 1700000000,
    "nonce": "0x...",
    "v": 28,
    "r": "0x...",
    "s": "0x..."
  }
}
```

### 5.5 Facilitator Processes Payment

Facilitator:
1. Validates signature
2. Calls `ERC3009PaymentToken.transferWithAuthorization` on Dispatch
3. Calls `PaymentRegistry.settlePayment` → sends ICM message to Echo
4. Returns payment proof JWT

Frontend receives:

```json
{
  "success": true,
  "paymentProof": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "transactionHash": "0x...",
  "buyer": "0x...",
  "contentId": "article-123",
  "amount": "0.5",
  "timestamp": 1700000000
}
```

### 5.6 Wait for Cross-Chain Sync (~30 seconds)

Monitor payment status:

```bash
curl "http://localhost:4000/api/debug/payment-status?buyer=0x...&contentId=article-123"
```

Expected progression:

1. **Immediately after payment**:
   ```json
   {
     "dispatchChain": {"paid": true, "settled": true},
     "echoChain": {"accessGranted": false},
     "syncStatus": {"inSync": false, "warning": "..."}
   }
   ```

2. **After ICM relay (~30s)**:
   ```json
   {
     "dispatchChain": {"paid": true, "settled": true},
     "echoChain": {"accessGranted": true},
     "syncStatus": {"inSync": true, "latency": 30}
   }
   ```

### 5.7 Request Content (Second Request - Paid)

Frontend automatically retries with `X-PAYMENT` header:

```bash
GET /api/content/article-123
X-PAYMENT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Backend:
1. Validates payment proof JWT
2. Queries Echo chain → `access[buyer][contentId] == true`
3. Returns **HTTP 200 OK** with content

```json
{
  "id": "article-123",
  "title": "Advanced Avalanche ICM Patterns",
  "description": "Deep dive into cross-chain messaging",
  "contentType": "article",
  "contentData": {
    "format": "markdown",
    "body": "# Advanced Patterns\n\nThis article explores..."
  }
}
```

---

## Step 6: Verify On-Chain State

### 6.1 Check Dispatch Chain (Payment)

```bash
# Using ethers.js or cast
cast call $PAYMENT_REGISTRY_ADDRESS \
  "payments(address,bytes32)(address,bytes32,uint256,bytes32,uint256,bool)" \
  $BUYER_ADDRESS \
  $(cast keccak "article-123") \
  --rpc-url $DISPATCH_RPC_URL
```

### 6.2 Check Echo Chain (Access)

```bash
cast call $CONTENT_ACCESS_MANAGER_ADDRESS \
  "access(address,bytes32)(bool)" \
  $BUYER_ADDRESS \
  $(cast keccak "article-123") \
  --rpc-url $ECHO_RPC_URL
```

Expected: `true`

---

## Troubleshooting

### Issue: Services fail to start

**Solution**: Check Docker logs:
```bash
docker compose logs -f
```

Ensure all environment variables are set in `.env`.

### Issue: Payment successful but access not granted

**Symptoms**: Dispatch chain shows payment, Echo chain shows no access after 60+ seconds.

**Likely cause**: ICM relayer is not running or stuck.

**Solution**:
1. Check relayer logs: `docker compose logs icm-relayer`
2. Restart relayer: `docker compose restart icm-relayer`
3. Verify relayer has access to both RPC URLs

### Issue: Signature validation fails

**Symptoms**: Facilitator returns "Invalid signature" error.

**Solution**:
- Ensure `chainId` in EIP-712 domain matches Dispatch testnet
- Verify `verifyingContract` matches `ERC3009_TOKEN_ADDRESS`
- Check `nonce` is unique and not previously used
- Ensure `validBefore` timestamp has not passed

### Issue: Insufficient balance error

**Symptoms**: Transaction reverts with "Insufficient balance".

**Solution**:
- Mint more test tokens to buyer address
- Verify buyer has approved sufficient amount (not needed for ERC-3009, but check token balance)

### Issue: RPC connection timeout

**Symptoms**: Health check shows `dispatchRpc` or `echoRpc` as unhealthy.

**Solution**:
- Verify RPC URLs are correct and accessible
- Check network connectivity
- Try alternative RPC endpoints

---

## Next Steps

### Development

- **Add more content**: Create additional content items with different prices
- **Customize frontend**: Modify UI components in `frontend/src/`
- **Extend contracts**: Add features like refunds, subscriptions, or access expiration

### Testing

- **Run contract tests**: `npm test` or `forge test`
- **Run integration tests**: `npm run test:integration`
- **Test edge cases**: Expired signatures, insufficient balance, relayer downtime

### Production Deployment

- **Mainnet deployment**: Follow similar steps with mainnet RPC URLs
- **Security hardening**: Use secure key management (AWS KMS, HashiCorp Vault)
- **Monitoring**: Set up alerts for relayer health, RPC availability, payment failures
- **Rate limiting**: Add rate limits to facilitator endpoints
- **Multi-sig**: Upgrade PaymentRegistry/ContentAccessManager to multi-sig governance

---

## Common Commands

### Start Services
```bash
docker compose up
```

### Stop Services
```bash
docker compose down
```

### View Logs
```bash
docker compose logs -f <service-name>
# e.g., docker compose logs -f facilitator
```

### Restart Single Service
```bash
docker compose restart <service-name>
```

### Rebuild Service
```bash
docker compose up --build <service-name>
```

### Deploy Contracts
```bash
cd contracts
npm run deploy:dispatch  # Deploy to Dispatch
npm run deploy:echo      # Deploy to Echo
```

### Mint Test Tokens
```bash
npm run mint -- --to 0x<address> --amount 100
```

---

## Resources

- **Specification**: [spec.md](./spec.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **API Contracts**: [contracts/](./contracts/)
- **Avalanche ICM Docs**: https://docs.avax.network/cross-subnet-communication
- **ERC-3009 Spec**: https://eips.ethereum.org/EIPS/eip-3009
- **x402 Protocol**: https://github.com/monetha/x402-protocol

---

## Support

For issues and questions:

1. Check health endpoint: `GET /api/debug/health`
2. Check payment status: `GET /api/debug/payment-status?buyer=...&contentId=...`
3. Review service logs: `docker compose logs -f`
4. Verify contract deployments on testnet explorer
5. Open an issue in the repository

---

**Last Updated**: 2025-11-16
