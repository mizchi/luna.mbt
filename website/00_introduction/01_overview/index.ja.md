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
| 配布可能なWeb Componentsを作りたい | **Stella** | MoonBit |
| 既存ページにリアクティビティを追加したい | **Luna UI** | JavaScript/TypeScript |
| fine-grained reactivityを学びたい | **Luna UI チュートリアル** | JS or MoonBit |

### 選択フローチャート

```
Webサイトが必要？
├── 静的コンテンツ (ドキュメント, ブログ) → Astra
└── 動的アプリ (認証, API) → Sol

コンポーネントが必要？
├── スタンドアロン配布 → Stella (Web Components)
└── Lunaアプリ内 → Luna UI Islands

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
│  Astra (SSG)          │  Sol (SSR Framework)                 │
│  静的ドキュメントサイト  │  フルスタックアプリ                   │
├─────────────────────────────────────────────────────────────┤
│                       Luna UI                                 │
│           Signals, Islands, Hydration, Components            │
├─────────────────────────────────────────────────────────────┤
│  Stella (Web Components)                                     │
│  スタンドアロン配布可能コンポーネント                           │
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

このドキュメントサイトもAstraで構築されています。

### [Sol](/ja/sol/) - フルスタックフレームワーク

Hono統合のサーバーサイドレンダリングフレームワーク：

- SSR + 部分的ハイドレーションのIsland Architecture
- ミドルウェア付きの宣言的ルーティング
- CSRF保護付きのServer Actions
- ネストされたレイアウト
- ストリーミングSSR

### [Stella](/ja/stella/) - Web Componentsビルダー

MoonBitからスタンドアロンで配布可能なWeb Componentsを構築：

- MoonBitを標準的なCustom Elementsにコンパイル
- Signalベースのfine-grained reactivity
- Declarative Shadow DOMによるSSR/Hydration
- TypeScriptとReactの型定義
- 自動検出用のローダースクリプト

## npmパッケージ

| パッケージ | 説明 |
|-----------|------|
| `@luna_ui/luna` | コアUIライブラリ + CLI |
| `@luna_ui/astra` | 静的サイトジェネレーターCLI |
| `@luna_ui/stella` | Web ComponentsジェネレーターCLI |
| `@luna_ui/wcr` | Web Componentsランタイム（Stella用） |

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

### Astra (ドキュメントサイト)

```bash
npx @luna_ui/astra new my-docs
cd my-docs && npm install && npm run dev
```

## 学習パス

### JavaScript/TypeScript 開発者向け

1. [JavaScript チュートリアル](/luna/tutorial-js/)から始める
2. [Signals](/luna/api-js/signals)と[Islands](/luna/api-js/islands)を学ぶ
3. [Astra](/ja/astra/)でサイトを、[Sol](/ja/sol/)でアプリを構築

### MoonBit 開発者向け

1. [MoonBit チュートリアル](/luna/tutorial-moonbit/)から始める
2. [MoonBit API リファレンス](/luna/api-moonbit/)を探索
3. Solでサーバーサイドコンポーネントを構築

## 機能比較

| 機能 | Luna UI | Astra | Sol | Stella |
|------|---------|-------|-----|--------|
| Signals | ✅ | ✅ | ✅ | ✅ |
| Islands | ✅ | ✅ | ✅ | ✅ |
| SSR | - | ビルド時 | ランタイム | オプション |
| ルーティング | - | ファイルベース | ファイルベース + API | - |
| Markdown | - | ✅ | - | - |
| i18n | - | ✅ | - | - |
| ミドルウェア | - | - | ✅ | - |
| Server Actions | - | - | ✅ | - |
| Web Components | ✅ | ✅ | ✅ | ✅ (メイン) |
| 配布可能 | - | - | - | ✅ |

## ステータス

> **実験的** - すべてのプロジェクトは活発に開発中です。APIは変更される可能性があります。

[MoonBit](https://www.moonbitlang.com/)で構築 - クラウドとエッジコンピューティング向けに設計された高速で安全な言語。
