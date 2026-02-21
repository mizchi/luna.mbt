# Sol Onboarding

新規メンバー向けに、最短で開発参加するための手順を固定します。

## 前提

- Node.js 24+
- `pnpm`
- `moon` / `sol` コマンド

## 1. 初期セットアップ

このリポジトリを clone した状態で実行します。

```bash
just bootstrap
```

`just bootstrap` が内部で実行する内容:

- `pnpm install`
- `moon update`
- `moon install`

## 2. ゴールデンパス（最短フロー）

```bash
sol new myapp --user yourname
cd myapp
pnpm install
pnpm dev
```

確認ポイント:

- `http://localhost:7777/` が表示される
- `http://localhost:7777/api/health` が JSON を返す

## 3. 最初の変更でやること

1. 1ページ追加
2. 1 API 追加
3. ドキュメント 1 箇所更新

## 4. PR 前チェック

```bash
just verify
```

`just verify` は次を順に実行します。

- `check`
- `test`
- `test-docs`
- `build`

## 5. CI との整合

GitHub Actions の `check` workflow も同じ `just bootstrap` と `just verify` を実行します。
