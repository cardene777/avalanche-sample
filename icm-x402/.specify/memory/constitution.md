<!--
Sync Impact Report - Constitution v1.0.0
========================================

Version Change: (none) → 1.0.0
Initial Constitution Creation

Modified Principles:
- (none - initial creation)

Added Sections:
- Core Principles (8 principles)
- Mission & Scope
- Component Architecture
- Technology Stack & Standards
- Security & Governance
- Out of Scope (v1)
- Governance

Removed Sections:
- (none)

Templates Requiring Updates:
✅ .specify/templates/plan-template.md - Constitution Check section already references constitution file
✅ .specify/templates/spec-template.md - No direct constitution references, alignment is implicit
✅ .specify/templates/tasks-template.md - No direct constitution references, alignment is implicit

Follow-up TODOs:
- (none)
-->

# ICM x402 Paywall Dapp Constitution

## Core Principles

### I. On-chain as Source of Truth

**どのユーザーがどのコンテンツにアクセスできるか**の最終的な真実は Echo 上の `ContentAccessManager` コントラクトが保持する。Backend の DB はキャッシュ／ログ用途に留める。

**Rationale**: オフチェーンデータベースは改ざん可能であり、中央集権的な管理となる。ブロックチェーン上にアクセス権の状態を記録することで、透明性・不変性・検証可能性を確保する。

### II. HTTP フローは常に x402 準拠

**未払いの場合**:
- `HTTP 402 Payment Required` + 機械可読な `paymentRequirements` JSON を返す。

**支払い済みの場合**:
- `X-PAYMENT` / `X-PAYMENT-RESPONSE` を用いた x402 標準フローに従う。

**Rationale**: x402 は HTTP 層での支払いを標準化するプロトコルであり、クライアント実装の互換性・再利用性を高める。プロトコル準拠により、将来的に異なるクライアントやサービスとの統合が容易になる。

### III. 支払いはユーザー署名のみ（ERC-3009）

決済トークンは **ERC-20 + ERC-3009** 準拠（`transferWithAuthorization`）とする。

ユーザーはウォレットで **署名だけ**行い、**トランザクション送信（ガス負担）は Facilitator が行う**（ガスレス UX）。

**Rationale**: ガス代の支払いはユーザー体験を損なう主要因である。ERC-3009 の署名ベース転送を用いることで、ユーザーは秘密鍵で署名するのみで支払いを承認でき、実際のトランザクション送信は Facilitator が代行する。これにより、ユーザーは ETH（ガストークン）を保有する必要がなくなる。

### IV. マルチチェーン前提だが実装は Avalanche 内で完結

v1 では **Dispatch ↔ Echo の 2 L1** のみをサポート。

設計上は将来、Base や他の L1 / Subnet にも拡張可能とする。

**Rationale**: マルチチェーン対応は重要な目標だが、初期実装では複雑性を抑えるために Avalanche エコシステム内の 2 つの L1 に限定する。アーキテクチャは他のチェーンへの拡張を妨げない設計とし、将来的な拡張性を担保する。

### V. ICM / Teleporter は公式実装（icm-contracts）を使用

`TeleporterMessenger` / `ITeleporterMessenger` / `ITeleporterReceiver` は
すべて `ava-labs/icm-contracts` リポジトリのものをインポートする。

独自のメッセンジャー実装は作らない。

送信側は `TeleporterMessenger.sendCrossChainMessage` を利用し、
受信側は `ITeleporterReceiver.receiveTeleporterMessage` を実装する。

**Rationale**: Avalanche の公式実装を使用することで、セキュリティ監査済みのコード、コミュニティサポート、将来的なアップデートとの互換性を確保する。独自実装はセキュリティリスクとメンテナンスコストを増大させる。

### VI. セキュリティ > UX > 実装コスト

署名は EIP-712 / ERC-3009 仕様通りに作成・検証する。

ICM 受信コントラクトでは必ず:
- `msg.sender == teleporterMessenger`
- `originChainID` / `originSenderAddress` のチェックを行う。

**Rationale**: 支払いシステムは金銭を扱うため、セキュリティは最優先事項である。仕様準拠の署名検証とクロスチェーンメッセージの送信元検証を厳格に行うことで、不正な支払いや権限付与を防ぐ。実装の利便性よりもセキュリティを優先する。

### VII. Docker-first

Backend / Facilitator / ICM Relayer / （必要なら）フロントエンドは
**すべて Docker コンテナとして動くこと**。

ローカル開発・デモは `docker compose up` 一発で最低限のスタックが起動する。

**Rationale**: Docker コンテナ化により、環境依存の問題を排除し、開発・テスト・デプロイの一貫性を確保する。新規開発者のオンボーディングを容易にし、CI/CD パイプラインの構築を簡素化する。

### VIII. クライアントのシンプルさを重視

フロントエンドは「HTTP 402 を見たら x402 クライアントに渡す」というパターンを共通化。

特定の API に依存しない汎用フローとして実装する。

**Rationale**: クライアント実装をシンプルに保つことで、保守性と拡張性を高める。x402 プロトコルの抽象化により、異なる API やサービスに対して同じクライアントロジックを再利用できる。

