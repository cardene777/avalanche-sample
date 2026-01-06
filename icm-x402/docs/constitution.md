### 1. ミッション & スコープ

* **ミッション**

  * Avalanche のテストネット **Dispatch / Echo** と **ICM（Teleporter）** を用いて、

    * 支払いは Dispatch
    * アクセス権の管理は Echo
  * で行う **x402 ベースのペイウォール Dapp** を構築する。
* **スコープ**

  * HTTP レイヤーの課金は **x402 プロトコル準拠**（`402 Payment Required` → `X-PAYMENT`）。
  * 決済チェーン：**Dispatch L1 Testnet**
  * コンテンツチェーン：**Echo L1 Testnet**
  * チェーン間メッセージ：**Avalanche ICM / TeleporterMessenger（icm-contracts）** を利用。
  * すべてのオフチェーンコンポーネントは **Docker コンテナで起動可能**であること。

---

### 2. プロダクト原則

1. **On-chain as Source of Truth**

   * 「どのユーザーがどのコンテンツにアクセスできるか」の最終的な真実は
     Echo 上の `ContentAccessManager` コントラクトが保持する。
   * Backend の DB はキャッシュ／ログ用途に留める。

2. **HTTP フローは常に x402 準拠**

   * 未払いの場合：

     * `HTTP 402 Payment Required` + 機械可読な `paymentRequirements` JSON を返す。
   * 支払い済みの場合：

     * `X-PAYMENT` / `X-PAYMENT-RESPONSE` を用いた x402 標準フローに従う。

3. **支払いはユーザー署名のみ（ERC-3009）**

   * 決済トークンは **ERC-20 + ERC-3009** 準拠（`transferWithAuthorization`）とする。
   * ユーザーはウォレットで **署名だけ**行い、
     **トランザクション送信（ガス負担）は Facilitator が行う**（ガスレス UX）。

4. **マルチチェーン前提だが実装は Avalanche 内で完結**

   * v1 では **Dispatch ↔ Echo の 2 L1** のみをサポート。
   * 設計上は将来、Base や他の L1 / Subnet にも拡張可能とする。

5. **ICM / Teleporter は公式実装（icm-contracts）を使用**

   * `TeleporterMessenger` / `ITeleporterMessenger` / `ITeleporterReceiver` は
     すべて `ava-labs/icm-contracts` リポジトリのものをインポートする。
   * 独自のメッセンジャー実装は作らない。
   * 送信側は `TeleporterMessenger.sendCrossChainMessage` を利用し、
     受信側は `ITeleporterReceiver.receiveTeleporterMessage` を実装する。

6. **セキュリティ > UX > 実装コスト**

   * 署名は EIP-712 / ERC-3009 仕様通りに作成・検証する。
   * ICM 受信コントラクトでは必ず

     * `msg.sender == teleporterMessenger`
     * `originChainID` / `originSenderAddress` のチェックを行う。

7. **Docker-first**

   * Backend / Facilitator / ICM Relayer / （必要なら）フロントエンドは
     **すべて Docker コンテナとして動くこと**。
   * ローカル開発・デモは `docker compose up` 一発で最低限のスタックが起動する。

8. **クライアントのシンプルさを重視**

   * フロントエンドは「HTTP 402 を見たら x402 クライアントに渡す」というパターンを共通化。
   * 特定の API に依存しない汎用フローとして実装する。

---

### 3. コンポーネント境界

**Frontend Dapp**

* Next.js / React。
* ユーザーウォレット（Core / MetaMask）が Dispatch に接続している前提。
* x402 クライアント SDK による

  * 402 検知
  * 署名フロー（ERC-3009 authorization）
  * `X-PAYMENT` ヘッダ付きリトライ

**Resource Server（Backend API）**

* Echo 上の `ContentAccessManager` を RPC で読み、アクセス権を判定。
* x402 Seller として

  * 1 回目：402 + paymentRequirements
  * 2 回目：X-PAYMENT 検証 → コンテンツ返却
* Avalanche SDK（TypeScript）で Echo/Dispatch を読み書きする。

**x402 Facilitator**

* クライアントから受け取った

  * 支払いリクエスト（paymentRequirements）
  * ユーザー署名（ERC-3009 authorization）
* を元に Dispatch 上で

  * `ERC3009PaymentToken.transferWithAuthorization` を実行。
  * 必要に応じて `PaymentRegistry` を呼びだし。
* x402 仕様に従った `payment proof` を Resource Server / Client に返す。

**ICM Relayer**

* Dispatch 上の `TeleporterMessenger` のメッセージを監視。
* Echo 上の `TeleporterMessenger` に `receiveCrossChainMessage` を中継。

**On-chain Contracts**

* Dispatch L1:

  * `ERC3009PaymentToken`：USDC 互換テストトークン（ERC-20 + ERC-3009）。
  * `PaymentRegistry`：

    * 支払いロジックを集約。
    * TeleporterMessenger を経由して Echo にメッセージ送信。
* Echo L1:

  * `ContentAccessManager`：

    * `ITeleporterReceiver` を実装し、支払い結果メッセージを受信。
    * `access[buyer][contentId]` を更新し Source of Truth とする。

---

### 4. 技術スタック & 標準

* **L1 / Messaging**

  * Avalanche テストネット：Dispatch / Echo。
  * Cross-chain：**ICM Contracts / TeleporterMessenger**（`ava-labs/icm-contracts`）。

* **トークン標準**

  * ERC-20
  * **ERC-3009 (TransferWithAuthorization)** は決済トークンに必須。

* **支払いプロトコル**

  * x402 EVM スキーム（ERC-3009 ベース）を採用。

* **開発言語**

  * Solidity（コントラクト）
  * TypeScript（Backend / Frontend）
  * Node.js（Facilitator / Relayer ラッパー）

* **Docker**

  * 各サービスは Dockerfile を持ち、`docker compose` で

    * `frontend`
    * `backend`
    * `facilitator`
    * `icm-relayer`
  * をまとめて起動可能にする。

---

### 5. セキュリティ / ガバナンス

* テストネットとはいえ、秘密鍵や RPC URL は `.env` + Docker secret で管理。
* `PaymentRegistry` / `ContentAccessManager` の管理者はシングルシグで開始し、将来的に multi-sig に移行できる設計とする。
* TeleporterMessenger のアドレス・バージョン管理は ICM Registry / TeleporterRegistry の仕様に従う。

---

### 6. v1 でやらないこと（非スコープ）

* サブスクリプション（定期課金）
* フィアット決済や KYC
* NFT / トークン化されたアクセス権
* ローカル Avalanche L1 自前起動（基本は公式テストネット接続）