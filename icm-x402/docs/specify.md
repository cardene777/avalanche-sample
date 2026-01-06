
### F-01: Paywalled Content API（Echo 上コンテンツのペイウォール）

**WHAT**

* `GET /api/content/:id` を提供する。
* リクエストに紐づく `buyerAddress` に応じて：

  * Echo 上の `ContentAccessManager.access(buyer, contentId)` が `true` なら：

    * `200 OK` + 隠しコンテンツ JSON/HTML を返す。
  * `false` なら：

    * `402 Payment Required` + x402 `paymentRequirements` JSON を返す。

**WHY**

* シンプルかつ x402 仕様に忠実な「有料コンテンツ取得 API」が必要。
* Echo を Source of Truth にすることで、将来的に別クライアントからも再利用可能。

**HOW（ヒント）**

* `buyerAddress` は

  * クエリパラメータ
  * `X-Wallet-Address` ヘッダ
  * 認証トークン
    のいずれかで渡される想定（Speckit で決めておく）。
* Echo RPC を Avalanche SDK から叩いて `access` を読み取る。

---

### F-02: 402 レスポンス & x402 paymentRequirements 生成

**WHAT**

* `GET /api/content/:id`（1 回目）で 402 を返す際、以下の構造の JSON を返却する：

```jsonc
{
  "x402Version": 1,
  "paymentRequirements": [
    {
      "network": "avalanche-dispatch-testnet",
      "tokenAddress": "0xERC3009PaymentTokenOnDispatch",
      "amount": "0.5",
      "recipient": "0xMerchantOnDispatch",
      "reference": "content:<id>"
    }
  ],
  "facilitator": "https://facilitator.dapp.local/x402"
}
```

**WHY**

* x402 クライアント SDK がこの情報を元に

  * どのチェーンで
  * どのトークンを
  * いくら
  * 誰に
  * どのリソースのために
    支払うかを判定するため。

**HOW（ヒント）**

* `reference` には `content:<id>` を含めることで、
  PaymentRegistry / ContentAccessManager が `contentId` を一意に特定できるようにする。

---

### F-03: ERC-3009 決済フロー（ユーザー署名 → Facilitator → Dispatch）

**WHAT**

* ユーザーはウォレットで **ERC-3009 authorization** に署名するだけでよい。
* フロントエンドは：

  * 402 レスポンスを受け取り x402 クライアントを起動
  * ユーザー署名（authorization）を取得
  * それを **Facilitator** に送信
* Facilitator は：

  * Dispatch 上の `ERC3009PaymentToken.transferWithAuthorization(...)` を実行して

    * `buyer → merchant` への送金を完了させる。
  * 決済トランザクションハッシュ / 各種情報を `payment proof` として返す。

**WHY**

* ユーザーにガスを持たせず、「署名だけで支払いが完了する」体験を実現したい。
* x402 の公式 EVM スキームと整合的にするため。

**HOW（ヒント）**

* ERC-3009 の `transferWithAuthorization` のパラメータ（`from`, `to`, `value`, `validAfter`, `validBefore`, `nonce` など）を
  EIP-712 ドメインと合わせてフロントで構築し、ウォレットに署名させる。
* Facilitator は署名検証と `transferWithAuthorization` 呼び出しを行う。

---

### F-04: PaymentRegistry（Dispatch）による ICM メッセージ送信

**WHAT**

* Dispatch 上に `PaymentRegistry` コントラクトをデプロイし、

  * 決済完了の記録
  * TeleporterMessenger を使った Echo へのメッセージ送信
* 主な責務：

  * `settlePayment(address buyer, bytes32 contentId, uint256 amount, bytes authorizationData)` のような関数を提供。
  * `paid[buyer][contentId] = true` を記録。
  * `TeleporterMessenger.sendCrossChainMessage` を呼んで Echo の `ContentAccessManager` 宛にメッセージ送信。

**WHY**

* 「誰がどのコンテンツを支払ったか」の情報をチェーン間で同期するため。
* 将来、他アプリも同じ決済情報を利用できるようにするため。

**HOW（ヒント）**

* コントラクトでは `ava-labs/icm-contracts` の
  `ITeleporterMessenger` を import し、コンストラクタで TeleporterMessenger のアドレスを受け取る。
* メッセージ payload には `buyer`, `contentId`, `amount`, `paymentTxHash` などを `abi.encode` して含める。

---

### F-05: ContentAccessManager（Echo, ITeleporterReceiver 実装）

**WHAT**

* Echo 上に `ContentAccessManager` をデプロイし、

  * ICM メッセージを受信して `access[buyer][contentId] = true` を立てる。
* `ITeleporterReceiver.receiveTeleporterMessage` を実装する。

**WHY**

* Echo を「アクセス権管理チェーン」として機能させるため。
* Backend が Echo だけを見れば「支払い済みかどうか」を判断できるようにするため。

**HOW（ヒント）**

