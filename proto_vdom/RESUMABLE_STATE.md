# Resumable State (Qwik-like State Serialization)

このライブラリは、Qwikのような状態のシリアライズと復元をサポートしています。これにより、SSRで生成されたHTMLと一緒に状態を送信し、クライアント側で復元できます。

**注意**: 状態のシリアライズ機能は**JavaScriptバックエンド専用**です（`hooks_serialization_js.mbt`）。コアフック機能（`hooks.mbt`）はバックエンド非依存です。

## 概要

1. **SSR側**: 状態をシリアライズしてHTMLに埋め込み
2. **クライアント側**: HTMLから状態を抽出して復元
3. **ハイドレーション**: 復元された状態を使って、再計算なしにUIを復元

## 利点

- **初期表示の高速化**: クライアント側で状態を再計算する必要がない
- **帯域幅の削減**: 必要最小限の状態のみを転送
- **一貫性**: サーバーとクライアントで同じ状態を保証

## 使用方法

### 1. SSR側: 状態を埋め込んだHTMLの生成

```moonbit
// フック状態を作成
let hooks_state = HooksState::new()
set_current_hooks_state(Some(hooks_state))

// コンポーネントをレンダリング（フック内で状態を作成）
let (count, _) = use_state(0)
let (name, _) = use_state("Alice")

// VNodeを作成
let vnode = div([], [
  text("Count: " + count.to_string()),
  text(", Name: " + name)
])

// 状態を埋め込んだHTMLを生成
let html = render_to_string_with_state(vnode, hooks_state)

// 結果:
// <div>Count: 0, Name: Alice</div>
// <script type="application/json" data-hooks-state>[0,"Alice"]</script>
```

### 2. クライアント側: 状態の復元とハイドレーション

```moonbit
// DOM準備
let container = document().getElementById("app").unwrap()

// フック状態を作成
let hooks_state = HooksState::new()
set_current_hooks_state(Some(hooks_state))

// 同じコンポーネント構造でVNodeを作成（初期値は無視される）
let (count, set_count) = use_state(0)  // 0は無視され、復元された値が使われる
let (name, set_name) = use_state("")   // ""は無視される

let vnode = div([], [
  text("Count: " + count.to_string()),
  text(", Name: " + name)
])

// レンダラーを作成
let renderer = DomRenderer::new(container)

// 状態を復元しながらハイドレーション
renderer.hydrate_with_state(vnode, hooks_state)

// この時点で、count = 0, name = "Alice" が復元されている
// DOMは再利用され、イベントハンドラーが追加される
```

### 3. 手動での状態シリアライズ/復元

```moonbit
// シリアライズ (JavaScript backend)
let json = hooks_state.serialize_js()
// => "[0,\"Alice\"]"

// 新しい状態を作成して復元 (JavaScript backend)
let new_state = HooksState::from_json(json)

// または、既存の状態に復元 (JavaScript backend)
hooks_state.restore_from_json(json)
```

### 4. HTMLから状態を抽出

```moonbit
let html = "<div>Content</div><script type=\"application/json\" data-hooks-state>[1,2,3]</script>"

match extract_state_from_html(html) {
  Some(state_json) => {
    println(state_json)  // => "[1,2,3]"
    let restored = HooksState::from_json(state_json)
  }
  None => println("No state found")
}
```

## 完全な例: カウンターアプリ

### SSR (server.mbt)

```moonbit
fn render_counter_ssr(initial_count : Int) -> String {
  let hooks_state = HooksState::new()
  set_current_hooks_state(Some(hooks_state))

  // カウンター状態を初期化
  let (count, _) = use_state(initial_count)

  // UI構築
  let vnode = div([], [
    h1([], [text("Counter: " + count.to_string())]),
    button([on_click(fn(_) { /* SSRでは無視 */ })], [text("+")])
  ])

  // 状態付きHTMLを生成
  let html = render_to_string_with_state(vnode, hooks_state)

  set_current_hooks_state(None)
  html
}
```

