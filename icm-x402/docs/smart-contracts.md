# Smart Contracts Specification

**x402 Paywall DApp - Smart Contracts**

---

## Overview

このシステムは3つのスマートコントラクトで構成されています：

| Contract | Chain | Purpose |
|----------|-------|---------|
| ERC3009PaymentToken | Dispatch L1 | ガス代不要の支払いトークン |
| PaymentRegistry | Dispatch L1 | 支払い記録とICM送信 |
| ContentAccessManager | Echo L1 | アクセス制御とICM受信 |

---

## 1. ERC3009PaymentToken (Dispatch Chain)

### 概要
ERC-20トークンにERC-3009の`transferWithAuthorization`機能を追加したコントラクト。

### 継承
```solidity
contract ERC3009PaymentToken is ERC20, Ownable
```

### 状態変数

```solidity
// EIP-712ドメインセパレーター
bytes32 public DOMAIN_SEPARATOR;

// transferWithAuthorizationのType Hash
bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");

// Nonce使用状態: authorizer => nonce => used
mapping(address => mapping(bytes32 => bool)) public authorizationState;
```

### コンストラクタ

```solidity
constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
) ERC20(name, symbol) Ownable(msg.sender)
```

**パラメータ**:
- `name`: トークン名（例: "PaymentToken"）
- `symbol`: トークンシンボル（例: "PAY"）
- `initialSupply`: 初期供給量（18 decimals）

### 主要関数

#### transferWithAuthorization

```solidity
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
) external
```

**説明**: ユーザーの署名に基づいてガス代不要でトークンを転送します。

**パラメータ**:
- `from`: トークン送信元（署名者）
- `to`: トークン受信先（コンテンツプロバイダー）
- `value`: 転送額
- `validAfter`: この時刻以降に有効
- `validBefore`: この時刻まで有効
- `nonce`: 一意のnonce（リプレイ攻撃防止）
- `v, r, s`: EIP-712署名コンポーネント

**検証内容**:
1. タイムスタンプが有効範囲内か
2. Nonceが未使用か
3. 署名が有効か（EIP-712）
4. 残高が十分か

**イベント**:
```solidity
emit Transfer(from, to, value);
```

**リバート条件**:
- `Authorization not yet valid`: validAfter以前
- `Authorization expired`: validBefore以降
- `Authorization already used`: nonce重複
- `Invalid signature`: 署名検証失敗
- `Insufficient balance`: 残高不足

---

## 2. PaymentRegistry (Dispatch Chain)

### 概要
支払い記録を保存し、Echoチェーンへアクセス許可メッセージを送信するコントラクト。

### 継承
```solidity
contract PaymentRegistry is Ownable
```

### 状態変数

```solidity
// Teleporter Messenger（ICM）
ITeleporterMessenger public immutable teleporterMessenger;

// EchoチェーンのChain ID
bytes32 public immutable echoChainID;

// EchoチェーンのContentAccessManagerアドレス
address public immutable contentAccessManagerOnEcho;

// 支払い記録: buyer => contentId => PaymentRecord
mapping(address => mapping(bytes32 => PaymentRecord)) public payments;

struct PaymentRecord {
    address buyer;
    bytes32 contentId;
    uint256 amount;
    bytes32 paymentTxHash;
    uint256 settledAt;
}
```

### コンストラクタ

```solidity
constructor(
    address _teleporterMessenger,
    bytes32 _echoChainID,
    address _contentAccessManagerOnEcho
) Ownable(msg.sender)
```

**パラメータ**:
- `_teleporterMessenger`: TeleporterMessengerのアドレス
- `_echoChainID`: EchoチェーンのID
- `_contentAccessManagerOnEcho`: Echo上のContentAccessManagerアドレス

### 主要関数

#### settlePayment

```solidity
function settlePayment(
    address buyer,
    bytes32 contentId,
    uint256 amount,
    bytes32 paymentTxHash
) external onlyOwner
```

**説明**: 支払いを記録し、Echoチェーンへアクセス許可メッセージを送信します。

**パラメータ**:
- `buyer`: 購入者アドレス
- `contentId`: コンテンツID（bytes32ハッシュ）
- `amount`: 支払い額
- `paymentTxHash`: 支払いトランザクションのハッシュ

**処理フロー**:
1. 支払い記録を保存
2. ICMメッセージペイロードをエンコード
3. `teleporterMessenger.sendCrossChainMessage()`を呼び出し

