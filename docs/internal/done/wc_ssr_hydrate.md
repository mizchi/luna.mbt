# Web Components SSR/Hydration 統合計画

Luna フレームワークに Web Components ベースの SSR/Hydration を統合する実装計画。

## 概要

現在の `ln:*` 属性ベースの Island アーキテクチャに加えて、Web Components (Declarative Shadow DOM) を使った `wc_*` 版を追加し、選択的に利用可能にする。

## 現状との比較

| 機能 | 現行 (ln:*) | 新規 (wc_*) |
|------|-------------|-------------|
| マーカー属性 | `ln:id`, `ln:url`, `ln:state`, `ln:trigger` | `<wc-*>` カスタム要素 |
| CSS カプセル化 | なし (グローバル) | Shadow DOM |
| イベントバインディング | `data-action-*` | `data-on-*` |
| 部分更新 | Signal + Effect | Signal + DOM Parts |
| ローダー | `ln-loader` (4.2KB) | `wc-loader` (新規) |
| SSR 出力 | `<div ln:id="...">` | `<wc-counter><template shadowrootmode="open">...</template></wc-counter>` |

## アーキテクチャ

```
src/
├── core/
│   ├── vnode.mbt              # VNode 定義 (VWcIsland 追加)
│   └── serialize/             # 状態シリアライズ (共通)
├── renderer/
│   └── wc/                    # 新規: WC 向け SSR レンダラー
│       ├── render_wc.mbt      # WC HTML 生成
│       └── parts_marker.mbt   # DOM Parts マーカー出力
├── platform/
│   ├── dom/
│   │   ├── wc_island.mbt      # 新規: WC Island コンテキスト
│   │   └── wc_hydrate.mbt     # 新規: WC Hydration
│   └── server_dom/
│       └── wc_elements.mbt    # 新規: WC 要素ファクトリ
js/
├── wcssr/                     # ✅ 実装済み
│   ├── src/
│   │   ├── server.ts          # SSR ランタイム
│   │   ├── client.ts          # Hydration ランタイム
│   │   └── parts.ts           # DOM Parts ポリフィル
│   └── tests/
└── wc-loader/                 # 新規: WC 用ローダー
    └── src/
        └── loader.js
```

## 実装フェーズ

### Phase 1: MoonBit VNode 拡張

**目標**: VNode 型に Web Components 対応のバリアントを追加

**ファイル**: `src/core/vnode.mbt`

```moonbit
// 新規追加
pub struct VWcIsland[E] {
  name : String              // カスタム要素名 (e.g., "wc-counter")
  styles : String            // Shadow DOM 内 CSS
  state : String             // シリアライズされた状態 JSON
  trigger : IslandTrigger    // Hydration トリガー
  children : Array[Node[E]]  // SSR コンテンツ
}

pub enum Node[E] {
  // ... 既存 ...
  Island(VIsland[E])         // 現行 ln:* 方式
  WcIsland(VWcIsland[E])     // 新規 Web Components 方式
}
```

**タスク**:
- [ ] `VWcIsland` 構造体を定義
- [ ] `Node` enum に `WcIsland` バリアントを追加
- [ ] コンストラクタ関数 `vwc_island()` を追加

---

### Phase 2: SSR レンダラー (MoonBit)

**目標**: Web Components の Declarative Shadow DOM を出力

**ファイル**: `src/renderer/wc/render_wc.mbt`

```moonbit
pub fn render_wc_island[E](
  sb : StringBuilder,
  island : VWcIsland[E],
  render_children : (StringBuilder, Array[Node[E]]) -> Unit,
) -> Unit {
  // <wc-counter data-state="{...}" data-trigger="load">
  sb.write_string("<")
  sb.write_string(island.name)
  sb.write_string(" data-state=\"")
  escape_attr_to(sb, island.state)
  sb.write_string("\" data-trigger=\"")
  sb.write_string(trigger_to_string(island.trigger))
  sb.write_string("\">")

  // <template shadowrootmode="open">
  sb.write_string("<template shadowrootmode=\"open\">")

  // <style>...</style>
  sb.write_string("<style>")
  escape_html_to(sb, island.styles)
  sb.write_string("</style>")

  // 子コンテンツ
  render_children(sb, island.children)

  sb.write_string("</template></")
  sb.write_string(island.name)
  sb.write_string(">")
}
```

**DOM Parts マーカー出力** (`src/renderer/wc/parts_marker.mbt`):

```moonbit
// テキストノード用マーカー
pub fn render_text_part(sb : StringBuilder, name : String, value : String) -> Unit {
  sb.write_string("<!--{{")
  sb.write_string(name)
  sb.write_string("}}-->")
  escape_html_to(sb, value)
  sb.write_string("<!--/{{")
  sb.write_string(name)
  sb.write_string("}}-->")
}

// 属性用マーカー
pub fn render_attr_part(sb : StringBuilder, attr_name : String, part_name : String) -> Unit {
  sb.write_string(" data-part=\"")
  sb.write_string(attr_name)
  sb.write_char(':')
  sb.write_string(part_name)
  sb.write_char('"')
}
```