### クライアント (client.mbt)

```moonbit
fn hydrate_counter() {
  let container = document().getElementById("app").unwrap()

  let hooks_state = HooksState::new()
  set_current_hooks_state(Some(hooks_state))

  // 同じ構造（初期値は復元された値に上書きされる）
  let (count, set_count) = use_state(0)

  let vnode = div([], [
    h1([], [text("Counter: " + count.to_string())]),
    button([on_click(fn(_) { set_count(count + 1) })], [text("+")])
  ])

  let renderer = DomRenderer::new(container)
  renderer.hydrate_with_state(vnode, hooks_state)

  // この時点でcountはSSRで設定された値に復元され、
  // ボタンのクリックハンドラーが有効になっている
}
```

## 制限事項

### シリアライズ可能な値

- ✅ プリミティブ型: `Int`, `String`, `Bool`, `Float`
- ✅ 配列: `Array[T]` (Tがシリアライズ可能なら)
- ✅ Option: `T?` (Tがシリアライズ可能なら)
- ✅ タプル: `(T1, T2, ...)` (全てシリアライズ可能なら)
- ❌ 関数/クロージャ
- ❌ DOM参照
- ❌ ネイティブオブジェクト

### フックの制約

- `useState`: ✅ 状態値はシリアライズ可能
- `useRef`: ✅ 参照値がシリアライズ可能なら
- `useMemo`: ✅ 計算結果がシリアライズ可能なら
- `useEffect`: ❌ エフェクト関数は保存されない（依存配列のみ）
- `useCallback`: ❌ 関数は保存されない

## ベストプラクティス

1. **同じフック順序を保つ**: SSRとクライアントで同じ順序でフックを呼ぶ
2. **シンプルな状態**: 複雑なオブジェクトより、プリミティブ値を優先
3. **セキュリティ**: 状態に機密情報を含めない（クライアントに送信されるため）
4. **サイズ最適化**: 必要最小限の状態のみを保存

## ファイル構成

状態のシリアライズ機能は以下のファイルに分離されています：

- **`hooks.mbt`** - コアフック機能（バックエンド非依存）
  - `useState`, `useEffect`, `useMemo`, `useCallback`, `useRef`
  - `HooksState` 構造体とその基本メソッド
  - シリアライズ機能は**含まない**

- **`hooks_serialization_js.mbt`** - JavaScriptバックエンド専用
  - `HooksState::serialize_js()` - JSON文字列への変換
  - `HooksState::from_json()` - JSON文字列からの復元
  - `HooksState::restore_from_json()` - 既存状態の更新
  - `@json` パッケージに依存

- **`renderer_ssr.mbt`** - SSRレンダラー
  - `render_to_string_with_state()` - 状態埋め込みHTML生成
  - `extract_state_from_html()` - HTMLから状態抽出

- **`renderer_dom.mbt`** - DOMレンダラー
  - `DomRenderer::hydrate_with_state()` - 状態復元付きハイドレーション

この設計により、将来的なNativeバックエンドやWASMバックエンドへの対応が容易になります。

## 内部実装

状態は以下のように変換されます：

```moonbit
// フック呼び出し
use_state(42)        // => hooks[0] = 42
use_state("hello")   // => hooks[1] = "hello"
use_ref(Some(100))   // => hooks[2] = MutRef { value: Some(100) }

// シリアライズ後のJSON
[42, "hello", {"value": 100}]

// HTMLに埋め込まれる形
<script type="application/json" data-hooks-state>
[42,"hello",{"value":100}]
</script>
```

## トラブルシューティング

### 状態が復元されない

- SSRとクライアントで同じ順序でフックを呼んでいるか確認
- フックの数が一致しているか確認

### ハイドレーションミスマッチ

- VNodeの構造が完全に一致しているか確認
- 条件分岐でフックを呼んでいないか確認

### スクリプトタグが見つからない

- `render_to_string_with_state`を使っているか確認
- HTMLが正しく送信されているか確認
