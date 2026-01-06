# Feature Specification: x402 Paywall Dapp with Avalanche ICM

**Feature Branch**: `001-x402-paywall`
**Created**: 2025-11-16
**Status**: Draft
**Input**: User description: "x402-based paywall Dapp using Avalanche ICM for cross-chain payment and access management between Dispatch and Echo L1 testnets"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Access Paywalled Content (Priority: P1)

A user visits the application and attempts to access premium content. The system checks if the user has already paid for the content and either grants access or presents a clear payment requirement.

**Why this priority**: This is the core value proposition of the paywall system. Without this, there is no MVP.

**Independent Test**: Can be fully tested by checking content access permissions and verifying that unpaid users receive payment requirements while paid users receive content.

**Acceptance Scenarios**:

1. **Given** a user has not paid for content ID "article-123", **When** they request `/api/content/article-123`, **Then** they receive HTTP 402 with payment requirements in x402 format
2. **Given** a user has already paid for content ID "article-123", **When** they request `/api/content/article-123`, **Then** they receive HTTP 200 with the content
3. **Given** a user requests non-existent content ID "invalid", **When** they request `/api/content/invalid`, **Then** they receive HTTP 404 with appropriate error message

---

### User Story 2 - Complete Gasless Payment (Priority: P2)

A user who needs to pay for content can complete the payment using only their wallet signature, without needing to hold gas tokens. The payment is processed across chains and access is automatically granted.

**Why this priority**: Gasless payment is a key differentiator and removes a major UX barrier. This completes the end-to-end payment flow.

**Independent Test**: Can be fully tested by having a user sign a payment authorization, verifying the payment completes on Dispatch chain, and confirming access is granted on Echo chain.

**Acceptance Scenarios**:

1. **Given** a user receives payment requirements for content, **When** they sign an ERC-3009 authorization and submit to the facilitator, **Then** the payment is executed on Dispatch chain without the user paying gas
2. **Given** a payment is completed on Dispatch, **When** the cross-chain message is relayed, **Then** access is granted on Echo chain within 30 seconds
3. **Given** a user submits an invalid or expired signature, **When** the facilitator attempts to process it, **Then** the payment fails with a clear error message and no funds are transferred

---

### User Story 3 - Seamless Browser Experience (Priority: P3)

A user browsing the web application can discover, pay for, and access premium content without leaving the page or understanding blockchain complexities.

**Why this priority**: Frontend integration makes the payment flow accessible to non-technical users and provides a complete user experience.

**Independent Test**: Can be fully tested by simulating a user clicking on premium content, going through the payment flow in the browser, and seeing the content appear without page reload.

**Acceptance Scenarios**:

1. **Given** a user clicks on premium content in the browser, **When** the HTTP 402 response is received, **Then** a wallet signature prompt appears automatically
2. **Given** a user completes the signature and payment, **When** the payment proof is received, **Then** the content loads automatically without manual refresh
3. **Given** a user cancels the wallet signature, **When** they dismiss the prompt, **Then** they see a friendly message explaining they can try again later

---

### User Story 4 - Easy Development Setup (Priority: P4)

A developer can set up the entire development environment including all services (frontend, backend, facilitator, relayer) with a single command.

**Why this priority**: Reduces onboarding friction and ensures consistency across development, testing, and demo environments.

**Independent Test**: Can be fully tested by running the setup command on a clean machine and verifying all services start successfully and can communicate.

**Acceptance Scenarios**:

1. **Given** a developer has Docker installed, **When** they run `docker compose up`, **Then** all services (frontend, backend, facilitator, relayer) start successfully
2. **Given** all services are running, **When** a developer makes a test API call, **Then** the services can communicate with each other and the Avalanche testnets
3. **Given** environment variables are missing, **When** the setup command runs, **Then** clear error messages indicate which variables need to be configured

---

### User Story 5 - Debug Payment State (Priority: P5)

A developer or support person can check the payment and access status across both chains to troubleshoot issues.

**Why this priority**: Debugging cross-chain systems is complex; this tooling accelerates troubleshooting and reduces support burden.

**Independent Test**: Can be fully tested by checking payment status for various buyer/content combinations and verifying the API returns accurate state from both chains.

**Acceptance Scenarios**:

