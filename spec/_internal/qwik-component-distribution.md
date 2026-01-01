# Qwik コンポーネント配布モード調査

## 概要

Qwik の Resumability と Library Mode を Sol に採用できるか検討。

## Qwik の主要概念

### 1. QRL (Qwik Resource Locator)

イベントハンドラを URL + シンボル名として HTML 属性にシリアライズ:

```html
<button on:click="./chunk.js#handler_symbol">click me</button>
```

- クリック時に初めてチャンクをロード・実行
- **Qwikloader** (~1KB): グローバルイベントリスナーで全イベントを捕捉

### 2. Resumability（再開可能性）

- サーバーで「一時停止」→ クライアントで「再開」
- **Hydration 不要**: 状態・リアクティビティグラフを HTML にシリアライズ
- コンポーネント単位で独立して再開可能（親コンポーネント不要）

シリアライズ可能な型:
- DOM 参照、Date、URL、Map/Set
- Promise、関数クロージャ（QRL ラップ時）

シリアライズ不可:
- クラスインスタンス、ストリーム

### 3. Library Mode（ライブラリビルド）

```javascript
// vite.config.ts
build: {
  target: 'es2020',
  lib: {
    entry: './src/index.ts',
    formats: ['es', 'cjs'],
    fileName: (format) => `index.qwik.${format === 'es' ? 'mjs' : 'cjs'}`
  }
}
```

- ファイル名は **必ず `.qwik.mjs`** にする（Optimizer が認識）
- `package.json` に `"qwik": "./lib/index.qwik.mjs"` エントリ必須

### 4. qwikify$（他フレームワーク統合）

```javascript
import { qwikify$ } from '@builder.io/qwik-react';

export const MUIButton = qwikify$(ReactMUIButton, {
  eagerness: 'visible'  // 'load' | 'hover' | 'idle' | 'visible'
});
```

React/Vue/Angular コンポーネントを Qwik Island としてラップ。

### 5. Qwik 2.0 の改善

- 仮想ノードを HTML ストリーム末尾に移動 → UI 描画高速化
- コメントノード削除 → HTML 軽量化
- Lazy Virtual Nodes → 必要時のみノード生成
- 新パッケージ名: `@qwik.dev/core`, `@qwik.dev/router`

## Sol との比較

| 機能 | Qwik | Sol (現状) | 差分 |
|------|------|-----------|------|
| Island Hydration | QRL + Qwikloader | `luna:wc-url` + loader.js | 類似 |
| 状態シリアライズ | HTML 内に完全シリアライズ | 属性ベース (`data-*`, `aria-*`) | Qwik が高度 |
| イベントハンドラ | QRL 形式で遅延ロード | JS ファイルを動的 import | 類似 |
| 他フレームワーク統合 | qwikify$ | 未対応 | 要検討 |
| ライブラリ配布 | `.qwik.mjs` 形式 | 未対応 | 要設計 |

## 採用可能な機能

### Phase 1: QRL 風イベント属性

```html
<!-- 現在 -->
<switch-demo luna:wc-url="/components/switch-demo.js" luna:wc-trigger="visible">

<!-- QRL 風（提案） -->
<button luna:click="./switch.js#toggle" luna:trigger="visible">
```

- イベント単位で遅延ロード
- 複数イベントを別チャンクに分割可能

### Phase 2: 状態シリアライズ強化

```html
<!-- 現在: 属性ベース -->
<button aria-checked="true" data-state="open">

<!-- Qwik 風: HTML 末尾にまとめて埋め込み -->
<script type="luna/state">
{"components":{"switch-1":{"checked":true}}}
</script>
```

### Phase 3: ライブラリ配布モード

```json
// package.json
{
  "main": "./lib/index.luna.mjs",
  "luna": "./lib/index.luna.mjs",
  "types": "./lib-types/index.d.ts"
}
```

- `.luna.mjs` 形式でコンポーネントを npm 配布
- ビルド時に Optimizer がチャンク分割

## 課題

1. **MoonBit → WASM**: Qwik は JS 前提、Sol は WASM + JS ハイブリッド
2. **シリアライズ複雑性**: クロージャ・Promise のシリアライズは高度な実装が必要
3. **Loader 拡張**: 現在の loader.js (2KB) に QRL パース機能を追加

## 結論

**段階的に採用可能**。

1. まず QRL 風のイベント属性形式を検討（loader.js 拡張）
2. 状態シリアライズは現在の属性ベースで十分なケースが多い
3. ライブラリ配布は将来的に対応

## 参考

- [Component library | Qwik Documentation](https://qwik.dev/docs/advanced/library/)
- [Resumable | Qwik Documentation](https://qwik.dev/docs/concepts/resumable/)
- [Towards Qwik 2.0](https://www.builder.io/blog/qwik-2-coming-soon)
