# Routing Specification

`sol` のルーティング仕様はこのドキュメントを単一ソースとして扱います。

## 1. API Selection

`sol` には用途の異なる2系統の登録 API があります。

| API | Input | 主目的 | Layout の扱い |
|---|---|---|---|
| `@router.register_routes` / `@router.register_server_routes` | `@luna/core/routes.Routes` | file based routing の割り当てを薄く行う | path prefix のグルーピングのみ（layout 合成しない） |
| `@router.register_sol_routes` | `@router.SolRoutes` | `ServerNode` SSR とレイアウト合成込みで扱う | `SolRoutes::Layout` を適用する |

## 2. Layout Semantics

- `register_routes` / `register_server_routes`
  - `Layout(segment, children, layout)` の `layout` は適用しない
  - `segment` による URL prefix 付与だけを行う
- `register_sol_routes`
  - `SolRoutes::Layout` の layout 関数を内側から外側へ順に適用する

## 3. Dynamic `source_path` Query Format

SSG 内部表現の `source_path` で動的パラメータを保持する場合、形式は以下です。

- 形式: `path/to/template.md?key=value&key2=value2...`
- 値は URL エンコードして埋め込む
- 動的セグメントに対応する主パラメータは常に含める
- `staticParams` に追加キーがある場合はクエリとして追記する

例:

- `docs/_...slug_/index.md?slug=guide%2Fintro&lang=ja`
- `posts/_id_.md?id=a%2Bb%3Dc%26d&preview=true`

復元時 (`page_generator`) は、クエリを URL デコードして `Map[String, String]` に復元します。

## 4. Scope

- この `source_path` 規約は SSG 用の内部表現です
- 実行時ルーティング (`Context::param`) にはこの規約は不要です
