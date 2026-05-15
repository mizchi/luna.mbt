---
title: 概要
---

# Luna エコシステム概要

Lunaは、MoonBitとJavaScriptでモダンなWebアプリケーションを構築するためのツールスイートです。

## どれを使うべき？

| やりたいこと | 使うもの | 言語 |
|-------------|---------|------|
| ドキュメントサイトを作りたい | **Astra** | Markdown + Islands |
| フルスタックWebアプリを作りたい | **Sol** | MoonBit |
| 既存ページにリアクティビティを追加したい | **Luna UI** | JavaScript/TypeScript |
| fine-grained reactivityを学びたい | **Luna UI チュートリアル** | JS or MoonBit |

### 選択フローチャート

```
Webサイトが必要？
├── 静的コンテンツ (ドキュメント, ブログ) → Astra
└── 動的アプリ (認証, API) → Sol

学習目的？
├── JavaScript を知っている → JS チュートリアル
└── MoonBit を知っている → MoonBit チュートリアル
```

## なぜ Luna なのか？

既存のソリューションへの不満から生まれました：

- **React** - パフォーマンスが重要なアプリケーションには大きすぎる
- **Qwik / Solid** - コンパイル時の変換がデバッグの邪魔になる
- **WebComponentsファーストのフレームワークがなかった** - 今までは

## 設計思想

### コンパイル時最適化が不要なほど小さい

| フレームワーク | バンドルサイズ |
|--------------|--------------|
| **Luna** | **~6.7 KB** |
| Preact | ~20 KB |
| Solid | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

Lunaは意図的にミニマルです。フレームワークのオーバーヘッドは無視できるレベルなので、コンパイル時の最適化は不要です。

### WebComponents SSR（世界初の実装）

Lunaは **WebComponents SSR + Hydration を完全サポートした初めてのフレームワーク** です。

- ブラウザ標準を優先（フレームワーク抽象化より）
- Shadow DOMによるスタイルカプセル化
- サーバーレンダリング用のDeclarative Shadow DOM

### ランタイムパフォーマンス

| シナリオ | Luna | React |
|---------|------|-------|
| 100×100 DOM シューティングゲーム | **60 FPS** | 12 FPS |

Fine-grained reactivityにより、実際のシナリオで **5倍のパフォーマンス** を実現。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                     あなたのアプリケーション                   │
├─────────────────────────────────────────────────────────────┤
│  Astra (SSG)            │  Sol (SSR Framework)                 │
│  静的ドキュメントサイト   │  フルスタックアプリ                   │
├─────────────────────────────────────────────────────────────┤
│                       Luna UI                                 │
│           Signals, Islands, Hydration, Components            │
├─────────────────────────────────────────────────────────────┤
│                      MoonBit / JavaScript                    │
└─────────────────────────────────────────────────────────────┘
```

## プロジェクト

### [Luna UI](/ja/luna/) - リアクティブUIライブラリ

すべての基盤：

- **Signals** - Fine-grained リアクティブプリミティブ
- **Islands** - 最適なパフォーマンスのための部分的ハイドレーション
- **Components** - 宣言的構文によるWeb Components
- **Hydration** - スマートなローディング戦略（load, idle, visible, media）

### [Astra](/ja/astra/) - 静的サイトジェネレーター

Markdownからドキュメントサイトやブログを構築：

- フロントマター対応のMarkdown
- 自動生成されるナビゲーションとサイドバー
- 多言語対応（i18n）
- Shikiによるシンタックスハイライト
- View TransitionsによるSPAナビゲーション

このドキュメントサイトもAstraで構築されています（Sol 0.16 以前の組み込み
SSG モードは `mizchi/astra` として独立しました。静的ダンプには
`astra build` を使用してください）。

### [Sol](/ja/sol/) - フルスタックフレームワーク

Hono統合のサーバーサイドレンダリングフレームワーク：

- SSR + 部分的ハイドレーションのIsland Architecture
- ミドルウェア付きの宣言的ルーティング
- CSRF保護付きのServer Actions
- ネストされたレイアウト
- ストリーミングSSR

## npmパッケージ

| パッケージ | 説明 |
|-----------|------|
| `@luna_ui/luna` | コアUIライブラリ + CLI |
| `@luna_ui/sol` | Sol SSR フレームワークCLI |
| `@luna_ui/astra` | Astra 静的サイトジェネレーター CLI |

## クイックスタート

### Luna UI (JavaScript)

```bash
npx @luna_ui/luna new myapp
cd myapp && npm install && npm run dev
```

### Luna UI (MoonBit)

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp && moon update && npm install && npm run dev
```

### Sol (SSR アプリ)

```bash
# sol ネイティブ CLI を一度だけインストール（推奨）
moon install mizchi/sol/cmd/sol

# 0.22.3+ では空ディレクトリで scaffold できる
sol new myapp --user yourname
cd myapp
pnpm install
moon update && moon install
pnpm dev
```

### Astra (ドキュメントサイト)

```bash
moon install mizchi/astra/cmd/astra
mkdir my-docs && cd my-docs
mkdir docs && echo "# Hello" > docs/index.md
astra dev          # ローカルプレビュー
astra build        # ./dist へ静的出力
```

## 学習パス

### JavaScript/TypeScript 開発者向け

1. [JavaScript チュートリアル](/luna/tutorial-js/)から始める
2. [Signals](/luna/api-js/signals)と[Islands](/luna/api-js/islands)を学ぶ
3. [Astra](/ja/astra/)でドキュメントサイトを、[Sol](/ja/sol/)でアプリを構築

### MoonBit 開発者向け

1. [MoonBit チュートリアル](/luna/tutorial-moonbit/)から始める
2. [MoonBit API リファレンス](/luna/api-moonbit/)を探索
3. Solでサーバーサイドコンポーネントを構築

## 機能比較

| 機能 | Luna UI | Astra | Sol |
|------|---------|-------|-----|
| Signals | ✅ | ✅ | ✅ |
| Islands | ✅ | ✅ | ✅ |
| SSR | - | ビルド時 | ランタイム |
| ルーティング | - | ファイルベース | ファイルベース + API |
| Markdown | - | ✅ | - |
| i18n | - | ✅ | - |
| ミドルウェア | - | - | ✅ |
| Server Actions | - | - | ✅ |
| Web Components | ✅ | ✅ | ✅ |

## ステータス

> **実験的** - すべてのプロジェクトは活発に開発中です。APIは変更される可能性があります。

[MoonBit](https://www.moonbitlang.com/)で構築 - クラウドとエッジコンピューティング向けに設計された高速で安全な言語。
