# Mars から Sol への移行ガイド

`sol` は `mars` の薄いラッパーとして設計しているため、段階的に移行できます。

## 方針

- 既存の `@mars.Server::new()` / `app.get` / `app.post` はそのまま使う
- 先にエントリポイントだけ `sol` に寄せる
- HTML レンダリングだけ `sol.page` に置き換える
- 最後に file based routing / `SolRoutes` を必要範囲で導入する

## 1. エントリポイントを `sol` に寄せる

既存のルート登録コードをほぼ変更せず、起動だけ `@sol.run_app` へ寄せます。

```moonbit
// before: mars で独自起動
// after: sol で起動境界を統一

fn configure_app() -> @mars.Server {
  let app = @mars.Server::new()
  register_api_routes(app) // 既存の mars handler 群をそのまま利用
  app
}

fn main {
  @sol.run_app(configure_app)
}
```

## 2. API ルートはそのまま維持する

`sol` は `App = @mars.Server` / `Ctx = @mars.Context` なので、API ルートは従来どおり書けます。

```moonbit
fn register_api_routes(app : @mars.Server) -> Unit {
  app.get(
    "/api/health",
    @mars.handler(async fn(c) {
      c.json(@sol.json_obj([("ok", @js.any(true))]))
    }),
  )
}
```

## 3. HTML ルートだけ `sol.page` に移行する

手書き HTML レスポンスを `sol` の SSR ヘルパへ寄せます。

```moonbit
fn home(_c : @mars.Context) -> @luna.Node[Unit, String] {
  @luna.h1([@luna.text("Hello from Sol SSR")])
}

fn register_pages(app : @mars.Server) -> Unit {
  @sol.page(app, "/", home, title="Home")
}
```

## 4. static / HMR を統一する

- static 配信: `@sol.serve_static(app)`
- HMR script 注入: `@sol.page` / `@router.register_sol_routes` 側で共通化済み
- 直接使う場合: `@hot_reload.with_dev_head_script(head)`

## 5. ルーティングを段階的に移行する

- file based routing を薄く使うなら: `@router.register_routes`
- layout 合成を含めて使うなら: `@router.register_sol_routes`

## API 対応表

| 既存 (mars) | 移行先 (sol) | 備考 |
|---|---|---|
| `@mars.Server::new()` | そのまま | `sol` でも同じ app 型を使う |
| `app.get/post/...` | そのまま | API ルートは基本据え置き可能 |
| `@mars.Context` | `@mars.Context` | そのまま利用 |
| 手書き HTML 文字列 | `@sol.page` / `@sol.render_page` | SSR と HMR 注入を統一 |
| 独自起動コード | `@sol.run` / `@sol.run_app` | 起動境界を統一 |

## 注意点

- `@sol.serve` / `@sol.create_app_then` は削除済み（`@sol.run` / `@sol.run_app` を利用）
- `@sol.get_port` / `@sol.get_hmr_port` / `@sol.get_hmr_script` / `@sol.set_env` は削除済み（`@hot_reload.*` と CLI 側 env 設定を利用）
- `@sol.text_response` / `@sol.js_response` / `@sol.static_response` / `@sol.read_file_sync` は削除済み（`Ctx` の `text/html/json` と static serve API を利用）
- まず「起動境界」と「HTML ルート」だけ移行し、API は据え置くのが安全
