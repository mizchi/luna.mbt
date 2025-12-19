---
title: Sol Framework
---

# Sol Framework

> **実験的**: Solは開発中です。APIは予告なく変更される可能性があります。

SolはLuna UIとMoonBitで構築されたフルスタックSSRフレームワークです。

## 特徴

- **ファイルベースルーティング** - ディレクトリ構造からページとAPIルートを生成
- **Islandハイドレーション** - スマートなトリガーで最小限のJavaScriptを配信
- **型安全なサーバー/クライアント** - MoonBitの型がサーバーからブラウザまで流れる
- **Hono統合** - 高速で軽量なHTTPサーバー

## クイックスタート

```bash
# 新しいSolプロジェクトを作成
npx sol new my-app
cd my-app

# 開発
npm run dev

# 本番ビルド
npm run build
```

## プロジェクト構造

```
my-app/
├── app/
│   ├── pages/           # ファイルベースルート
│   │   ├── index.mbt    # /
│   │   └── about.mbt    # /about
│   ├── islands/         # インタラクティブコンポーネント
│   │   └── counter.mbt
│   └── api/             # APIルート
│       └── hello.mbt    # /api/hello
├── sol.config.json
└── moon.mod.json
```

## ステータス

Solは実験的であり、本番環境での使用には適していません。推奨:

- 静的ドキュメントサイトには[Astra](/ja/astra/)を使用
- クライアントサイドアプリケーションにはLuna UIを直接使用
- 更新は[GitHubリポジトリ](https://github.com/aspect-build/aspect-cli)をフォロー

## 関連

- [Luna UIガイド](/ja/guide/) - コアリアクティビティの概念
- [Astra SSG](/ja/astra/) - 静的サイト生成