**ICMメッセージ構造**:
```solidity
abi.encode(buyer, contentId, amount, paymentTxHash)
```

**イベント**:
```solidity
event PaymentSettled(
    address indexed buyer,
    bytes32 indexed contentId,
    uint256 amount,
    bytes32 paymentTxHash
);

event AccessGrantMessageSent(
    bytes32 indexed messageID,
    address indexed buyer,
    bytes32 indexed contentId
);
```

**アクセス制御**: `onlyOwner`（Facilitatorのみ）

---

## 3. ContentAccessManager (Echo Chain)

### 概要
ICMメッセージを受信してアクセス権を付与するコントラクト。**唯一の真実の情報源**。

### 継承
```solidity
contract ContentAccessManager is ITeleporterReceiver, Ownable
```

### 状態変数

```solidity
// Teleporter Messenger（ICM）
ITeleporterMessenger public immutable teleporterMessenger;

// DispatchチェーンのChain ID
bytes32 public immutable dispatchChainID;

// DispatchチェーンのPaymentRegistryアドレス
address public immutable paymentRegistryAddress;

// アクセス権: buyer => contentId => hasAccess
mapping(address => mapping(bytes32 => bool)) public access;

// アクセス許可の詳細: buyer => contentId => AccessGrant
mapping(address => mapping(bytes32 => AccessGrant)) public accessGrants;

struct AccessGrant {
    address buyer;
    bytes32 contentId;
    uint256 amount;
    bytes32 paymentTxHash;
    uint256 grantedAt;
}
```

### コンストラクタ

```solidity
constructor(
    address _teleporterMessenger,
    bytes32 _dispatchChainID,
    address _paymentRegistryAddress
) Ownable(msg.sender)
```

**パラメータ**:
- `_teleporterMessenger`: TeleporterMessengerのアドレス
- `_dispatchChainID`: DispatchチェーンのID
- `_paymentRegistryAddress`: Dispatch上のPaymentRegistryアドレス

### 主要関数

#### receiveTeleporterMessage

```solidity
function receiveTeleporterMessage(
    bytes32 originChainID,
    address originSenderAddress,
    bytes calldata message
) external override
```

**説明**: ICMメッセージを受信し、アクセス権を付与します。

**セキュリティ検証**:
```solidity
require(msg.sender == address(teleporterMessenger), "Invalid messenger");
require(originChainID == dispatchChainID, "Invalid origin chain");
require(originSenderAddress == paymentRegistryAddress, "Invalid sender");
```

**処理フロー**:
1. メッセージをデコード: `(buyer, contentId, amount, paymentTxHash)`
2. アクセス権を付与: `access[buyer][contentId] = true`
3. アクセス許可詳細を保存

**イベント**:
```solidity
event AccessGranted(
    address indexed buyer,
    bytes32 indexed contentId,
    uint256 amount,
    bytes32 paymentTxHash,
    uint256 timestamp
);
```

#### hasAccess

```solidity
function hasAccess(
    address buyer,
    bytes32 contentId
) external view returns (bool)
```

**説明**: 購入者が特定のコンテンツへのアクセス権を持っているか確認します。

**戻り値**: アクセス権の有無（bool）

#### getAccessGrant

```solidity
function getAccessGrant(
    address buyer,
    bytes32 contentId
) external view returns (AccessGrant memory)
```

**説明**: アクセス許可の詳細を取得します。

**戻り値**: AccessGrant構造体

---

## セキュリティ分析

### ERC3009PaymentToken

#### ✅ 保護されている攻撃
- **リプレイ攻撃**: Nonce管理で防止
- **署名偽造**: EIP-712厳密検証
- **期限切れ署名**: validAfter/validBefore検証
- **整数オーバーフロー**: Solidity 0.8.20の自動チェック

#### ⚠️ 考慮事項
- **Front-running**: facilit atorが先にトランザクションを実行する可能性（ただし、facilitatorは信頼された主体）
- **Nonce管理**: ユーザーはnonceを一意に保つ必要がある

### PaymentRegistry

#### ✅ 保護されている攻撃
- **不正決済**: onlyOwner制限
- **二重決済**: PaymentRecord上書き可能（最新を記録）
- **ICMメッセージ改ざん**: Teleporter Messengerが保証

#### ⚠️ 考慮事項
- **Owner権限集中**: Facilitatorが唯一の決済実行者
- **ICM配信失敗**: リトライ機構が必要（Relayerで対応）