* import 先は `icm-contracts/contracts/teleporter/interfaces/ITeleporterReceiver.sol` を使用（パスは remapping で調整）。
* `receiveTeleporterMessage` 内で：

  * `require(msg.sender == address(teleporterMessenger))`
  * `require(originChainID == DISPATCH_CHAIN_ID)`
  * `require(originSenderAddress == paymentRegistryOnDispatch)`
    をチェック。
* `message` を `abi.decode` して `(buyer, contentId, amount, paymentTxHash)` を取得し、`access` を更新。

---

### F-06: x402 HTTP フロー（Resource Server）

**WHAT**

* Resource Server は x402 Seller として以下の 2 段階フローを実装する：

  1. `GET /api/content/:id`（1回目）

     * Echo の `access` を確認し、未購入なら 402 + JSON。
  2. `GET /api/content/:id`（2回目）

     * `X-PAYMENT` ヘッダを受け取り、Facilitator の `/introspect` エンドポイントに渡して検証。
     * OK かつ Echo の `access` が true なら 200 + コンテンツ。

**WHY**

* HTTP レイヤーから見たときに、x402 の流れが完全に再現されていることを保証するため。
* x402 対応クライアントであれば、この API をそのまま利用できるようにするため。

**HOW（ヒント）**

* `x402-express` などのミドルウェアライブラリを前提にする（自作でも可）。
* `X-PAYMENT` の中身は Facilitator が発行する署名付きトークン（payment proof）とし、
  Resource Server はそれを「そのまま Facilitator に投げるだけ」にしてロジックを薄く保つ。

---

### F-07: Frontend x402 クライアント統合

**WHAT**

* フロントエンドは以下の共通フローを実装：

  1. `fetch('/api/content/:id')` を実行。
  2. `status === 402` の場合：

     * `paymentRequirements` を受け取り x402 クライアントに渡す。
     * ウォレットで ERC-3009 署名。
     * Facilitator 経由で決済 → `X-PAYMENT` ヘッダ付きで同じ URL を再リクエスト。
  3. `status === 200` になったらコンテンツを表示。

**WHY**

* 任意の API エンドポイントを最小限の変更で「有料 API」にできるようにしたい。
* x402 の「402 → pay → retry」の UX を明確に実装するため。

**HOW（ヒント）**

* `x402-fetch` のような wrapper を使って実装するか、
  独自に `fetchWithX402` ヘルパーを実装する。

---

### F-08: ICM Relayer コンテナ

**WHAT**

* Dispatch ↔ Echo 間の ICM メッセージ中継を行う Relayer を Docker コンテナとして用意する。
* コンテナは以下を行う：

  * Dispatch の TeleporterMessenger イベントを購読。
  * Echo の TeleporterMessenger に対して `receiveCrossChainMessage` を送信。

**WHY**

* Cross-chain メッセージが届かないと、支払い情報が Echo に反映されずコンテンツが解放されないため。
* ローカル／テスト環境を簡単に再現できるようにするため。

**HOW（ヒント）**

* Avalanche 公式の Teleporter CLI / ICM サンプルを利用し、
  それをラップする Node.js スクリプトをコンテナから起動する構成でもよい。

---

### F-09: Docker / Docker Compose による起動

**WHAT**

* プロジェクトルートに `docker-compose.yml` を用意し、以下のサービスを定義：

  * `frontend`：Next.js アプリ
  * `backend`：Resource Server
  * `facilitator`：x402 Facilitator
  * `icm-relayer`：ICM Relayer
* `docker compose up` で一通りのスタックが立ち上がり、
  `.env` に設定した Avalanche RPC / TeleporterMessenger アドレスを使って実際に Dispatch / Echo に接続する。

**WHY**

* チーム内・外で「再現性の高い」環境を素早く共有するため。
* Speckit ベースで CI / E2E テストを走らせる土台を Docker 上に作るため。

**HOW（ヒント）**

* それぞれのサービスは個別の Dockerfile を持つ。
* 共通の `.env`（または `.env.backend`, `.env.frontend` など）を `env_file` として読ませる。
* 将来的にテスト用ローカル L1（anvil 等）に切り替えられるよう、RPC URL はすべて環境変数から取得。

---

### F-10: デバッグ / ステータス API

**WHAT**

* 以下のようなデバッグ用エンドポイントを Backend に用意する：

  * `GET /api/debug/payment-status?buyer=&contentId=`
    → Dispatch `PaymentRegistry.paid` と Echo `ContentAccessManager.access` を両方返す。
  * `GET /api/debug/health`
    → Backend, Facilitator, Dispatch RPC, Echo RPC, ICM Relayer の疎通状況を JSON で返す。

**WHY**

* ICM の遅延や Relayer の停止、ERC-3009 署名ミスなど、
  トラブルシュートが難しい箇所を可視化するため。
* Speckit 上でテスト観点を定義しやすくするため（例：Given/When/Then）。