---

## Mission & Scope

### Mission

Avalanche のテストネット **Dispatch / Echo** と **ICM（Teleporter）** を用いて、
- 支払いは Dispatch
- アクセス権の管理は Echo

で行う **x402 ベースのペイウォール Dapp** を構築する。

### Scope

- HTTP レイヤーの課金は **x402 プロトコル準拠**（`402 Payment Required` → `X-PAYMENT`）。
- 決済チェーン：**Dispatch L1 Testnet**
- コンテンツチェーン：**Echo L1 Testnet**
- チェーン間メッセージ：**Avalanche ICM / TeleporterMessenger（icm-contracts）** を利用。
- すべてのオフチェーンコンポーネントは **Docker コンテナで起動可能**であること。

---

## Component Architecture

### Frontend Dapp

- Next.js / React。
- ユーザーウォレット（Core / MetaMask）が Dispatch に接続している前提。
- x402 クライアント SDK による
  - 402 検知
  - 署名フロー（ERC-3009 authorization）
  - `X-PAYMENT` ヘッダ付きリトライ

### Resource Server（Backend API）

- Echo 上の `ContentAccessManager` を RPC で読み、アクセス権を判定。
- x402 Seller として
  - 1 回目：402 + paymentRequirements
  - 2 回目：X-PAYMENT 検証 → コンテンツ返却
- Avalanche SDK（TypeScript）で Echo/Dispatch を読み書きする。

### x402 Facilitator

- クライアントから受け取った
  - 支払いリクエスト（paymentRequirements）
  - ユーザー署名（ERC-3009 authorization）
- を元に Dispatch 上で
  - `ERC3009PaymentToken.transferWithAuthorization` を実行。
  - 必要に応じて `PaymentRegistry` を呼びだし。
- x402 仕様に従った `payment proof` を Resource Server / Client に返す。

### ICM Relayer

- Dispatch 上の `TeleporterMessenger` のメッセージを監視。
- Echo 上の `TeleporterMessenger` に `receiveCrossChainMessage` を中継。

### On-chain Contracts

**Dispatch L1**:
- `ERC3009PaymentToken`：USDC 互換テストトークン（ERC-20 + ERC-3009）。
- `PaymentRegistry`：
  - 支払いロジックを集約。
  - TeleporterMessenger を経由して Echo にメッセージ送信。

**Echo L1**:
- `ContentAccessManager`：
  - `ITeleporterReceiver` を実装し、支払い結果メッセージを受信。
  - `access[buyer][contentId]` を更新し Source of Truth とする。

---

## Technology Stack & Standards

### L1 / Messaging

- Avalanche テストネット：Dispatch / Echo。
- Cross-chain：**ICM Contracts / TeleporterMessenger**（`ava-labs/icm-contracts`）。

### Token Standards

- ERC-20
- **ERC-3009 (TransferWithAuthorization)** は決済トークンに必須。

### Payment Protocol

- x402 EVM スキーム（ERC-3009 ベース）を採用。

### Development Languages

- Solidity（コントラクト）
- TypeScript（Backend / Frontend）
- Node.js（Facilitator / Relayer ラッパー）

### Docker

- 各サービスは Dockerfile を持ち、`docker compose` で
  - `frontend`
  - `backend`
  - `facilitator`
  - `icm-relayer`
- をまとめて起動可能にする。

---

## Security & Governance

### Security

- テストネットとはいえ、秘密鍵や RPC URL は `.env` + Docker secret で管理。
- `PaymentRegistry` / `ContentAccessManager` の管理者はシングルシグで開始し、将来的に multi-sig に移行できる設計とする。
- TeleporterMessenger のアドレス・バージョン管理は ICM Registry / TeleporterRegistry の仕様に従う。

### Governance

- Constitution supersedes all other practices.
- Amendments require documentation, approval, and migration plan.
- All PRs and reviews must verify compliance with these principles.
- Complexity must be justified against the principles defined above.

---

## Out of Scope (v1)

以下は v1 の実装範囲外とする：

- サブスクリプション（定期課金）
- フィアット決済や KYC
- NFT / トークン化されたアクセス権
- ローカル Avalanche L1 自前起動（基本は公式テストネット接続）

---

## Governance

This constitution serves as the foundational document for the ICM x402 Paywall Dapp project. All design decisions, implementation choices, and architectural patterns must align with the principles outlined above.

### Amendment Process

1. Proposed amendments must be documented with rationale and impact analysis.
2. Version number must be incremented according to semantic versioning:
   - **MAJOR**: Backward incompatible principle removals or redefinitions.
   - **MINOR**: New principle/section added or materially expanded guidance.
   - **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements.
3. Dependent templates and documents must be updated to reflect changes.
4. A Sync Impact Report must be generated and reviewed.

### Compliance Review

- All pull requests must reference and comply with relevant constitutional principles.
- Complex implementations that deviate from principles must include explicit justification.
- Regular reviews should ensure ongoing alignment with constitutional guidance.

**Version**: 1.0.0 | **Ratified**: 2025-11-16 | **Last Amended**: 2025-11-16
