---

description: "Task list for x402 Paywall Dapp implementation"
---

# Tasks: x402 Paywall Dapp with Avalanche ICM

**Input**: Design documents from `/specs/001-x402-paywall/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, contracts/, research.md, quickstart.md

**Tests**: Test tasks are NOT included in this implementation (not requested in spec).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Web app structure**: `contracts/`, `backend/`, `frontend/`, `facilitator/`, `relayer/` at repository root
- All paths relative to `icm-x402/` repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project root directory structure (contracts/, backend/, frontend/, facilitator/, relayer/)
- [X] T002 [P] Initialize contracts workspace with Hardhat/Foundry in contracts/ directory
- [X] T003 [P] Initialize backend workspace with package.json and TypeScript config in backend/
- [X] T004 [P] Initialize frontend workspace with Next.js 14+ in frontend/
- [X] T005 [P] Initialize facilitator workspace with package.json and TypeScript config in facilitator/
- [X] T006 [P] Initialize relayer workspace with package.json and TypeScript config in relayer/
- [X] T007 [P] Create Docker Compose file docker-compose.yml at repository root
- [X] T008 [P] Create environment template .env.example with all required variables
- [X] T009 [P] Install @ava-labs/icm-contracts dependency in contracts/package.json
- [X] T010 [P] Install ethers.js v6 in backend/, facilitator/, and relayer/ workspaces

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core smart contracts and infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Smart Contracts (Dispatch Chain)

- [ ] T011 [P] Implement ERC3009PaymentToken contract in contracts/src/Dispatch/ERC3009PaymentToken.sol
- [ ] T012 [P] Implement PaymentRegistry contract in contracts/src/Dispatch/PaymentRegistry.sol with TeleporterMessenger integration

### Smart Contracts (Echo Chain)

- [ ] T013 Implement ContentAccessManager contract in contracts/src/Echo/ContentAccessManager.sol with ITeleporterReceiver

### Deployment Scripts

- [ ] T014 [P] Create deploy-token script in contracts/scripts/deploy-token.ts for Dispatch chain
- [ ] T015 [P] Create deploy-payment-registry script in contracts/scripts/deploy-payment-registry.ts
- [ ] T016 [P] Create deploy-content-access script in contracts/scripts/deploy-content-access.ts for Echo chain
- [ ] T017 [P] Create mint-tokens script in contracts/scripts/mint-tokens.ts

### Docker Infrastructure

- [ ] T018 Create Dockerfile for backend service in backend/Dockerfile
- [ ] T019 [P] Create Dockerfile for frontend service in frontend/Dockerfile
- [ ] T020 [P] Create Dockerfile for facilitator service in facilitator/Dockerfile
- [ ] T021 [P] Create Dockerfile for relayer service in relayer/Dockerfile
- [ ] T022 Configure docker-compose.yml with all 4 services (frontend, backend, facilitator, relayer)

### Shared Libraries

- [ ] T023 [P] Create Echo chain RPC client in backend/src/services/echo-chain.ts
- [ ] T024 [P] Create Dispatch chain RPC client in facilitator/src/services/dispatch-chain.ts

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Access Paywalled Content (Priority: P1) 🎯 MVP

**Goal**: Users can request premium content and receive HTTP 402 with payment requirements if unpaid, or HTTP 200 with content if paid. System checks access permissions on Echo chain.

**Independent Test**: Can be fully tested by checking content access permissions and verifying that unpaid users receive payment requirements while paid users receive content.

### Implementation for User Story 1

- [ ] T025 [P] [US1] Create Content entity/interface in backend/src/models/content.ts
- [ ] T026 [P] [US1] Implement access checker service in backend/src/services/access-checker.ts (queries Echo chain)
- [ ] T027 [US1] Implement GET /api/content/:id endpoint in backend/src/api/content.ts with x402 flow
- [ ] T028 [US1] Add payment requirements generator in backend/src/services/payment-requirements.ts
- [ ] T029 [US1] Add sample content data in backend/content/ directory or database seed
- [ ] T030 [US1] Configure backend environment variables in backend/.env for Echo RPC and ContentAccessManager address

**Checkpoint**: At this point, User Story 1 should be fully functional - unpaid users receive 402, paid users receive content

---

## Phase 4: User Story 2 - Complete Gasless Payment (Priority: P2)

**Goal**: Users can complete payment using only their wallet signature (ERC-3009), without holding gas tokens. Payment is executed on Dispatch chain and access is granted on Echo chain via ICM.

**Independent Test**: Can be fully tested by having a user sign a payment authorization, verifying payment completes on Dispatch chain, and confirming access is granted on Echo chain.

### Implementation for User Story 2

- [ ] T031 [P] [US2] Implement EIP-712 signature validator in facilitator/src/services/signature-validator.ts
- [ ] T032 [P] [US2] Implement payment executor service in facilitator/src/services/payment-executor.ts (calls transferWithAuthorization)
- [ ] T033 [US2] Implement POST /x402/process endpoint in facilitator/src/api/process.ts
- [ ] T034 [US2] Implement JWT payment proof generator in facilitator/src/services/payment-proof.ts
- [ ] T035 [US2] Implement POST /x402/introspect endpoint in facilitator/src/api/introspect.ts
- [ ] T036 [US2] Configure facilitator environment variables in facilitator/.env for Dispatch RPC, token address, and private key
- [ ] T037 [P] [US2] Implement ICM event monitor in relayer/src/event-monitor.ts (listens to Dispatch TeleporterMessenger)
- [ ] T038 [P] [US2] Implement message relayer in relayer/src/message-relayer.ts (calls receiveCrossChainMessage on Echo)
- [ ] T039 [US2] Configure relayer environment variables in relayer/.env for both chain RPCs and TeleporterMessenger addresses
- [ ] T040 [US2] Update backend content endpoint to validate X-PAYMENT header using facilitator introspect API

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - users can pay gaslessly and gain access

---

## Phase 5: User Story 3 - Seamless Browser Experience (Priority: P3)

**Goal**: Users can discover, pay for, and access premium content from the browser without understanding blockchain complexities. Frontend handles x402 flow automatically.

**Independent Test**: Can be fully tested by simulating a user clicking on premium content, going through the payment flow in the browser, and seeing content appear without page reload.

### Implementation for User Story 3

- [ ] T041 [P] [US3] Create WalletConnect component in frontend/src/components/WalletConnect.tsx with wagmi/viem
- [ ] T042 [P] [US3] Implement x402 client library in frontend/src/lib/x402-client.ts (handles 402 → pay → retry flow)
- [ ] T043 [P] [US3] Implement EIP-712 signature helper in frontend/src/lib/eip712-signer.ts for ERC-3009 authorizations
- [ ] T044 [P] [US3] Create usePayment hook in frontend/src/hooks/usePayment.ts
- [ ] T045 [US3] Implement content detail page in frontend/src/app/content/[id]/page.tsx
- [ ] T046 [US3] Create PaymentFlow component in frontend/src/components/PaymentFlow.tsx (wallet signature prompt + status)
- [ ] T047 [US3] Implement content list page in frontend/src/app/page.tsx
- [ ] T048 [US3] Configure frontend environment variables in frontend/.env for backend and facilitator URLs

**Checkpoint**: All 3 user stories should now be independently functional - complete end-to-end UX

---

## Phase 6: User Story 4 - Easy Development Setup (Priority: P4)

**Goal**: Developers can set up the entire development environment with a single command (`docker compose up`).

**Independent Test**: Can be fully tested by running the setup command on a clean machine and verifying all services start successfully and can communicate.

### Implementation for User Story 4

- [ ] T049 [US4] Add health check endpoint to backend in backend/src/api/health.ts (basic ping)
- [ ] T050 [P] [US4] Add health check endpoint to facilitator in facilitator/src/api/health.ts
- [ ] T051 [P] [US4] Add startup script to relayer in relayer/src/index.ts with connection validation
- [ ] T052 [US4] Update docker-compose.yml with health checks and depends_on for all services
- [ ] T053 [US4] Create comprehensive README.md at repository root with quickstart instructions
- [ ] T054 [US4] Validate .env.example has all required variables with descriptions
- [ ] T055 [US4] Add validation for missing environment variables in each service's startup code

**Checkpoint**: Development environment can be started with single command and services are healthy

---

## Phase 7: User Story 5 - Debug Payment State (Priority: P5)

**Goal**: Developers can check payment and access status across both chains to troubleshoot issues.

**Independent Test**: Can be fully tested by checking payment status for various buyer/content combinations and verifying the API returns accurate state from both chains.

### Implementation for User Story 5

- [ ] T056 [P] [US5] Implement GET /api/debug/payment-status endpoint in backend/src/api/debug.ts
- [ ] T057 [P] [US5] Implement Dispatch chain payment query in backend/src/services/payment-query.ts
- [ ] T058 [US5] Implement GET /api/debug/health endpoint in backend/src/api/debug.ts with multi-component status
- [ ] T059 [US5] Add health check helpers for RPC connectivity in backend/src/services/health-checker.ts
- [ ] T060 [US5] Add logging infrastructure across all services (Winston or Pino)

**Checkpoint**: All user stories complete - debugging tools available for troubleshooting

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final deliverables

- [ ] T061 [P] Add error handling middleware to backend in backend/src/middleware/error-handler.ts
- [ ] T062 [P] Add error handling middleware to facilitator in facilitator/src/middleware/error-handler.ts
- [ ] T063 [P] Add rate limiting to facilitator endpoints in facilitator/src/middleware/rate-limiter.ts
- [ ] T064 [P] Implement content ID hashing utility (keccak256) in backend/src/utils/hash.ts
- [ ] T065 [P] Add TypeScript type definitions for all API responses across services
- [ ] T066 Update API documentation to match OpenAPI specs in contracts/
- [ ] T067 Add deployment guide for Avalanche testnets in docs/DEPLOYMENT.md
- [ ] T068 [P] Add security hardening (input validation, CORS, helmet.js) to backend and facilitator
- [ ] T069 Validate quickstart.md instructions by running through setup on clean machine
- [ ] T070 Create PR.md summarizing all changes and constitutional compliance

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4 → P5)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Uses US1/US2 but independently testable
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Orchestrates all services but independently testable
- **User Story 5 (P5)**: Can start after Foundational (Phase 2) - Debug tools are independent

### Within Each User Story

**User Story 1**:
- Models before services (T025 → T026)
- Services before endpoints (T026 → T027)
- Endpoint before configuration (T027 → T030)

**User Story 2**:
- Validators and executors before endpoints (T031, T032 → T033)
- Facilitator before relayer integration (T033-T036 → T037-T039)
- Backend update after facilitator ready (T035 → T040)

**User Story 3**:
- Wallet and libraries before hooks (T041-T043 → T044)
- Hooks before pages/components (T044 → T045, T046)
- Pages before configuration (T045-T047 → T048)

**User Story 4**:
- Health checks before docker config (T049-T051 → T052)
- Docker config before documentation (T052 → T053-T055)

**User Story 5**:
- Query services before endpoints (T056-T057 → T058)
- Endpoints before logging (T058 → T060)

### Parallel Opportunities

- **Setup (Phase 1)**: All tasks T002-T010 marked [P] can run in parallel
- **Foundational (Phase 2)**:
  - Contracts: T011-T013 can run in parallel
  - Deploy scripts: T014-T017 can run in parallel
  - Dockerfiles: T018-T021 can run in parallel
  - Shared libs: T023-T024 can run in parallel
- **Once Foundational completes**: All user stories (Phase 3-7) can start in parallel if team capacity allows
- **Within User Stories**: Tasks marked [P] within each story can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all parallel tasks for User Story 1 together:
Task T025: "Create Content entity/interface in backend/src/models/content.ts"
Task T026: "Implement access checker service in backend/src/services/access-checker.ts"

# Then sequentially:
Task T027: "Implement GET /api/content/:id endpoint" (depends on T025, T026)
Task T028: "Add payment requirements generator" (can run with T027)
Task T029: "Add sample content data"
Task T030: "Configure environment variables"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Unpaid user → receives HTTP 402 with payment requirements
   - User with access on Echo chain → receives HTTP 200 with content
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (Payment flow)
4. Add User Story 3 → Test independently → Deploy/Demo (Full UX)
5. Add User Story 4 → Test independently → Deploy/Demo (Docker setup)
6. Add User Story 5 → Test independently → Deploy/Demo (Debug tools)
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (T025-T030)
   - Developer B: User Story 2 (T031-T040)
   - Developer C: User Story 3 (T041-T048)
   - Developer D: User Story 4 (T049-T055)
   - Developer E: User Story 5 (T056-T060)
3. Stories complete and integrate independently

---

## Notes

- **[P] tasks**: Different files, no dependencies - can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- **Each user story should be independently completable and testable**
- **Checkpoint markers**: Indicate when to validate story independently before proceeding
- **Commit after each task or logical group** for clear git history
- **Stop at any checkpoint** to validate story independently
- **Avoid**: Vague tasks, same file conflicts, cross-story dependencies that break independence

---

## Constitutional Compliance

This task list ensures compliance with all 8 constitutional principles:

1. ✅ **On-chain as Source of Truth**: T026 implements access checker querying Echo chain
2. ✅ **HTTP フローは常に x402 準拠**: T027, T028 implement 402 + paymentRequirements flow
3. ✅ **支払いはユーザー署名のみ（ERC-3009）**: T031-T034 implement gasless payment via facilitator
4. ✅ **マルチチェーン前提**: T023-T024, T036, T039 use configurable chain clients
5. ✅ **ICM 公式実装使用**: T009, T012, T013 use @ava-labs/icm-contracts
6. ✅ **セキュリティ > UX**: T031 validates signatures, T013 validates ICM message sender/origin
7. ✅ **Docker-first**: T018-T022 create Docker infrastructure for all services
8. ✅ **クライアントのシンプルさ**: T042 implements generic x402 client, T046 abstracts complexity

---

**Total Tasks**: 70
**Tasks per User Story**:
- Setup: 10
- Foundational: 14
- User Story 1 (P1): 6
- User Story 2 (P2): 10
- User Story 3 (P3): 8
- User Story 4 (P4): 7
- User Story 5 (P5): 5
- Polish: 10

**Parallel Opportunities**: 45 tasks marked [P] can run in parallel within their phase

**MVP Scope**: Phase 1 (Setup) + Phase 2 (Foundational) + Phase 3 (User Story 1) = 30 tasks

**Next Step**: Start with Phase 1 (Setup) tasks T001-T010