### ContentAccessManager

#### ✅ 保護されている攻撃
- **不正アクセス許可**: 3重検証（messenger, chainID, sender）
- **メッセージリプレイ**: TeleporterMessengerが防止
- **ChainID偽装**: immutableで固定

#### ⚠️ 考慮事項
- **アクセス権取り消し**: 現状は永続的（将来的に有効期限機能を追加可能）

---

## ガス最適化

### 使用されているテクニック
1. **immutable変数**: teleporterMessenger, chainID, addressesを不変化
2. **mapping**: O(1)アクセス
3. **bytes32**: stringよりガス効率的
4. **構造体パッキング**: 256-bitアライメント
5. **短いリバート文字列**: ガス削減

### 推定ガスコスト

| 操作 | 推定ガス |
|------|----------|
| transferWithAuthorization | ~65,000 |
| settlePayment | ~150,000 (ICM送信含む) |
| receiveTeleporterMessage | ~80,000 |
| hasAccess (view) | 0 (読み取りのみ) |

---

## デプロイ順序

```
1. Dispatch Chain
   ├── ERC3009PaymentToken
   └── PaymentRegistry
       └── constructor(teleporterMessenger, echoChainID, ?)
           ※ ContentAccessManagerアドレスは後で設定

2. Echo Chain
   └── ContentAccessManager
       └── constructor(teleporterMessenger, dispatchChainID, paymentRegistryAddress)

3. Dispatch Chain (更新)
   └── PaymentRegistry.setContentAccessManager(contentAccessManagerAddress)
       ※ または再デプロイ
```

**注意**: PaymentRegistryとContentAccessManagerは互いのアドレスを知る必要があるため、デプロイ順序が重要です。

---

## テストシナリオ

### ERC3009PaymentToken

```javascript
describe("ERC3009PaymentToken", () => {
  it("正常な transferWithAuthorization", async () => {
    // 署名生成 → 実行 → 残高確認
  });

  it("期限切れ署名はリバート", async () => {
    // validBefore < now → リバート
  });

  it("Nonce重複はリバート", async () => {
    // 同じnonceで2回実行 → 2回目リバート
  });

  it("無効な署名はリバート", async () => {
    // 間違った秘密鍵で署名 → リバート
  });
});
```

### PaymentRegistry

```javascript
describe("PaymentRegistry", () => {
  it("Owner以外は決済不可", async () => {
    // 非OwnerでsettlePayment → リバート
  });

  it("ICMメッセージ送信成功", async () => {
    // settlePayment → AccessGrantMessageSentイベント確認
  });
});
```

### ContentAccessManager

```javascript
describe("ContentAccessManager", () => {
  it("不正なメッセンジャーからのメッセージを拒否", async () => {
    // 別アドレスから呼び出し → リバート
  });

  it("正常なICMメッセージでアクセス付与", async () => {
    // receiveTeleporterMessage → hasAccess = true
  });

  it("不正なChainIDを拒否", async () => {
    // 別ChainIDから → リバート
  });
});
```

---

## アップグレード戦略

現在の実装は**非アップグレード可能**です。将来的にアップグレード可能にする場合：

### オプション1: Transparent Proxy Pattern
```solidity
contract ContentAccessManagerV2 is ContentAccessManager {
    // 新機能: アクセス権の有効期限
    mapping(address => mapping(bytes32 => uint256)) public accessExpiry;
}
```

### オプション2: Diamond Pattern
複数のファセットに機能を分割。

### 推奨
初期リリースは非アップグレード可能で十分。必要に応じてマイグレーションスクリプトで新バージョンにデータ移行。

---

## 監査チェックリスト

- [ ] EIP-712実装の正確性
- [ ] Nonce管理のリプレイ攻撃耐性
- [ ] ICMメッセージの検証ロジック
- [ ] アクセス制御（onlyOwner）
- [ ] 整数オーバーフロー/アンダーフロー
- [ ] リエントランシー攻撃（現在該当なし）
- [ ] ガス最適化
- [ ] イベント発行の完全性

---

## 参考資料

- [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
- [ERC-3009 Specification](https://eips.ethereum.org/EIPS/eip-3009)
- [EIP-712 Typed Data](https://eips.ethereum.org/EIPS/eip-712)
- [Avalanche ICM Documentation](https://docs.avax.network/cross-chain)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/)