**タスク**:
- [ ] `render_wc.mbt` 新規作成
- [ ] `parts_marker.mbt` 新規作成
- [ ] `render_to_string.mbt` に `WcIsland` ケースを追加
- [ ] moon.pkg.json にモジュール追加

---

### Phase 3: サーバー側要素ファクトリ (MoonBit)

**目標**: `@server_dom.wc_island()` ヘルパー関数を提供

**ファイル**: `src/platform/server_dom/wc_elements.mbt`

```moonbit
/// Web Components Island を作成
pub fn wc_island(
  name : String,                      // カスタム要素名
  styles : String,                    // CSS
  state? : String,                    // 状態 JSON
  trigger? : @luna.IslandTrigger,     // トリガー
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.vwc_island(
    name,
    styles,
    state.unwrap_or("{}"),
    children,
    trigger=trigger.unwrap_or(@luna.Load),
  )
}

// トリガー別ショートカット
pub fn wc_island_load(...) -> @luna.Node[Unit]
pub fn wc_island_idle(...) -> @luna.Node[Unit]
pub fn wc_island_visible(...) -> @luna.Node[Unit]
```

**タスク**:
- [ ] `wc_elements.mbt` 新規作成
- [ ] `island.mbt` と同様のヘルパー関数群を追加

---

### Phase 4: クライアントローダー (JavaScript)

**目標**: Web Components 用の軽量ローダーを作成

**ファイル**: `js/wc-loader/src/loader.js`

```javascript
// wc-loader: Web Components Hydration Loader
(function(w, d) {
  const loaded = new Set();
  const Q = s => d.querySelectorAll(s);

  // カスタム要素を検索してセットアップ
  const scan = () => {
    Q('[data-wc-url]').forEach(setup);
  };

  // 状態をパース
  const parseState = el => {
    const s = el.dataset.state;
    if (!s) return {};
    try { return JSON.parse(s); } catch { return {}; }
  };

  // Hydration 実行
  const hydrate = async el => {
    const name = el.tagName.toLowerCase();
    if (loaded.has(name)) return;
    loaded.add(name);

    const url = el.dataset.wcUrl;
    if (!url) return;

    // コンポーネントモジュールをロード
    const mod = await import(url);
    const def = mod.default ?? mod[name];

    if (def && typeof def === 'object') {
      // wcssr の registerComponent を使用
      const { registerComponent } = await import('@luna_ui/wcssr/client');
      registerComponent(def);
    }
  };

  // トリガー設定
  const setup = el => {
    const t = el.dataset.trigger ?? 'load';
    if (t === 'load') {
      if (d.readyState === 'loading') {
        d.addEventListener('DOMContentLoaded', () => hydrate(el), { once: true });
      } else {
        hydrate(el);
      }
    } else if (t === 'idle') {
      requestIdleCallback(() => hydrate(el));
    } else if (t === 'visible') {
      new IntersectionObserver((entries, obs) => {
        if (entries[0].isIntersecting) {
          obs.disconnect();
          hydrate(el);
        }
      }).observe(el);
    }
  };

  // グローバル API
  w.__WC_SCAN__ = scan;
  w.__WC_HYDRATE__ = hydrate;

  scan();
})(window, document);
```

**タスク**:
- [ ] `js/wc-loader/` ディレクトリ作成
- [ ] `loader.js` 実装
- [ ] minify ビルド設定
- [ ] サイズ目標: < 2KB

---

### Phase 5: MoonBit クライアント統合

**目標**: MoonBit から wcssr の DOM Parts を利用

**ファイル**: `src/platform/dom/wc_island.mbt`

```moonbit
/// Web Components Island コンテキスト
pub struct WcIslandContext {
  element : @js_dom.Element
  shadow_root : @js_dom.ShadowRoot
  parts : @js.Any  // Map<string, Part>
}

pub fn WcIslandContext::new(element : @js_dom.Element) -> WcIslandContext? {
  let shadow = element.shadowRoot
  guard shadow is Some(root) else { return None }

  // DOM Parts を復元
  let parts = hydrate_parts_from_element_ffi(root)

  Some(WcIslandContext { element, shadow_root: root, parts })
}

/// Signal と Part を接続
pub fn WcIslandContext::bind_signal[T : Show](
  self : WcIslandContext,
  part_name : String,
  signal : @signal.Signal[T],
) -> Unit {
  let _ = @signal.effect(fn() {
    let value = signal.get().to_string()
    set_part_value_ffi(self.parts, part_name, value)
    commit_part_ffi(self.parts, part_name)
  })
}
```

**FFI 関数** (`src/platform/js/wc_ffi.mbt`):

```moonbit
// JS の wcssr 関数を呼び出す
extern "js" fn hydrate_parts_from_element_ffi(root : @js_dom.ShadowRoot) -> @js.Any =
  #| (root) => window.__WCSSR__.hydratePartsFromElement(root)

extern "js" fn set_part_value_ffi(parts : @js.Any, name : String, value : String) -> Unit =
  #| (parts, name, value) => { const p = parts.get(name); if(p) p.value = value; }

extern "js" fn commit_part_ffi(parts : @js.Any, name : String) -> Unit =
  #| (parts, name) => { const p = parts.get(name); if(p) p.commit(); }
```

