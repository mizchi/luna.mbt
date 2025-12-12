# Luna Framework

MoonBitで実装されたIsland ArchitectureベースのUIフレームワーク。

## プロジェクト構成

```
src/                    # MoonBitソースコード
├── core/               # コアモジュール
│   ├── signal/         # Signalプリミティブ
│   ├── resume/         # 状態復帰/シリアライズ
│   └── vnode.mbt       # VNode定義
├── browser/            # ブラウザ専用モジュール
│   ├── dom/            # DOM操作、レンダリング、差分更新
│   ├── fixable/        # 実験的Hydration
│   ├── client_router.mbt # クライアントルーター
│   └── hydrate.mbt     # Hydration
├── server/             # サーバーサイド
│   ├── renderer/       # SSRレンダリング
│   ├── renderer_web/   # WebストリーミングSSR
│   └── embed/          # Island埋め込み
├── sol/                # SSRフレームワーク（Next.js相当）
├── router/             # ルーティング
├── tests/              # テストコンポーネント
└── examples/           # サンプル
packages/               # NPMパッケージ
├── luna/               # @mizchi/luna
├── loader/             # @mizchi/luna-loader
└── cli/                # CLIツール
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

### HTML属性 (ln:*)
- `ln:id` - コンポーネントID
- `ln:url` - Hydration用モジュールURL
- `ln:trigger` - Hydrationトリガー (load, idle, visible, media)
- `ln:state` - シリアライズされた状態JSON

### MoonBit名前空間
- `mizchi/luna` - コア（旧 mizchi/ui）
- `@luna.` - Signal, Node, Attr等のエイリアス
- `@dom.` - DOM操作のエイリアス
- `@ssr.` - SSRのエイリアス
- `@sol.` - SSRフレームワーク（App, Ctx等）のエイリアス

### NPMパッケージ
- `@mizchi/luna` - コアランタイム
- `@mizchi/luna-loader` - Islandローダー

## アーキテクチャ

### Island Architecture
- SSRで静的HTML生成
- `ln:*`属性でIsland境界をマーク
- luna-loaderが遅延Hydration実行

### トリガータイプ
| トリガー | 説明 |
|---------|------|
| `load` | ページロード時即座 |
| `idle` | requestIdleCallback時 |
| `visible` | IntersectionObserver検知時 |
| `media` | メディアクエリマッチ時 |

### Signals
```moonbit
let count = @signal.signal(0)
@signal.effect(fn() { println(count.get().to_string()) })
count.set(1)  // "1" が出力される
```

## 開発時の注意

- 名前空間は `mizchi/luna`
- 属性は `ln:*` 形式に統一
- テストは必ず `moon check` と `pnpm test` の両方を確認
- XSSエスケープは `src/server/embed/serializer.mbt` で処理

## 参照ドキュメント

- [Embedding Architecture](./src/server/embed/ARCHITECTURE.md)
