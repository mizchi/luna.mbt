---
title: 概要
---

# Luna エコシステム概要

Luna は MoonBit と JavaScript でモダンな Web アプリケーションを構築するためのツール群です。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                     あなたのアプリケーション                    │
├─────────────────────────────────────────────────────────────┤
│  Astra (SSG)           │  Sol (SSR フレームワーク)             │
│  静的サイト生成          │  フルスタックアプリ                   │
├─────────────────────────────────────────────────────────────┤
│                       Luna (コアライブラリ)                    │
│                Signals, Islands, Hydration                   │
├─────────────────────────────────────────────────────────────┤
│                      MoonBit / JavaScript                    │
└─────────────────────────────────────────────────────────────┘
```

## プロジェクト

### [Luna](/ja/luna/) - コアライブラリ

すべての基盤となる UI ライブラリ。

- **Signals** - きめ細かいリアクティブプリミティブ
- **Islands** - 部分的 Hydration による最適なパフォーマンス
- **Hydration** - スマートなローディング戦略 (load, idle, visible, media)

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [count, setCount] = createSignal(0);
createEffect(() => console.log(count()));
setCount(1);  // Logs: 1
```

### [Astra](/ja/astra/) - 静的サイトジェネレーター

Markdown からドキュメントサイトやブログを生成するビルドツール。

- Frontmatter 対応の Markdown
- ナビゲーションとサイドバーの自動生成
- i18n（国際化）サポート
- Shiki によるシンタックスハイライト

このドキュメントサイトは Astra で構築されています。

### [Sol](/ja/sol/) - フルスタックフレームワーク

Hono 統合による SSR フレームワーク。

- Island Architecture による SSR + 部分的 Hydration
- ファイルベースルーティング
- Edge 対応デプロイ

### Stella - 配布プラットフォーム

生成したコードを外部に配布するためのプラットフォーム。詳細は別途公開予定。

## 学習パス

### JavaScript 開発者向け

1. [チュートリアル (JavaScript)](/ja/tutorial-js/) から始める
2. [Signals](/ja/luna/signals/) と [Islands](/ja/luna/islands/) を学ぶ
3. [Astra](/ja/astra/) でサイトを、または [Sol](/ja/sol/) でアプリを構築

### MoonBit 開発者向け

1. [チュートリアル (MoonBit)](/ja/tutorial-moonbit/) から始める
2. MoonBit でのコア Luna API を探索
3. サーバーサイドコンポーネントを構築

## 機能比較

| 機能 | Astra | Sol |
|------|-------|-----|
| ユースケース | ドキュメント、ブログ | Web アプリケーション |
| レンダリング | 静的（ビルド時） | 動的（リクエスト時） |
| ルーティング | ファイルベース | ファイルベース + API ルート |
| Islands | Markdown 埋め込み | コンポーネントベース |
| デプロイ | 静的ホスティング | Edge ランタイム / Node.js |

## はじめに

目的に応じて選択：

- **ドキュメントを作成？** → [Astra クイックスタート](/ja/astra/)
- **アプリを構築？** → [Sol クイックスタート](/ja/sol/)
- **リアクティビティだけ必要？** → [Luna Signals](/ja/luna/signals/)

## ステータス

> **実験的** - すべてのプロジェクトは活発に開発中です。API は変更される可能性があります。

[MoonBit](https://www.moonbitlang.com/) で構築 - クラウドとエッジコンピューティングのための高速で安全な言語。
