# js/luna 改善提案

feedback-v2.md からの JS 側実装提案。Tree-shaking を考慮し、使わない機能はバンドルに含まれないようにする。

## 現状の課題

### 1. index.ts が肥大化

現在 `js/luna/src/index.ts` は 800行以上あり、以下が混在：

- MoonBit API の re-export
- SolidJS 互換ラッパー（createSignal, createEffect 等）
- コンポーネント（For, Show, Switch, Match, Portal 等）
- ユーティリティ（mergeProps, splitProps, on 等）
- Store API（createStore, produce, reconcile）
- Router API

### 2. Tree-shaking の問題

すべてが1ファイルからエクスポートされているため、使わない機能も含まれやすい。

---

## 提案: モジュール分割

```
js/luna/src/
├── index.ts           # メインエントリ（re-export のみ）
├── signal.ts          # Signal API (createSignal, createEffect, createMemo)
├── components.ts      # コンポーネント (For, Show, Switch, Match, Portal)
├── utils.ts           # ユーティリティ (mergeProps, splitProps, on)
├── store.ts           # Store API (createStore, produce, reconcile)
├── router.ts          # Router API
├── resource.ts        # Resource API (createResource, createDeferred)
└── event-utils.ts     # NEW: イベントユーティリティ
```

### メリット

1. **Tree-shaking**: 使わないモジュールはバンドルから除外
2. **可読性**: 機能ごとにファイル分割
3. **テスト容易性**: モジュール単位でテスト可能

---

## 新規追加: event-utils.ts

feedback-v2.md の提案 1B を JS 側で実装。

```typescript
// js/luna/src/event-utils.ts

/**
 * Get input/textarea value from event target
 */
export function getTargetValue(e: Event): string {
  return (e.target as HTMLInputElement)?.value ?? "";
}

/**
 * Get client position from mouse/pointer event
 */
export function getClientPos(e: MouseEvent | PointerEvent): { x: number; y: number } {
  return { x: e.clientX, y: e.clientY };
}

/**
 * Get offset position (relative to element) from mouse/pointer event
 */
export function getOffsetPos(e: MouseEvent | PointerEvent): { x: number; y: number } {
  return { x: e.offsetX, y: e.offsetY };
}

/**
 * Get data attribute from event target or closest ancestor
 */
export function getDataAttr(e: Event, key: string): string | null {
  const target = e.target as HTMLElement;
  return target?.closest(`[data-${key}]`)?.getAttribute(`data-${key}`) ?? null;
}

/**
 * Get data-id from closest ancestor (common pattern)
 */
export function getDataId(e: Event): string | null {
  return getDataAttr(e, "id");
}

/**
 * Prevent default and stop propagation
 */
export function stopEvent(e: Event): void {
  e.preventDefault();
  e.stopPropagation();
}

/**
 * Check if IME is composing (for input events)
 */
export function isComposing(e: InputEvent | KeyboardEvent): boolean {
  return e.isComposing ?? false;
}
```

### 使用例

```typescript
import { getTargetValue, getDataId, stopEvent, isComposing } from "@luna_ui/luna/event-utils";

// Input handling
on=events().input(fn(e) {
  if (!isComposing(e)) {
    const value = getTargetValue(e);
    setValue(value);
  }
})

// Click with data-id
on=events().click(fn(e) {
  const id = getDataId(e);
  if (id) {
    selectItem(id);
  }
})
```

---

## 新規追加: IME 対応コンポーネント

feedback-v2.md の提案 3 を実装。

```typescript
// js/luna/src/ime.ts

import { createSignal, createEffect } from "./signal";

interface IMEInputProps {
  value: () => string;
  onCommit: (value: string) => void;
  onCancel?: () => void;
  placeholder?: string;
  class?: string;
  style?: string;
  autoFocus?: boolean;
}

/**
 * IME-aware input component
 * Only calls onCommit when:
 * - Enter is pressed (outside IME composition)
 * - Blur occurs
 */
export function IMEInput(props: IMEInputProps) {
  let inputRef: HTMLInputElement | null = null;
  let isComposing = false;

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter" && !isComposing) {
      e.preventDefault();
      props.onCommit(inputRef?.value ?? "");
    }
    if (e.key === "Escape") {
      props.onCancel?.();
    }
  };

  return createElement("input", [
    ["type", { $tag: 0, _0: "text" }],
    ["value", { $tag: 1, _0: props.value }],
    ["placeholder", { $tag: 0, _0: props.placeholder ?? "" }],
    ["class", { $tag: 0, _0: props.class ?? "" }],
    ["style", { $tag: 0, _0: props.style ?? "" }],
    ["compositionstart", { $tag: 2, _0: () => { isComposing = true; } }],
    ["compositionend", { $tag: 2, _0: () => { isComposing = false; } }],
    ["keydown", { $tag: 2, _0: handleKeyDown }],
    ["blur", { $tag: 2, _0: () => props.onCommit(inputRef?.value ?? "") }],
    ["__ref", { $tag: 2, _0: (el) => {
      inputRef = el;
      if (props.autoFocus) el.focus();
    }}],
  ], []);
}

/**
 * IME-aware textarea component
 * Supports multiline input with IME
 */
export function IMETextArea(props: IMEInputProps & { rows?: number }) {
  // Similar implementation with textarea
}
```

---

## 既存コードの改善

### 1. Switch/Match の最適化（完了済み）

ab1dacc で修正済み。`createMemo` + `show` でリアクティブ化。

### 2. createStore の軽量化

現在の `createStore` は Proxy ベースで複雑。シンプルなユースケース向けに軽量版を提供：

```typescript
// 軽量版: ネストなしの単純なオブジェクト用
export function createSimpleStore<T extends object>(initial: T): [() => T, (partial: Partial<T>) => void] {
  const [state, setState] = createSignal(initial);
  const update = (partial: Partial<T>) => setState((prev) => ({ ...prev, ...partial }));
  return [state, update];
}
```

### 3. Router の分離

Router は使わないプロジェクトも多いため、別エントリポイントに：

```typescript
// js/luna/src/router.ts
export { createRouter, routerNavigate, routerReplace, routerGetPath, routerGetMatch, routerGetBase };
export { routePage, routePageTitled, routePageFull };
```

---

## 実装優先度

| 優先度 | タスク | 理由 |
|--------|--------|------|
| 高 | event-utils.ts 追加 | よく使うパターンを簡略化 |
| 中 | モジュール分割 | Tree-shaking 改善 |
| 中 | IME コンポーネント | 日本語入力対応 |
| 低 | createSimpleStore | 軽量版 Store |

---

## 互換性

- すべての変更は後方互換
- index.ts からの re-export は維持
- 新しいインポートパスは追加オプション

```typescript
// 既存（引き続き動作）
import { createSignal, For, Show } from "@luna_ui/luna";

// 新規（tree-shaking 最適化）
import { createSignal } from "@luna_ui/luna/signal";
import { For, Show } from "@luna_ui/luna/components";
import { getTargetValue } from "@luna_ui/luna/event-utils";
```
