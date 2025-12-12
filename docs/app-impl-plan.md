# Luna + Sol 実装計画

フルスタックWebフレームワークの実装計画。Hono上でSSRとresumable stateを統合する。

## 目標

```bash
$ luna new myapp
$ cd myapp && luna dev  # localhost:3000
```

## プロジェクト構造（生成されるアプリ）

```
myapp/
├── client/
│   └── components/
│       └── counter.mbt        # クライアントコンポーネント
├── server/
│   ├── components/
│   │   └── markdown.mbt       # サーバー専用コンポーネント
│   └── run/
│       ├── routes.mbt         # ルーティング定義
│       └── main.mbt           # エントリーポイント (is-main: true)
└── moon.mod.json
```

## 現状の実装

### src/sol/app.mbt
- Hono上のSSRフレームワーク基盤 (Sol)
- `create_app()`, `page()`, `api()`, `serve()`
- Island Architecture (`IslandConfig`, `render_island`)
- 依存: `mizchi/npm_typed/hono`, `mizchi/js/core`

### src/core/resume/
- `StateValue` enum: Null, Bool, Int, Float, Str, Arr
- `ResumableState`: Signal値のシリアライズ/デシリアライズ
- `Serializable` trait: 型ごとのシリアライズ実装
- JSONパーサー (pure MoonBit)

### src/examples/example_app/
- 基本的なSSRページの例
- `home_page`, `about_page`, `counter_page`

---

## Phase 1: src/core/serialize の分離

### 目的
`src/core/resume` から文字列シリアライズ部分を抽出し、`--target all` で動作するようにする。

### 新規パッケージ: src/core/serialize

```
src/core/serialize/
├── state_value.mbt       # StateValue enum
├── json_serializer.mbt   # to_json実装
├── json_parser.mbt       # from_json実装 (JsonParser)
├── moon.pkg.json         # 依存なし (target all対応)
└── serialize_test.mbt
```

### 抽出対象 (src/core/resume/state.mbt から)
- `StateValue` enum
- `state_value_to_json()`
- `escape_json_string()`
- `JsonParser` struct と関連メソッド
- `ResumableState::to_json()`, `ResumableState::from_json()`

### 残す部分 (src/core/resume/)
- `ResumableState` struct (serialize をインポート)
- `Serializable` trait
- Signal連携 (`register_signal`, `restore_signal`, etc.)

### moon.pkg.json (src/core/serialize)

```json
{
  "import": []
}
```

依存なしでtarget all対応。

---

## Phase 2: CLI基盤 (src/cli)

### 機能

```bash
luna new <name>     # プロジェクト作成
luna dev            # 開発サーバー起動
luna build          # 本番ビルド
luna validate       # client/server境界チェック
```

### 実装方針

Node.js CLI として実装（MoonBitではなくTypeScript）:

```
packages/cli/
├── src/
│   ├── index.ts
│   ├── commands/
│   │   ├── new.ts
│   │   ├── dev.ts
│   │   ├── build.ts
│   │   └── validate.ts
│   └── utils/
│       └── project.ts
├── templates/
│   └── default/          # luna new のテンプレート
└── package.json
```

### dev コマンド内部処理

1. `moon build --target js` 実行
2. `dist/dev/` に中間ファイル生成
3. クライアントコンポーネント用のre-exportスクリプト生成
4. rolldown でバンドル (mizchi/npm_typed/rolldown)
5. Hono開発サーバー起動

### ビルド出力

```
dist/
├── dev/
│   ├── _generated/
│   │   └── client_components.js  # re-export wrapper
│   └── server.js
└── prod/
    ├── client/
    │   └── counter-[hash].js
    └── server/
        └── index.js
```

---

## Phase 3: ルーティング

### routes.mbt の形式

```moonbit
///| ルーティング定義
pub fn setup_routes(app : @sol.App) -> @sol.App {
  // 静的ページ
  app
  |> @sol.page("/", home_page, title="Home")
  |> @sol.page("/about", about_page, title="About")

  // 動的ルート (URLPattern使用)
  |> @sol.page("/posts/:id", post_page, title="Post")

  // API
  |> @sol.api("/api/posts", list_posts)
  |> @sol.api_post("/api/posts", create_post)

  // Island (クライアントコンポーネント)
  |> @sol.island_page("/counter", counter_islands)
}
```

### URLパターン

`mizchi/js/web/url` の URLPattern を使用:

```moonbit
// 内部でURLPatternを使用してパラメータ抽出
let params = ctx.params()  // { "id": "123" }
```

型安全性は最初は諦める（将来的にコード生成で対応）。

---

## Phase 4: 非同期コンポーネント

### サーバーコンポーネントでの非同期

```moonbit
///| サーバー専用: 非同期データフェッチ
async fn post_page(ctx : @sol.Ctx) -> @luna.Node {
  let id = ctx.params().get("id").unwrap()
  let post = fetch_post(id)  // async

  @luna.h("article", [], [
    @luna.h("h1", [], [@luna.vtext(post.title)]),
    @luna.h("div", [], [@luna.vtext(post.content)]),
  ])
}
```

### 制約
- `server/components/` のコンポーネントのみ `async` 使用可
- 必ずSSRされてからクライアントに送信
- クライアント側では hydration のみ（再フェッチなし）

---

## Phase 5: 境界の検証 (luna validate)

### ルール

1. `client/components/` は `server/` をインポート不可
2. `server/components/` は非同期OK
3. `client/components/` から `@js` 系を使うときは注意（bundleに含まれる）

### 検証方法

`moon.pkg.json` の依存関係を静的解析:

```typescript
// packages/cli/src/commands/validate.ts
function validateClientServerBoundary(projectDir: string) {
  // client/components/ の moon.pkg.json を読み取り
  // server/ へのimportがないかチェック
}
```

---

## 実装順序

### Step 1: src/core/serialize 分離
1. [ ] `src/core/serialize/` 作成
2. [ ] `StateValue`, JSONシリアライズ/パース移動
3. [ ] `src/core/resume/` を `serialize` に依存させる
4. [ ] `moon test --target all ./src/core/serialize/`

### Step 2: CLI 基盤
1. [ ] `packages/cli/` 作成
2. [ ] `luna new` コマンド（テンプレートコピー）
3. [ ] `luna dev` コマンド（moon build + serve）

### Step 3: 開発サーバー改善
1. [ ] rolldown統合
2. [ ] クライアントコンポーネントのバンドル
3. [ ] HMR検討（将来）

### Step 4: ルーティング強化
1. [ ] URLPattern統合
2. [ ] 動的ルートパラメータ

### Step 5: 非同期コンポーネント
1. [ ] async page handler
2. [ ] サーバーコンポーネントでのfetch

---

## 設計判断

### React との違い

| React | Luna |
|-------|--------|
| `"use client"` / `"use server"` | ディレクトリ規約 (`client/`, `server/`) |
| Server Components (RSC) | サーバーコンポーネント（非同期OK、SSR専用） |
| Server Actions | API routes (`@sol.api_post`) |
| 自動バンドル分離 | CLI による明示的ビルド |

### 型安全性

最初のPoCでは型安全性を諦める箇所:
- URLパラメータ (`ctx.params()` は `Map[String, String]`)
- JSON API レスポンス

将来的にコード生成で対応可能。

---

## 参考

- [src/sol/app.mbt](../src/sol/app.mbt) - Sol フレームワーク基盤
- [src/core/resume/](../src/core/resume/) - Resumable State実装
- [docs/IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) - 全体計画
- [docs/next-xany.md](./next-xany.md) - クロスターゲットAny型
