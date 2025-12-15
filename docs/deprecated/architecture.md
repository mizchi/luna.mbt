# Luna Architecture

## src/ 構造

```
src/
├── core/                      # ターゲット非依存
│   ├── signal/                # Signalプリミティブ
│   ├── vnode.mbt              # VNode定義
│   └── serialize/             # 状態シリアライズ
│
├── renderer/                  # VNode → 文字列 (純粋、DOM非依存)
│   ├── render_to_string.mbt   # HTML文字列生成
│   ├── stream_render.mbt      # ストリーミング対応
│   └── shard/                 # Island埋め込み
│
├── platform/                  # プラットフォーム固有
│   ├── dom/                   # ブラウザ DOM API
│   │   ├── element/           # 低レベルDOM操作 (render, diff, reconcile)
│   │   ├── hydrate.mbt        # Hydration
│   │   ├── island.mbt         # Island hydration
│   │   └── repair/            # 実験的Hydration
│   │
│   └── server_dom/            # サーバーサイドDOM
│       ├── elements.mbt       # html, head, body等の要素ファクトリ
│       ├── island.mbt         # Islandヘルパー
│       └── render.mbt         # レンダリング関数
│
├── router/                    # ルーティング
│
├── sol/                       # SSRフレームワーク (将来分離候補)
│
├── lib/                       # 公開API
│   └── api_js/
│
├── examples/
└── tests/
```

## モジュール責務

| モジュール | 責務 | DOM依存 | 実行環境 |
|-----------|------|---------|----------|
| `core/` | Signal, VNode, serialize | なし | どこでも |
| `renderer/` | VNode → HTML文字列 | なし | どこでも |
| `platform/dom/` | VNode → 実DOM | あり | ブラウザ |
| `platform/dom/element/` | 低レベルDOM操作 | あり | ブラウザ |
| `platform/server_dom/` | サーバーSSR用VNode生成 | なし | サーバー(JS) |
| `router/` | ルーティング定義 | なし | どこでも |
| `sol/` | Honoベースのフレームワーク | renderer利用 | サーバー |

## server_dom モジュール

サーバーサイドでHTMLドキュメントを生成するためのモジュール。

### 特徴
- イベントハンドラなし（`E = Unit`）
- `html`, `head`, `body` などのドキュメント構造要素をサポート
- `island()` ヘルパーでクライアントコンポーネントを埋め込み可能
- `renderer` を内部で使用してHTML文字列を生成

### 使用例

```moonbit
// サーバーサイドでHTMLドキュメントを生成
let doc = @server_dom.document(
  lang="ja",
  head_children=[
    @server_dom.title("My App"),
    @server_dom.meta(charset="UTF-8"),
  ],
  body_children=[
    @server_dom.h1(children=[@server_dom.text("Hello!")]),
    // クライアントコンポーネントをIslandとして埋め込み
    @server_dom.island(
      "counter",
      "/components/counter.js",
      state="{\"count\":0}",
      children=[@server_dom.text("Loading...")],
    ),
  ],
)
let html = @server_dom.render_document(doc)
```

### 将来の拡張
現在はJSターゲットのみ対応。将来的にWASMやNativeターゲットからのレンダリングも検討（中間生成コードの整備が必要）。

## 依存関係

```
core/signal  ←  core/  ←  renderer/
                  ↑           ↑
         platform/dom/element mercurius/
                  ↑
            platform/dom/
                  ↑
            platform/dom/repair/

            core/  ←  renderer/
                         ↑
                  platform/server_dom/

                  ↓
                sol/  (renderer, shard を利用)
```

## 将来の拡張

```
platform/
├── dom/           # ブラウザ
├── server_dom/    # サーバーサイドSSR (実装済み)
├── terminal/      # Terminal UI (将来)
└── canvas/        # Canvas 2D (将来)
```
