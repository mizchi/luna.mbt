# @mizchi/luna-loader

Luna Island Architecture 用の軽量ローダー。

## サイズ

| ファイル | サイズ |
|---------|--------|
| dist/loader.js | ~2.3KB |
| dist/wc-loader.js | ~2.4KB |
| dist/sol-nav.js | ~3.1KB |

### 機能別サイズ内訳（概算）

全機能を含めた状態で約1.4KB。各機能を削除した場合の削減量：

| 機能 | 削減量 | 説明 |
|------|--------|------|
| MutationObserver | ~170B | 動的追加要素の自動検出 |
| media trigger | ~150B | `luna:client-trigger="media:(query)"` |
| luna/json preload | ~70B | `<script type="luna/json">` の事前読み込み |
| url: state fetch | ~60B | `luna:state="url:/api/state"` |
| luna:export | ~50B | カスタム export 名指定 |

全て削除すると約936Bまで削減可能。

## 属性

| 属性 | 必須 | 説明 |
|------|------|------|
| `luna:id` | Yes | Island の一意識別子 |
| `luna:url` | Yes | Hydration モジュールの URL |
| `luna:client-trigger` | No | Hydration トリガー (default: `load`) |
| `luna:state` | No | 状態の取得方法 |
| `luna:export` | No | モジュールの export 名 |

### luna:client-trigger

| 値 | 説明 |
|----|------|
| `load` | DOMContentLoaded 時に即座に hydrate |
| `idle` | `requestIdleCallback` で hydrate |
| `visible` | IntersectionObserver で viewport 進入時に hydrate |
| `media:(query)` | メディアクエリマッチ時に hydrate |
| `none` | 自動 hydrate なし（手動で `__LUNA_HYDRATE__` を呼ぶ） |

### luna:state

| 形式 | 説明 |
|------|------|
| `#id` | `<script type="luna/json" id="...">` を参照 |
| `url:/path` | URL から fetch して JSON として解析 |
| `{...}` | インライン JSON |

## Public API

```js
window.__LUNA_STATE__    // { [id]: state } - 全 Island の状態
window.__LUNA_HYDRATE__  // (el) => Promise - 手動 hydrate
window.__LUNA_SCAN__     // () => void - 再スキャン
```

## 使用例

```html
<!-- State を script タグで定義 -->
<script type="luna/json" id="counter-state">{"count":0}</script>

<!-- Island 要素 -->
<div luna:id="counter" luna:url="./counter.js" luna:state="#counter-state" luna:client-trigger="visible">
  <span>0</span>
  <button>+1</button>
</div>
```

```js
// counter.js
export function hydrate(el, state, id) {
  // el: DOM 要素
  // state: { count: 0 }
  // id: "counter"
}
```