1. **Given** a payment has been made but access not yet granted, **When** a developer checks `/api/debug/payment-status`, **Then** they see payment status on Dispatch and access status on Echo separately
2. **Given** all services are running, **When** a developer checks `/api/debug/health`, **Then** they see the connection status of all components (backend, facilitator, Dispatch RPC, Echo RPC, relayer)
3. **Given** the ICM relayer is stopped, **When** the health check runs, **Then** it clearly indicates the relayer is unavailable

---

### Edge Cases

- What happens when the ICM relayer is offline and messages cannot be delivered?
- How does the system handle a user attempting to pay for already-purchased content?
- What happens if the signature is valid but the user has insufficient token balance?
- How does the system respond if Dispatch or Echo RPC is temporarily unavailable?
- What happens if a payment is made but the cross-chain message fails to relay?
- How are duplicate payments prevented if a user retries quickly?
- What happens if the TeleporterMessenger contract address changes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an API endpoint that returns content only to users who have paid for it
- **FR-002**: System MUST return HTTP 402 with x402-compliant payment requirements when content is unpaid
- **FR-003**: System MUST verify payment status by checking on-chain access control state on Echo chain
- **FR-004**: System MUST accept user payment authorizations signed with ERC-3009 standard
- **FR-005**: System MUST execute payments on Dispatch chain without requiring users to hold gas tokens
- **FR-006**: System MUST send cross-chain messages from Dispatch to Echo using Avalanche ICM
- **FR-007**: System MUST update access control on Echo chain when payment messages are received
- **FR-008**: System MUST validate cross-chain message sender, origin chain, and message authenticity
- **FR-009**: System MUST provide x402-compliant payment proof after successful payment
- **FR-010**: System MUST accept X-PAYMENT header and verify payment proof before granting access
- **FR-011**: System MUST relay ICM messages between Dispatch and Echo chains automatically
- **FR-012**: System MUST provide debug endpoints for checking payment and access state across both chains
- **FR-013**: System MUST provide health check endpoint showing status of all system components
- **FR-014**: System MUST run all services (frontend, backend, facilitator, relayer) in Docker containers
- **FR-015**: System MUST support deployment via Docker Compose with environment-based configuration

### Key Entities

- **Content**: Represents premium digital content (articles, videos, data, etc.) that requires payment to access. Each content item has a unique identifier and a price.
- **Payment**: Records a payment transaction on Dispatch chain, including buyer address, content ID, amount, and transaction hash.
- **Access**: Represents permission to view specific content, stored on Echo chain. Links a buyer address to a content ID.
- **Buyer**: A user identified by their wallet address who may purchase and access content.
- **Payment Authorization**: An ERC-3009 signature authorizing token transfer, including parameters like from, to, amount, validity period, and nonce.
- **Cross-Chain Message**: An ICM message sent from Dispatch to Echo containing payment information to grant access.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the payment flow (from seeing HTTP 402 to accessing content) in under 60 seconds under normal network conditions
- **SC-002**: System successfully processes and grants access for 95% of valid payment attempts
- **SC-003**: Cross-chain access grants occur within 30 seconds of payment completion on Dispatch chain
- **SC-004**: Users complete payment without holding or spending gas tokens (100% gasless for end users)
- **SC-005**: Development environment starts successfully with a single command on machines meeting minimum requirements (Docker installed)
- **SC-006**: Debug endpoints accurately reflect on-chain state with less than 5 second lag
- **SC-007**: System handles at least 10 concurrent payment requests without errors
- **SC-008**: Payment requirements are returned in x402-compliant format that can be parsed by standard x402 clients

## Assumptions

1. **Testnet Availability**: Avalanche Dispatch and Echo L1 testnets are publicly accessible and operational
2. **TeleporterMessenger Deployment**: TeleporterMessenger contracts are already deployed on both Dispatch and Echo chains at known addresses
3. **User Wallet**: Users have a compatible wallet (Core or MetaMask) installed and configured for Dispatch chain
4. **Token Availability**: Users have access to test tokens (ERC-3009 compatible) on Dispatch chain for making payments
5. **RPC Access**: Application has reliable access to RPC endpoints for both Dispatch and Echo chains
6. **ICM Registry**: TeleporterRegistry contracts exist on both chains for version management (if applicable)
7. **Development Environment**: Developers have Docker and Docker Compose installed for local setup
8. **Network Latency**: Cross-chain message relay time is primarily dependent on ICM relayer performance and network conditions
9. **EIP-712 Support**: User wallets support EIP-712 typed data signing for ERC-3009 authorizations
10. **Content Storage**: Actual content storage mechanism (database, IPFS, etc.) is independent of the paywall logic
