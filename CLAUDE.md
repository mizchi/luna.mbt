# Kaguya Framework

MoonBitで実装されたIsland ArchitectureベースのUIフレームワーク。

## プロジェクト構成

```
src/                    # MoonBitソースコード
├── signal.mbt          # Signalプリミティブ
├── effect.mbt          # Effectプリミティブ
├── element/            # HTML要素ファクトリ (div, span等)
├── ssr/                # SSRレンダリング
├── embedding/          # 埋め込みモード
├── resume/             # 状態復帰/シリアライズ
├── js/                 # JS専用モジュール
│   ├── dom/            # DOM操作、Hydration
│   │   └── reconcile/  # VDOM差分計算
│   ├── ssr/            # JSストリーミングSSR
│   ├── framework/      # Hono統合
│   └── webcomponents/  # WebComponents
├── tests/              # テストコンポーネント
└── examples/           # サンプル
packages/               # NPMパッケージ
├── core/               # @kaguya/core (旧ui)
└── loader/             # @kaguya/loader
e2e/                    # Playwrightテスト
```

## コマンド

```bash
# MoonBitビルド/テスト
moon check               # 型チェック
moon build --target js   # JSビルド
moon test --target js    # ユニットテスト

# NPMテスト
pnpm test:browser        # Vitest browser mode
pnpm test:e2e            # Playwright E2E
pnpm test:e2e:embedding  # Embeddingテストのみ
pnpm test:e2e:loader     # Loaderテストのみ
```

## 命名規約

### HTML属性 (kg:*)
- `kg:id` - コンポーネントID
- `kg:url` - Hydration用モジュールURL
- `kg:trigger` - Hydrationトリガー (load, idle, visible, media)
- `kg:state` - シリアライズされた状態JSON

### MoonBit名前空間
- `mizchi/kaguya` - コア（旧 mizchi/ui）
- `@kaguya.` - Signal, Node, Attr等のエイリアス
- `@dom.` - DOM操作のエイリアス
- `@ssr.` - SSRのエイリアス

### NPMパッケージ
- `@mizchi/kaguya` - コアランタイム
- `@mizchi/kaguya-loader` - Islandローダー

## アーキテクチャ

### Island Architecture
- SSRで静的HTML生成
- `kg:*`属性でIsland境界をマーク
- kaguya-loaderが遅延Hydration実行

### トリガータイプ
| トリガー | 説明 |
|---------|------|
| `load` | ページロード時即座 |
| `idle` | requestIdleCallback時 |
| `visible` | IntersectionObserver検知時 |
| `media` | メディアクエリマッチ時 |

### Signals
```moonbit
let count = @ui.signal(0)
@ui.effect(fn() { println(count.get().to_string()) })
count.set(1)  // "1" が出力される
```

## 開発時の注意

- 名前空間は `mizchi/kaguya` (移行中)
- 属性は `kg:*` 形式に統一
- テストは必ず `moon check` と `pnpm test:e2e` の両方を確認
- XSSエスケープは `src/embedding/serializer.mbt` で処理

## 参照ドキュメント

- [実装計画](./docs/IMPLEMENTATION_PLAN.md)
- [Embedding Architecture](./src/embedding/ARCHITECTURE.md)
- [Reconcile README](./src/js/dom/reconcile/README.md)
