---
title: はじめる
---

# はじめる

Luna UIフレームワークを始めましょう。

## クイックスタート

### Luna UI (JavaScript/TypeScript)

```bash
npx @luna_ui/luna new myapp
cd myapp
npm install
npm run dev
```

ブラウザで http://localhost:5173 を開きます。

### Luna UI (MoonBit)

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp
moon update
npm install
npm run dev
```

ブラウザで http://localhost:5173 を開きます。

### Astra (ドキュメントサイト)

```bash
moon install mizchi/astra/cmd/astra
mkdir my-docs && cd my-docs
mkdir docs && echo "# Hello Astra" > docs/index.md
astra dev          # ローカルプレビュー
astra build        # ./dist へ静的出力
```

`astra dev` のデフォルトは http://localhost:7777 です（`--port` で変更可）。

## 次のステップ

- [概要](/ja/introduction/overview/) - Luna エコシステムの全体像を理解
- [Luna チュートリアル (JavaScript)](/luna/tutorial-js/) - JavaScript で Luna を学ぶ
- [Luna チュートリアル (MoonBit)](/luna/tutorial-moonbit/) - MoonBit で Luna を学ぶ
