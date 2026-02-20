# Sol Quickstart

`sol` を最短で起動して、`dev -> build -> serve` の一連を確認する手順です。

## 前提

- Node.js 24+
- `pnpm`
- `moon` / `sol` コマンドが利用可能

## 1. 新規プロジェクトを作成する

```bash
sol new myapp --user yourname
cd myapp
pnpm install
```

`sol new` が生成する `package.json` の主要スクリプト:

- `dev`: `sol dev`
- `build`: `sol build`
- `serve`: `sol serve`

## 2. 開発サーバーを起動する

```bash
# script 経由
pnpm dev

# 直接実行
sol dev
```

確認ポイント:

- `http://localhost:7777/` が表示される
- `http://localhost:7777/api/health` が JSON を返す

## 3. 本番ビルドを作成する

```bash
# script 経由
pnpm build

# 直接実行
sol build
```

## 4. 本番ビルドを配信する

```bash
# script 経由
pnpm serve

# 直接実行
sol serve
```

## 5. 変更反映の最短フロー

ルートを変更したときは以下で差分を確認します。

```bash
sol generate --mode dev
sol dev
```

ルーティング仕様の正本: `docs/routing.md`  
問題が起きたとき: `docs/troubleshooting.md`
