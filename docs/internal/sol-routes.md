# Sol Routes 設計

## 概要

Sol の型安全なルーティングシステム。URLPattern API を活用し、パターンマッチングをプラットフォームに委譲する。

## 設計方針

- **URLPattern API**: パターンマッチングをプラットフォームに委譲
- **URLPatternResult**: 中間状態としてユーザーに渡す
- **ユーザー側でパース**: バリデーションはユーザーが明示的に行う
- **フラットな Routes**: Param/Group を廃止し、path~ に URLPattern 構文を直接記述

## URLPattern ベースのパターンマッチング

[URLPattern API](https://developer.mozilla.org/ja/docs/Web/API/URL_Pattern_API) を活用。

```
URL → URLPattern.exec() → URLPatternResult → ユーザーがパース → Typed Params
```

### URLPatternResult

`URLPattern.exec()` の戻り値：

```javascript
{
  pathname: {
    input: "/user/123",
    groups: { uid: "123" }  // 名前付きキャプチャ
  },
  search: {
    input: "?page=1",
    groups: {}
  },
  // ... protocol, hostname, etc.
}
```

### MoonBit ラッパー

```moonbit
// mizchi/js/web/url/url_pattern.mbt

pub struct URLPattern {
  inner : @js.Any
}

pub struct URLPatternResult {
  inner : @js.Any
}

pub fn URLPattern::new(pathname : String) -> URLPattern

pub fn URLPattern::exec(self : URLPattern, url : String) -> URLPatternResult?

pub fn URLPatternResult::get_pathname_group(self : URLPatternResult, name : String) -> String?
```

## Routes 定義

### Before（現状）

```moonbit
// Param, Group で階層構造
Layout(segment="/users", layout="users_layout", children=[
  Param(key="id", children=[
    Page(path="", component="user_detail", ...),
  ]),
])
```

### After（新設計）

```moonbit
// フラットな path~ 定義（URLPattern 構文）
Page(path="/users/:id", component="user_detail", ...)
Page(path="/api/user/:uid", component="api_user", ...)
Page(path="/files/*", component="file_viewer", ...)  // ワイルドカード
```

URLPattern が `:id`, `*`, `**` などを自動で解釈。

## PageProps / RouteParams

```moonbit
// Route parameters extracted from URL
pub struct RouteParams {
  params : Array[(String, String)]          // Path parameters
  query : Array[(String, String)]           // Query parameters
  path : String                             // Full path
  is_fragment : Bool                        // Fragment request flag
  url_pattern_result : URLPatternResult?    // Optional URLPatternResult
}

// Props passed to page components
pub struct PageProps {
  ctx : Ctx
  params : RouteParams
  is_fragment : Bool
}

// Convenience methods on PageProps
pub fn PageProps::get_param(self, key : String) -> String?      // Path param
pub fn PageProps::get_query(self, key : String) -> String?      // Query param
pub fn PageProps::get_pathname_group(self, name : String) -> String?  // URLPattern group
pub fn PageProps::get_search_group(self, name : String) -> String?    // URLPattern search group
pub fn PageProps::path(self) -> String                          // Full path
```

## ユーザー実装

```moonbit
// ページハンドラの例
fn user_page_handler(
  component : String,
  ctx : Ctx,
  params : RouteParams,
) -> @luna.Node? {
  // params.get_param で既存の params 配列から取得
  let uid = params.get_param("uid").unwrap_or("unknown")

  Some(@server_dom.div([], [
    @server_dom.text("User: \{uid}"),
  ]))
}

// URLPatternResult を使う場合（将来的に）
fn user_page_with_pattern(
  component : String,
  ctx : Ctx,
  params : RouteParams,
) -> @luna.Node? {
  // url_pattern_result が設定されている場合は groups から取得可能
  let uid = params.get_pathname_group("uid").unwrap_or("unknown")

  Some(@server_dom.div([], [
    @server_dom.text("User: \{uid}"),
  ]))
}

// バリデーション付き
fn user_detail_handler(
  component : String,
  ctx : Ctx,
  params : RouteParams,
) -> @luna.Node? {
  let id_str = params.get_param("id")?
  // バリデーションはユーザー側で行う

  Some(@server_dom.div([], [
    @server_dom.text("User ID: \{id_str}"),
  ]))
}
```

## CLI コマンド

```bash
sol validate   # sol.config.json の検証
sol generate   # コード生成（app/__gen__/*.mbt）
sol dev        # validate + generate + build + serve（watch モード）
sol build      # validate + generate + moon build
```

### sol validate

生成前に設定ファイルを検証：

- **パス構文検証**: URLPattern として有効か
- **パス重複検出**: 同じパスパターンが複数定義されていないか
- **ID 重複検出**: ルート ID がユニークか

## プラットフォーム互換性

| プラットフォーム | サポート |
|-----------------|---------|
| Chrome | 95+ |
| Safari | 17+ |
| Firefox | 未サポート（polyfill 必要） |
| Node.js | 18+ |
| Deno | サポート |
| Cloudflare Workers | サポート |

**互換アダプタ**: Firefox や古いブラウザ向けに、後で polyfill または MoonBit 純粋実装のフォールバックを用意する。

```moonbit
// mizchi/js/web/url/adapter.mbt

/// URLPattern 互換インターフェース
pub trait URLPatternLike {
  exec(Self, String) -> URLPatternResult?
  test(Self, String) -> Bool
}

/// ネイティブ実装
pub struct NativeURLPattern { ... }

/// 純粋実装（フォールバック）
pub struct PureURLPattern { ... }

/// 環境に応じて適切な実装を返す
pub fn create_url_pattern(pathname : String) -> &URLPatternLike
```

現状の `src/core/routes/match.mbt` の純粋 MoonBit 実装が `PureURLPattern` のベースになる。

## 参考リンク

- [URLPattern API (MDN)](https://developer.mozilla.org/ja/docs/Web/API/URL_Pattern_API)
- [Mocket](https://github.com/oboard/mocket)
