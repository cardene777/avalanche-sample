# テスト項目一覧

このドキュメントでは、ICTT ERC20コントラクトのテスト項目を体系的にまとめています。

## 目次

- [1. ERC20基本機能テスト](#1-erc20基本機能テスト)
- [2. ERC20TokenHomeテスト](#2-erc20tokenhomeテスト)
- [3. ERC20TokenRemoteテスト](#3-erc20tokenremoteテスト)

---

## 1. ERC20基本機能テスト

**テストファイル**: `test/ExampleERC20DecimalsTests.t.sol`

### 1.1 Decimals機能

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testDecimals` | decimals関数がデフォルト値18を返すことを確認 | decimals()が18を返す |

**詳細**:
- SampleERC20トークンのdecimals()がOpenZeppelinのデフォルト値18を返すことを検証

---

## 2. ERC20TokenHomeテスト

**テストファイル**: `test/ERC20TokenHomeTests.t.sol`

ERC20TokenHomeは送信元チェーン（Home）側のコントラクトで、トークンをロックして他のチェーンに転送する機能を提供します。

### 2.1 初期化テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testNonUpgradeableInitialization` | 非アップグレード可能なコントラクトの初期化が正しく動作することを確認 | blockchainIDが正しく設定される |
| `testDisableInitialization` | 初期化が無効化されている場合に初期化が失敗することを確認 | InvalidInitializationエラーが発生 |

### 2.2 初期化パラメータ検証テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testZeroTeleporterRegistryAddress` | TeleporterRegistryアドレスがゼロアドレスの場合に初期化が失敗することを確認 | "zero Teleporter registry address"エラー |
| `testZeroTeleporterManagerAddress` | TeleporterManagerアドレスがゼロアドレスの場合に初期化が失敗することを確認 | OwnableInvalidOwnerエラー |
| `testZeroFeeTokenAddress` | 手数料トークンアドレスがゼロアドレスの場合に初期化が失敗することを確認 | "zero token address"エラー |
| `testTokenDecimalsTooHigh` | トークンのdecimals値が上限を超える場合に初期化が失敗することを確認 | "token decimals too high"エラー |

### 2.3 トークン転送機能テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testReceiveZeroHomeTokenAmount` | スケーリングダウンによりゼロHomeトークン額を受信する場合にエラーが発生することを確認 | "zero token amount"エラー |
| `testSendScaledUpAmount` | スケールアップされたトークン額が正しく送信されることを確認 | トークン量が1e2倍されて送信される |

**詳細**:
- `testReceiveZeroHomeTokenAmount`: リモートから受信したトークン額がスケールダウンされてゼロになる場合のエラー処理を検証
- `testSendScaledUpAmount`: トークンマルチプライヤーを使用して送信額が適切にスケールアップされることを検証

### 2.4 宛先登録テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testRegisterDestinationRoundUpCollateralNeeded` | 宛先登録時に必要な担保額が正しく切り上げられることを確認 | トークンマルチプライヤーに基づいて担保額が適切に計算される |

---

## 3. ERC20TokenRemoteテスト

**テストファイル**: `test/ERC20TokenRemoteTests.t.sol`

ERC20TokenRemoteは受信先チェーン（Remote）側のコントラクトで、他のチェーンからトークンを受信してミントする機能を提供します。

### 3.1 初期化テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testNonUpgradeableInitialization` | 非アップグレード可能なコントラクトの初期化が正しく動作することを確認 | blockchainIDが正しく設定される |
| `testDisableInitialization` | 初期化が無効化されている場合に初期化が失敗することを確認 | InvalidInitializationエラーが発生 |

### 3.2 初期化パラメータ検証テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testZeroTeleporterRegistryAddress` | TeleporterRegistryアドレスがゼロアドレスの場合に初期化が失敗することを確認 | "zero Teleporter registry address"エラー |
| `testZeroTeleporterManagerAddress` | TeleporterManagerアドレスがゼロアドレスの場合に初期化が失敗することを確認 | OwnableInvalidOwnerエラー |
| `testZeroTokenHomeBlockchainID` | TokenHomeBlockchainIDがゼロの場合に初期化が失敗することを確認 | "zero token home blockchain ID"エラー |
| `testDeployToSameBlockchain` | TokenHomeと同じブロックチェーンにデプロイしようとした場合に初期化が失敗することを確認 | "cannot deploy to same blockchain as token home"エラー |
| `testZeroTokenHomeAddress` | TokenHomeアドレスがゼロアドレスの場合に初期化が失敗することを確認 | "zero token home address"エラー |

### 3.3 トークン転送機能テスト

| テスト名 | 説明 | 期待結果 |
|---------|------|---------|
| `testSendWithSeparateFeeAsset` | 別の手数料アセットを使用してトークンを送信できることを確認 | メインのトークンとは異なる手数料トークンを使用して送信が正常に行われる |
| `testDecimals` | decimals関数が正しい値を返すことを確認 | 初期化時に設定したdecimals値が正しく返される |

**詳細**:
- `testSendWithSeparateFeeAsset`: メインのトークンとは異なる手数料トークンを使用して送信が正常に行われることを検証

---

## テスト実行方法

### すべてのテストを実行

```bash
forge test
```

### 詳細な出力でテストを実行

```bash
forge test -vv
```

### 特定のテストファイルのみ実行

```bash
# ERC20TokenHomeのテストのみ
forge test --match-path test/ERC20TokenHomeTests.t.sol

# ERC20TokenRemoteのテストのみ
forge test --match-path test/ERC20TokenRemoteTests.t.sol

# ExampleERC20Decimalsのテストのみ
forge test --match-path test/ExampleERC20DecimalsTests.t.sol
```

### 特定のテスト関数のみ実行

```bash
# decimalsのテストのみ
forge test --match-test testDecimals

# 初期化関連のテストのみ
forge test --match-test testNonUpgradeableInitialization
```

### ガスレポートの表示

```bash
forge test --gas-report
```

---

## テストカバレッジ概要

| カテゴリ | テスト数 | 説明 |
|---------|---------|------|
| ERC20基本機能 | 1 | decimals機能のテスト |
| TokenHome初期化 | 6 | 初期化とパラメータ検証 |
| TokenHome転送機能 | 3 | トークン送受信とスケーリング |
| TokenRemote初期化 | 7 | 初期化とパラメータ検証 |
| TokenRemote転送機能 | 2 | トークン送信と手数料処理 |
| **合計** | **19** | **全テスト項目** |

---

## テストの設計方針

### 1. 成功パターンと失敗パターン

各機能に対して以下をテスト：
- ✅ 正常系：期待される動作が正しく行われるか
- ❌ 異常系：不正な入力やエラー条件で適切に失敗するか

### 2. エッジケースのカバレッジ

- ゼロアドレスの検証
- ゼロ値の検証
- 上限値の検証
- スケーリング処理の境界値

### 3. イベントの検証

重要な状態変更時にイベントが正しく発行されることを確認：
- トークン転送イベント（Transfer）
- 承認イベント（Approval）
- カスタムイベント（TokensSent、TokensWithdrawnなど）

---

## 参考資料

- [Foundry Book - Testing](https://book.getfoundry.sh/forge/tests)
- [Avalanche ICM Documentation](https://build.avax.network/academy/interchain-messaging)
- [OpenZeppelin Test Helpers](https://docs.openzeppelin.com/test-helpers/)
