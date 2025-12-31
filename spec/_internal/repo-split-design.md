# リポジトリ分割設計

## 現状の課題

- Luna + Sol + Astra が一つのリポジトリで垂直統合されている
- 実験的コードが増え、見通しが悪くなっている
- Astra と Sol の境界が曖昧

## 分割方針

### 分割後の構成

```
luna/                    ← コアUIライブラリ（新リポジトリ）
├── signal/              Signal システム
├── render/              VNode, レンダリング抽象
├── dom/                 DOM 操作（Browser）
├── static_dom/          静的レンダリング
├── css/                 CSS Utilities
├── serialize/           状態シリアライズ
├── routes/              ルーティング型定義
└── components/radix/    Radix コンポーネント

sol/                     ← SSR/SSGフレームワーク（現リポジトリを改名）
├── core/                共有型、設定
├── runtime/             ランタイム
├── router/              ルーティング
├── middleware/          Hono ミドルウェア
├── action/              Server Actions
├── content/             Markdown, Frontmatter
├── ssg/                 ← Astra を統合
│   ├── generator/       静的サイト生成
│   ├── components/      Blog, Header, Footer
│   ├── routes/          ファイルベースルーティング
│   ├── mdx/             MDX 処理
│   ├── isr/             Incremental Static Regeneration
│   └── cache/           ビルドキャッシュ
├── stella/              Island Shard 生成
├── platform/            プラットフォーム固有実装
└── adapters/            デプロイアダプタ
```

## 依存関係

```
Luna (コアUI)
  ↑ 外部依存なし
  │
Sol (SSR/SSG Framework)
  └── @luna_ui/luna に依存
```

Luna は Sol に依存しない（一方向依存）。

## Astra → Sol/ssg 統合の理由

1. **境界の曖昧さ**: Astra は Sol の機能（content/, routes/）に強く依存
2. **循環的結合**: astra/* 内部で相互参照が発生している
3. **概念的統一**: SSG は SSR の静的化バリエーションとして捉える

### 統合後の責務

| モジュール | 責務 |
|-----------|------|
| sol/router | 動的ルーティング（SSR） |
| sol/ssg/routes | 静的ルーティング（ビルド時） |
| sol/ssg/generator | 静的サイト生成 |
| sol/content | Markdown/MDX 処理（共有） |
| sol/middleware | Hono ミドルウェア（SSR時） |
| sol/ssg/isr | ISR（ハイブリッド） |

## 実装計画

### Phase 1: Luna Core 分離

- src/luna/ を新リポジトリに移動
- NPM パッケージ `@luna_ui/luna` として公開
- 工数: 2-3日

### Phase 2: Astra → Sol/ssg 統合

```
src/astra/generator/   → src/sol/ssg/generator/
src/astra/components/  → src/sol/ssg/components/
src/astra/routes/      → src/sol/ssg/routes/
src/astra/mdx/         → src/sol/ssg/mdx/
src/astra/isr/         → src/sol/ssg/isr/
src/astra/cache/       → src/sol/ssg/cache/
src/astra/tree/        → src/sol/ssg/tree/
src/astra/assets/      → src/sol/ssg/assets/
src/astra/themes/      → src/sol/ssg/themes/
```

- import パスの変更
- moon.pkg.json の更新
- 工数: 1週間

### Phase 3: Sol 内部整理

- 循環依存の解消
- 責務の明確化
- ドキュメント更新
- 工数: 1-2週間

## 分割のメリット

### Luna 側
- バンドルサイズ最小化（5KB以下目標）
- 他のフレームワークからの利用可能
- ブラウザ専用パッケージとして独立

### Sol 側
- SSR/SSG を統一的に扱える
- CLI ツールの統合
- 設定の一元化（sol.config.json）

## 分割しない場合

現状のまま維持し、以下を優先：
- Astra 内部の循環依存解消
- 不要コードの削除
- ドキュメント整備

## 関連ファイル

- src/luna/ - Luna Core
- src/sol/ - Sol Framework
- src/astra/ - SSG (統合予定)
- src/stella/ - Shard Generator
- src/core/ - 共有型定義
- src/platform/ - プラットフォーム固有

---

作成日: 2024-12-31
ステータス: 検討中
