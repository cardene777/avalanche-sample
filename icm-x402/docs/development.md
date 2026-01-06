# Development Guide

**x402 Paywall DApp - 開発ガイド**

---

## 目次

1. [開発環境のセットアップ](#開発環境のセットアップ)
2. [ローカル開発サーバーの起動](#ローカル開発サーバーの起動)
3. [コーディング規約](#コーディング規約)
4. [テスト](#テスト)
5. [デバッグ](#デバッグ)
6. [貢献ガイドライン](#貢献ガイドライン)

---

## 開発環境のセットアップ

### 前提条件

- **Node.js**: 20以上
- **Bun**: 1.2以上
- **Git**: 2.30以上
- **VSCode** (推奨): 拡張機能あり

### 1-1. リポジトリのクローン

```bash
git clone https://github.com/your-org/icm-x402-paywall.git
cd icm-x402-paywall
```

### 1-2. 依存関係のインストール

```bash
# Contracts
cd contracts
bun install

# Backend
cd ../backend
bun install

# Facilitator
cd ../facilitator
bun install

# Frontend (Phase 5以降)
cd ../frontend
bun install

# Relayer (Phase 7以降)
cd ../relayer
bun install
```

### 1-3. 環境変数の設定

```bash
# ルートディレクトリ
cp .env.example .env

# 各サービス
cp backend/.env.example backend/.env
cp facilitator/.env.example facilitator/.env
```

`.env`ファイルを編集してテストネットのRPC URLとアドレスを設定します。

### 1-4. VSCode拡張機能（推奨）

`.vscode/extensions.json`を作成：

```json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "juanblanco.solidity",
    "ms-vscode.vscode-typescript-next"
  ]
}
```

---

## ローカル開発サーバーの起動

### スマートコントラクト

#### ローカルHardhatネットワーク

```bash
cd contracts

# Hardhatノードを起動（別ターミナル）
bun hardhat node

# コントラクトをlocalhostにデプロイ
bun hardhat run scripts/deploy-all.ts --network localhost
```

#### Testnetにデプロイ

```bash
# Dispatch Testnet
bun hardhat run scripts/deploy-token.ts --network dispatch

# Echo Testnet
bun hardhat run scripts/deploy-content-access-manager.ts --network echo
```

### Backend

```bash
cd backend

# 開発サーバー起動（ホットリロード）
bun run dev

# または
bun run start  # 本番モード
```

サーバーは `http://localhost:4000` で起動します。

### Facilitator

```bash
cd facilitator

# 開発サーバー起動
bun run dev
```

サーバーは `http://localhost:5000` で起動します。

### Frontend (Phase 5以降)

```bash
cd frontend

# Next.js開発サーバー起動
bun run dev
```

サーバーは `http://localhost:3000` で起動します。

### すべてのサービスを同時起動

```bash
# プロジェクトルートで
docker-compose up
```

---

## コーディング規約

### TypeScript

#### ファイル命名
- **kebab-case**: `echo-chain.ts`, `payment-helper.ts`
- **PascalCase（クラス/コンポーネント）**: `AccessChecker.tsx`

#### 命名規則

```typescript
// インターフェース: PascalCase
interface Content {
  id: string;
  title: string;
}

// 型エイリアス: PascalCase
type ContentAccessStatus = {
  hasAccess: boolean;
};

// 関数: camelCase
function checkAccess(buyer: string): boolean {
  // ...
}

// 定数: UPPER_SNAKE_CASE
const MAX_RETRIES = 3;
const API_BASE_URL = "http://localhost:4000";

// クラス: PascalCase
class EchoChainClient {
  // プライベート変数: camelCase with private
  private provider: ethers.JsonRpcProvider;

  // パブリックメソッド: camelCase
  async hasAccess(buyer: string, contentId: string): Promise<boolean> {
    // ...
  }
}
```

#### コメント

```typescript
/**
 * EIP-712署名データを生成します
 * @param from 送信者アドレス
 * @param to 受信者アドレス
 * @param value 転送額
 * @returns EIP-712 Typed Data
 */
function generateTypedData(
  from: string,
  to: string,
  value: bigint
): TypedData {
  // 実装...
}
```

日本語コメントも推奨：

```typescript
// ユーザーがアクセス権を持っているか確認
const hasAccess = await echoClient.hasAccess(buyer, contentId);

// アクセス権がない場合は402エラーを返す
if (!hasAccess) {
  return res.status(402).json({ /* ... */ });
}
```

### Solidity

#### 命名規則

```solidity
// コントラクト: PascalCase
contract ERC3009PaymentToken {
    // 状態変数（public）: camelCase
    bytes32 public DOMAIN_SEPARATOR;

    // 定数: UPPER_SNAKE_CASE
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = keccak256(...);

    // マッピング: camelCase
    mapping(address => mapping(bytes32 => bool)) public authorizationState;

    // 関数: camelCase
    function transferWithAuthorization(...) external {
        // ...
    }

    // イベント: PascalCase
    event PaymentSettled(address indexed buyer, bytes32 indexed contentId);
}
```

#### NatSpecコメント

```solidity
/// @title ERC-3009 Payment Token
/// @notice ガス代不要の支払いトークン
/// @dev EIP-712署名を使用
contract ERC3009PaymentToken {
    /// @notice 署名に基づいてトークンを転送
    /// @param from 送信者
    /// @param to 受信者
    /// @param value 転送額
    /// @return success 成功したかどうか
    function transferWithAuthorization(...) external returns (bool success) {
        // ...
    }
}
```

### ESLint/Prettier

`.eslintrc.js`:
```javascript
module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier'
  ],
  rules: {
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    'no-console': ['warn', { allow: ['warn', 'error'] }]
  }
};
```

`.prettierrc`:
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": false,
  "printWidth": 100,
  "tabWidth": 2
}
```

フォーマット実行：
```bash
bun run lint        # Lint
bun run format      # Prettier
```

---

## テスト

### スマートコントラクト

```bash
cd contracts

# すべてのテスト実行
bun hardhat test

# 特定のテストのみ
bun hardhat test test/ERC3009PaymentToken.test.ts

# カバレッジレポート
bun hardhat coverage
```

#### テスト例

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC3009PaymentToken", function () {
  it("正常なtransferWithAuthorizationが成功する", async function () {
    // Arrange
    const [owner, buyer, seller] = await ethers.getSigners();
    const token = await ethers.deployContract("ERC3009PaymentToken", [
      "PaymentToken",
      "PAY",
      ethers.parseEther("1000000")
    ]);

    // Act
    const typedData = { /* EIP-712 data */ };
    const signature = await buyer.signTypedData(...);
    await token.transferWithAuthorization(..., signature.v, signature.r, signature.s);

    // Assert
    const balance = await token.balanceOf(seller.address);
    expect(balance).to.equal(ethers.parseEther("10"));
  });
});
```

### Backend

```bash
cd backend

# Vitestテスト実行
bun run test

# Watch mode
bun run test:watch

# カバレッジ
bun run test:coverage
```

#### テスト例

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { AccessChecker } from '../src/services/access-checker';

describe('AccessChecker', () => {
  let accessChecker: AccessChecker;

  beforeEach(() => {
    // Setup
    accessChecker = new AccessChecker(...);
  });

  it('アクセス権がない場合は402ステータスを返す', async () => {
    // Arrange
    const buyer = "0xABC...";
    const content = { id: "premium-guide", /* ... */ };

    // Act
    const result = await accessChecker.checkAccess(buyer, content);

    // Assert
    expect(result.hasAccess).toBe(false);
    expect(result.paymentRequired).toBeDefined();
  });
});
```

---

## デバッグ

### VSCode Debugger設定

`.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Backend",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "bun",
      "runtimeArgs": ["run", "dev"],
      "cwd": "${workspaceFolder}/backend",
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    },
    {
      "name": "Debug Facilitator",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "bun",
      "runtimeArgs": ["run", "dev"],
      "cwd": "${workspaceFolder}/facilitator",
      "console": "integratedTerminal"
    }
  ]
}
```

### ログ出力

```typescript
// 構造化ログ（推奨）
console.log(JSON.stringify({
  level: "info",
  timestamp: new Date().toISOString(),
  service: "backend",
  message: "Content access checked",
  buyer: "0xABC...",
  contentId: "premium-guide",
  hasAccess: false
}));

// 開発環境のみ
if (process.env.NODE_ENV === 'development') {
  console.log("Debug info:", data);
}
```

### Hardhatコンソール

```bash
cd contracts
bun hardhat console --network localhost
```

```javascript
> const token = await ethers.getContractAt("ERC3009PaymentToken", "0x...");
> const balance = await token.balanceOf("0xABC...");
> console.log(ethers.formatEther(balance));
```

---

## 貢献ガイドライン

### ブランチ戦略

```
main
 ├── develop
 │    ├── feature/add-payment-api
 │    ├── feature/improve-error-handling
 │    └── bugfix/fix-signature-verification
 └── hotfix/critical-security-patch
```

### コミットメッセージ

```
<type>: <subject>

<body>

<footer>
```

**Type:**
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `style`: コードフォーマット
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド設定等

**例:**
```
feat: add EIP-712 signature verification

- Implement PaymentHelper.verifySignature()
- Add unit tests for signature validation
- Update API documentation

Closes #123
```

### Pull Request

1. **Issueを作成**: 機能・バグの詳細を記載
2. **ブランチ作成**: `feature/#{issue番号}-description`
3. **実装・テスト**: コーディング規約に従う
4. **コミット**: 意味のある単位でコミット
5. **PR作成**: テンプレートに従って記載
6. **レビュー**: 最低1名の承認
7. **マージ**: Squash & Merge

#### PRテンプレート

```markdown
## 概要
このPRは何を解決しますか？

## 変更内容
- 変更1
- 変更2

## テスト
- [ ] 単体テスト追加
- [ ] 手動テスト完了
- [ ] カバレッジ90%以上

## チェックリスト
- [ ] Lint/Formatエラーなし
- [ ] ドキュメント更新済み
- [ ] 破壊的変更なし（あればCHANGELOGに記載）

## 関連Issue
Closes #123
```

### コードレビュー

#### レビュアー
- セキュリティ観点
- パフォーマンス観点
- コーディング規約準拠
- テストカバレッジ

#### レビュイー
- 自己レビュー実施
- CI通過確認
- コンフリクト解消

---

## 開発ワークフロー

### 新機能追加

```bash
# 1. Issueから開始
gh issue create --title "Add bulk access check API"

# 2. ブランチ作成
git checkout -b feature/#42-bulk-access-api

# 3. 実装
# - src/api/content.ts に新エンドポイント追加
# - test/api/content.test.ts にテスト追加

# 4. テスト実行
bun run test
bun run lint

# 5. コミット
git add .
git commit -m "feat: add bulk access check API

- Add GET /api/content/bulk-check endpoint
- Support multiple content IDs in query
- Add unit tests for bulk check

Closes #42"

# 6. プッシュ & PR作成
git push origin feature/#42-bulk-access-api
gh pr create --title "feat: add bulk access check API" --body "Closes #42"
```

### バグ修正

```bash
# 1. バグIssue作成
gh issue create --title "Bug: Signature verification fails for some valid signatures"

# 2. ブランチ作成
git checkout -b bugfix/#43-signature-verification

# 3. テスト追加（TDD）
# - test/utils/payment-helper.test.ts に失敗ケース追加

# 4. 修正実装
# - src/utils/payment-helper.ts を修正

# 5. テスト確認
bun run test

# 6. コミット & PR
git commit -m "fix: correct EIP-712 signature verification

- Fix domain separator computation
- Add test cases for edge cases

Fixes #43"
```

---

## 開発ツール

### おすすめVSCode拡張

- **Solidity**: `juanblanco.solidity`
- **ESLint**: `dbaeumer.vscode-eslint`
- **Prettier**: `esbenp.prettier-vscode`
- **GitLens**: `eamodio.gitlens`
- **Thunder Client**: API testing

### CLIツール

```bash
# Cast (Foundry)
cast call $TOKEN_ADDRESS "balanceOf(address)" $BUYER_ADDRESS

# Hardhat
bun hardhat verify --network dispatch $TOKEN_ADDRESS "PaymentToken" "PAY" "1000000000000000000000000"

# curl (API testing)
curl -H "X-BUYER-ADDRESS: 0xABC..." http://localhost:4000/api/content/premium-guide
```

---

## FAQ

### Q: Bunの代わりにnpm/yarnは使えますか？
A: はい。`package.json`を調整すれば使用可能ですが、Bunを推奨します。

### Q: ローカルでICMメッセージをテストするには？
A: Hardhat Networkでは実際のICMは動作しません。Testnetでのテストを推奨します。

### Q: デバッグでブレークポイントが効かない
A: `tsx`を使用する場合、`--inspect`フラグを追加してください。

```json
{
  "scripts": {
    "dev": "tsx --inspect watch src/index.ts"
  }
}
```

---

## 次のステップ

- [アーキテクチャ](./architecture.md) - システム全体の設計
- [API仕様](./api-specification.md) - エンドポイントリファレンス
- [デプロイ](./deployment.md) - 本番環境への展開

---

## サポート

開発に関する質問:
- **GitHub Discussions**: https://github.com/your-org/icm-x402-paywall/discussions
- **Discord**: https://discord.gg/your-server
