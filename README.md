# Avalanche Sample Projects

> Avalancheブロックチェーンを使用したサンプルDAppプロジェクト集

このリポジトリは、Avalanche L1（旧Subnet）とInterchain Messaging (ICM)を活用したサンプルプロジェクトを含むモノレポです。

---

## 📦 プロジェクト一覧

### 🔐 [x402 Paywall DApp](./icm-x402/)

**クロスチェーン有料コンテンツ配信プラットフォーム**

- **技術**: Avalanche ICM, ERC-3009, HTTP 402 Protocol
- **状態**: Phase 4完了 (41/70タスク)
- **特徴**:
  - ガス代不要の支払い（ERC-3009）
  - クロスチェーンアクセス制御（Dispatch ⇄ Echo）
  - x402プロトコル統合

**クイックスタート**:
```bash
cd icm-x402
docker-compose up -d --build
```

📖 [詳細はこちら](./icm-x402/README.md)

---

### 🪙 [ICM ERC20](./icm-erc20/)

**Interchain Messagingを使用したERC-20トークン転送**

- **技術**: Avalanche ICM, ERC-20
- **状態**: サンプル実装
- **特徴**:
  - L1間トークン転送
  - TeleporterMessenger統合

---

### 🎨 [Simple ERC721](./simple-erc721/)

**シンプルなNFTコントラクト**

- **技術**: ERC-721, OpenZeppelin
- **状態**: 基本実装
- **特徴**:
  - NFTミント・転送
  - メタデータ管理

---

## 🚀 はじめに

### 前提条件

- **Node.js**: 20以上
- **Bun**: 1.2以上（推奨）
- **Docker**: 20以上
- **Git**: 2.30以上

### リポジトリのクローン

```bash
git clone https://github.com/your-org/avalanche-sample.git
cd avalanche-sample
```

### 環境変数の設定

モノレポ全体で共通の環境変数を使用します：

```bash
# ルートディレクトリで .env を作成
cp .env.example .env

# .env ファイルを編集
# - RPC URLの設定
# - コントラクトアドレスの設定（デプロイ後）
# - Facilitator秘密鍵の設定（テストネット用）
```

⚠️ **重要**: `.env`ファイルは**ルート直下**（`/avalanche-sample/.env`）に配置します。

### プロジェクトのセットアップ

各プロジェクトディレクトリに移動して、READMEの手順に従ってください：

```bash
# x402 Paywall DApp
cd icm-x402
cat README.md

# ICM ERC20
cd ../icm-erc20
cat README.md

# Simple ERC721
cd ../simple-erc721
cat README.md
```

---

## 📁 ディレクトリ構造

```
avalanche-sample/                  # モノレポルート
├── .env                          # 🔐 環境変数（全プロジェクト共通）
├── .env.example                  # 環境変数テンプレート
├── .gitignore                    # Git無視設定
├── README.md                     # このファイル
│
├── icm-x402/                     # x402 Paywall DApp
│   ├── contracts/                # Solidity contracts
│   ├── backend/                  # Content API (Port 4000)
│   ├── facilitator/              # Payment service (Port 5000)
│   ├── frontend/                 # Next.js UI (Port 3000)
│   ├── relayer/                  # ICM relayer
│   ├── docs/                     # Technical documentation
│   ├── docker-compose.yml        # Docker services (参照: ../.env)
│   └── README.md
│
├── icm-erc20/                    # ICM ERC20 sample
├── simple-erc721/                # Simple NFT sample
└── specification/                # Project specifications
```

**重要**: `.env`ファイルは**ルート直下**に配置されます。各プロジェクトの`docker-compose.yml`は`../.env`を参照します。

---

## 🛠️ 開発

### モノレポ全体のビルド

各プロジェクトは独立しているため、個別にビルドしてください：

```bash
# x402 Paywall DApp
cd icm-x402/contracts && bun install && bun run compile
cd ../backend && bun install && bun run build
cd ../facilitator && bun install && bun run build

# 他のプロジェクトも同様
```

### Docker Composeで起動

```bash
# x402 Paywall DApp（推奨）
cd icm-x402
docker-compose up -d --build

# ログ確認
docker-compose logs -f

# 停止
docker-compose down
```

---

## 📚 ドキュメント

各プロジェクトの詳細ドキュメントはプロジェクトディレクトリ内にあります：

### x402 Paywall DApp
- [Architecture](./icm-x402/docs/architecture.md)
- [API Specification](./icm-x402/docs/api-specification.md)
- [Smart Contracts](./icm-x402/docs/smart-contracts.md)
- [Deployment Guide](./icm-x402/docs/deployment.md)
- [Development Guide](./icm-x402/docs/development.md)

---

## 🤝 貢献

貢献を歓迎します！詳細は各プロジェクトのCONTRIBUTING.mdを参照してください。

---

## 📄 ライセンス

このリポジトリのすべてのプロジェクトは [MIT License](./LICENSE) の下で公開されています。

---

## 🔗 リンク

- [Avalanche Documentation](https://docs.avax.network/)
- [Avalanche ICM](https://docs.avax.network/cross-chain)
- [Avalanche Testnet Faucet](https://faucet.avax.network/)

---

<p align="center">
  Made with ❤️ for the Avalanche ecosystem
</p>