**タスク**:
- [ ] `wc_island.mbt` 新規作成
- [ ] `wc_ffi.mbt` 新規作成
- [ ] wcssr の関数をグローバルに公開 (`window.__WCSSR__`)
- [ ] Signal と Part の接続ヘルパー

---

### Phase 6: サンプル実装

**目標**: 既存の Counter を Web Components 版で再実装

**サーバー側** (`examples/sol_app/app/server/wc_counter.mbt`):

```moonbit
pub fn wc_counter(props : @types.CounterProps) -> @luna.Node[Unit] {
  let state_json = props.to_json().stringify()

  @server_dom.wc_island(
    name="wc-counter",
    styles=":host { display: block; } .count { font-size: 2rem; }",
    state=state_json,
    trigger=@luna.Load,
    children=[
      div(class="count", [
        // DOM Parts マーカー付きテキスト
        @server_dom.text_part("count", props.initial_count.to_string()),
      ]),
      div(class="buttons", [
        button(class="dec", data_on_click="decrement", [text("-")]),
        button(class="inc", data_on_click="increment", [text("+")]),
      ]),
    ],
  )
}
```

**クライアント側** (`examples/sol_app/app/client/wc_counter.mbt`):

```moonbit
pub fn hydrate(el : @js_dom.Element, state : @js.Any) -> Unit {
  let ctx = @wc_island.WcIslandContext::new(el).unwrap()
  let initial_count = js_get_count(state)
  let count = @signal.signal(initial_count)

  // DOM Part と Signal を接続
  ctx.bind_signal("count", count)

  // イベントハンドラ
  ctx.bind_handler("increment", fn() { count.update(fn(n) { n + 1 }) })
  ctx.bind_handler("decrement", fn() { count.update(fn(n) { n - 1 }) })
}
```

**タスク**:
- [ ] `wc_counter.mbt` サーバー側実装
- [ ] `wc_counter.mbt` クライアント側実装
- [ ] ルーティングに追加 (`/wc-counter`)
- [ ] E2E テスト追加

---

## Phase 7: テスト

**目標**: 各層のテストを整備

| テスト種別 | ファイル | 内容 |
|-----------|---------|------|
| MoonBit Unit | `src/renderer/wc/*_test.mbt` | HTML 出力の検証 |
| Vitest Unit | `js/wcssr/src/*.test.ts` | ✅ 実装済み |
| Vitest Browser | `js/wcssr/tests/*.browser.test.ts` | ✅ 実装済み |
| E2E | `e2e/wc_*.test.ts` | SSR + Hydration 統合 |

**タスク**:
- [ ] `render_wc_test.mbt` 追加
- [ ] E2E テスト `wc_counter.test.ts` 追加

---

## マイルストーン

### M1: 基盤 (Phase 1-2)
- VNode 拡張
- SSR レンダラー
- **成果物**: MoonBit で WC の HTML 出力が可能

### M2: サーバー側完成 (Phase 3)
- 要素ファクトリ
- **成果物**: `@server_dom.wc_island()` が利用可能

### M3: クライアント側完成 (Phase 4-5)
- wc-loader
- MoonBit FFI 統合
- **成果物**: SSR → Hydration の一連の流れが動作

### M4: サンプル & テスト (Phase 6-7)
- Counter サンプル
- テスト整備
- **成果物**: プロダクション利用可能な状態

---

## 移行ガイドライン

### 既存コードとの共存

```moonbit
// 現行方式と新方式を混在可能
fn page() -> @luna.Node[Unit] {
  div([], [
    // 現行の ln:* 方式
    @server_dom.island(
      id="legacy-counter",
      url="/static/counter.js",
      ...
    ),

    // 新規の WC 方式
    @server_dom.wc_island(
      name="wc-counter",
      ...
    ),
  ])
}
```

### 選択基準

| ケース | 推奨方式 |
|--------|---------|
| CSS カプセル化が必要 | WC 方式 |
| 既存コードとの互換性重視 | ln:* 方式 |
| 部分更新の効率を重視 | WC 方式 (DOM Parts) |
| 外部配信 (Widget) | WC 方式 (自己完結) |
| MoonBit 完結 | ln:* 方式 |

---

## 参考資料

- [WICG DOM Parts Imperative](https://github.com/WICG/webcomponents/blob/gh-pages/proposals/DOM-Parts-Imperative.md)
- [WICG DOM Parts Declarative](https://github.com/WICG/webcomponents/blob/gh-pages/proposals/DOM-Parts-Declarative-Template.md)
- [Declarative Shadow DOM](https://web.dev/declarative-shadow-dom/)
- `js/wcssr/README.md` - 実装済みライブラリのドキュメント
- `experiments/webcomponents_ssr/README.md` - 実験結果
