# Astra/Sol 責務再編成

## 完了した作業

### 1. browser_router の移動

```
移動前: src/luna/dom/router/
移動後: src/sol/browser_router/
```

理由: ブラウザルーターは sol のフレームワーク機能であり、luna のコアUI機能ではない。

依存関係:
- `luna/routes` (ルートマッチングのコア型)
- `luna/signal` (リアクティブ状態管理)

## 不確定事項

### 1. Routes モジュールの統合

現状、3つの routes モジュールが存在:

| モジュール | ターゲット | 責務 |
|-----------|-----------|------|
| `luna/routes` | js, wasm-gc, native | RouteMatch, CompiledRoutes (コアマッチング) |
| `core/routes` | all | SSG メタデータ、パターンコンパイル |
| `astra/routes` | js | ファイルベースルーティング |

**選択肢:**
- A) luna/routes をそのまま保持（ターゲット非依存性が重要）
- B) luna/routes を sol/routes に移動し、luna は sol から借用
- C) core/routes を sol/routes にマージ

**推奨:** A（luna/routes は native ターゲットでも使える汎用性がある）

### 2. Astra/Sol 間のルーティング統合

現状:
- `astra/routes`: ファイルベースルーティング（マークダウンファイルからルート生成）
- `sol/router`: Hono 統合のサーバールーター

**選択肢:**
- A) sol/router が astra/routes を使うように依存追加
- B) astra/routes のファイルスキャン部分を sol に移動
- C) 共通インターフェースを core/routes に定義

**懸念:** sol → astra の依存は逆方向なので避けたい

### 3. ISR 実装の統合

現状、3つの ISR モジュールが存在:

| モジュール | 依存 | 用途 |
|-----------|------|------|
| `core/isr` | なし | 基本型定義 |
| `sol/isr` | hono | SSR ランタイム用 |
| `astra/isr` | core_isr, astra, fs | SSG ビルド時用 |

**判断:** 異なる用途なので現状のまま維持が妥当

### 4. Cache 実装

現状:
- `core/cache`: 基本型定義
- `astra/cache`: SSG 用キャッシュ（ファイルシステム）

**判断:** 異なる用途なので現状のまま維持が妥当

## 今後の移動候補

単純なディレクトリ移動で済むものは完了。
残りは設計判断が必要なもののみ。

### 優先度: 高
- `core/routes` → `sol/routes` へのマージ検討
  - `ssg` メタデータ型は sol に統合すべきか

### 優先度: 中
- `astra/routes` のファイルスキャン機能を sol で利用可能にする方法

### 優先度: 低
- `sol/cli` と `astra/cli` の統合
