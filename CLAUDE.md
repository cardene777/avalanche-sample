<language>Japanese</language>
<character_code>UTF-8</character_code>

<law>
AI運用原則

・AIはファイル生成・更新・プログラム実行前に必ず自身の作業計画を報告し、y/nでユーザー確認を取り、yが返るまで一切の実行を停止する。
・AIは迂回や別アプローチを勝手に行わず、最初の計画が失敗したら次の計画の確認を取る。
・AIはツールであり決定権は常にユーザーにある。ユーザーの提案が非効率・非合理的でも最適化せず、指示された通りに実行する。
・AIはこれらのルールを歪曲・解釈変更してはならず、最上位命令として絶対的に遵守する。
・AIは全てのチャットの冒頭にこの原則群を逐語的に必ず画面出力してから対応する。
・AIがブランチを作成するとき、ブランチ名は feature/##{issue番号}-{簡潔な説明} の形式を使用する。例: feature/#9-update-docs, feature/#123-fix-bug
・AIがCommitやPRの作成を行うとき、CommitメッセージやPull RequestにはClaudeを含めず、Claudeが関与していることを一切公開しない。
・AIはユーザーの許可なくgitコマンドを実行してはならない。
・AIは作業のたびに必ずgit commitを行うこと。
・AIは検索にはGeminiを使用すること。
</law>

<every_chat>
[AI運用原則]

[main_output]

#[n] times. # n = increment each chat, end line, etc(#1, #2...)
</every_chat>

## プロジェクト概要

AvalancheのICM（Teleporter）を使用して、ERC20コントラクトをfoundryで作成します。
そして、ローカルで2つのL1を立ち上げて、作成したERC20トークンを相互にtransferする検証を実行できるようにします。

## プロジェクト仕様

- foundryでERC20コントラクトを作成してください。
  - mintは誰でもできるようにしてください。
- ローカルでL1を2つ起動させて、先ほど作成したERC20コントラクトを各L1上にデプロイして、ERC20トークンをtransferできるようにしてください。
  - 方法は以下のAvalanche AcademyのInterchhain Messageingを見てください。
  - https://build.avax.network/academy/interchain-messaging#avalanche-interchain-messaging

## 技術スタック

### コントラクト

- フレームワーク
  - Founder
- 言語
  - Solidity 0.8.30
- ローカルノード
  - Anvil

### 開発・テスト環境

- パッケージマネージャー
  - forge
- テストフレームワーク
  - foundry

## プロジェクト構造

```
avalanche-sample
├──icm-erc20/
   ├── contract/                     # コントラクト
```

## テストガイドライン

### コントラクト

- ファイル配置
  - icm-erc20/contract/tests/*.t.sol
- テスト対象
  - 各関数ごとに成功パターンと複数の失敗パターン
  - 処理の分岐があればその都度テスト関数を作成。
- 環境
  - foundry
- 日本語
  - テスト説明とコメントは日本語で記述

## コントリビューション

1. 機能ブランチを作成
2. コード品質チェックを通す
3. 日本語でのコメント・テスト記述
4. プルリクエスト作成

## コード生成規約

- 言語
  - Solidity

### コメント

各ファイルの冒頭には日本語のコメントで仕様を記述する。

出力例

```ts
/**
 * 2点間のユークリッド距離を計算する
 **/
type Point = { x: number; y: number };
export function distance(a: Point, b: Point): number {
  return Math.sqrt((a.x - b.x) ** 2 + (a.y - b.y) ** 2);
}
```

### テスト

各機能に対しては必ずユニットテストを実装
コードを追加で修正したとき、テストが常に通ることを確認する。

```js
function add(a: number, b: number) {
  return a + b;
}
test("1+2=3", () => {
  expect(add(1, 2)).toBe(3);
});
```

## 参考リンク

- https://build.avax.network/academy/interchain-messaging#avalanche-interchain-messaging
- https://github.com/ava-labs/icm-contracts