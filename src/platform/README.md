# Platform

プラットフォーム固有の実装。

## モジュール構成

| サブモジュール | 責務 |
|---------------|------|
| `dom/` | ブラウザDOM操作 |
| `js/` | JS固有API |
| `server_dom/` | サーバーサイドDOM (イベントなし) |

## dom/

ブラウザ環境向けのDOM操作。

| パス | 責務 |
|-----|------|
| `element/` | 低レベルDOM操作 (render, diff, reconcile) |
| `client/` | クライアント側Hydration |
| `router/` | クライアントサイドルーティング |
| `portal/` | Portalコンポーネント |
| `island.mbt` | Island Hydration |
| `wc_island.mbt` | Web Components Island (Declarative Shadow DOM) |

## js/

JavaScript固有の機能。

| パス | 責務 |
|-----|------|
| `api/` | JS向け公開API (`@mizchi/luna`) |
| `stream_renderer/` | ストリーミングSSR |
| `cache/` | ファイルキャッシュ (mtime ベース) |
| `fs_adapter/` | FileSystem アダプター (Node.js, memfs) |

## server_dom/

サーバーサイドDOM生成。イベントハンドラなし。

| パス | 責務 |
|-----|------|
| `element/` | HTML要素ファクトリ (html, head, body等) |
| `island.mbt` | Islandヘルパー |
| `wc_island.mbt` | Web Components Island |
| `render.mbt` | レンダリング関数 |

## 使い分け

```
ブラウザ実行時 → dom/
サーバー実行時 → server_dom/
JS固有機能    → js/
```

## 参照

- [Luna Core](../luna/README.md) - VNode定義
- [Stella](../stella/README.md) - Shard生成
