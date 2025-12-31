# Sol Type-Safe Islands

静的解析可能で型安全な Island Architecture の設計。

## 設計原則

1. **コンパイル時検証**: 存在しない hydration スクリプトの参照はビルドエラー
2. **型付き Props/State**: SSR と Hydration で同じ型定義を共有
3. **IDE 補完**: コンポーネント名、props、trigger の補完が効く
4. **文字列リテラル排除**: マジックストリングを型で置き換え
5. **Dual Language Types**: TypeScript と MoonBit の型を同時生成・同時運用

## アーキテクチャ

```
    ┌─────────────────┐           ┌─────────────────┐
    │ MoonBit Source  │    OR     │ TypeScript Src  │
    │ (*.mbt)         │           │ (*.tsx)         │
    └────────┬────────┘           └────────┬────────┘
             │                              │
             └──────────────┬───────────────┘
                            ▼
                  ┌─────────────────────┐
                  │   Parse & Extract   │
                  │   → IR (中間表現)   │
                  └──────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
    ┌─────────────────┐ ┌─────────┐ ┌─────────────────┐
    │ MoonBit Types   │ │Manifest │ │ TypeScript Types│
    │ (generated.mbt) │ │(islands)│ │ (generated.ts)  │
    └────────┬────────┘ └────┬────┘ └────────┬────────┘
             │               │               │
             ▼               │               ▼
    ┌─────────────────┐      │      ┌─────────────────┐
    │ MoonBit SSR     │◀─────┴─────▶│ TypeScript      │
    │ (render)        │             │ Hydration       │
    └─────────────────┘             └─────────────────┘
```

**型の流れ:**
- ソースコード（MoonBit or TypeScript）を構文解析
- IR を経由して両言語の型を同時生成
- SSR と Hydration で同じ Props/State 型を使用

## 0. Type Extraction from Source Code

独自スキーマを定義せず、MoonBit または TypeScript のソースコードを構文解析して型を抽出。

### アプローチ

```
┌─────────────────────────────────────────────────────────────────┐
│                    Source Code (User writes)                     │
│                                                                   │
│  ┌─────────────────────────┐   ┌─────────────────────────────┐  │
│  │ MoonBit                 │   │ TypeScript                  │  │
│  │ pub struct SwitchProps  │ OR│ interface SwitchProps       │  │
│  │ pub fn switch_island()  │   │ export const Switch = ...   │  │
│  └───────────┬─────────────┘   └───────────────┬─────────────┘  │
│              │                                  │                │
└──────────────┼──────────────────────────────────┼────────────────┘
               │                                  │
               ▼                                  ▼
        ┌─────────────────────────────────────────────┐
        │              IR (中間表現)                   │
        │  {                                          │
        │    name: "switch-demo",                     │
        │    props: { checked: Bool, label: String }, │
        │    hydrate: "./switch.hydrate.ts",          │
        │    trigger: "visible"                       │
        │  }                                          │
        └──────────────────┬──────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌────────────┐   ┌────────────┐   ┌────────────┐
   │ MoonBit    │   │ TypeScript │   │ Manifest   │
   │ Types      │   │ Types      │   │ (runtime)  │
   └────────────┘   └────────────┘   └────────────┘
```

### MoonBit as Source

```moonbit
// src/components/switch.mbt

/// Props 定義（これを構文解析して抽出）
pub struct SwitchProps {
  checked : Bool
  disabled : Bool
  label : String
} derive(Serialize)

/// Island 定義（マーカーアノテーションで検出）
///| @island(name="switch-demo", hydrate="./switch.hydrate.ts", trigger=visible)
pub fn switch_island(props : SwitchProps) -> @luna.Node[Unit] {
  // ...
}
```

**抽出される情報:**
- `SwitchProps` の構造体定義 → IR に変換
- `@island` アノテーション → Island メタデータ

### TypeScript as Source

```typescript
// src/components/switch.tsx

/** Props 定義（これを構文解析して抽出） */
export interface SwitchProps {
  checked: boolean;
  disabled?: boolean;
  label: string;
}

/** Island 定義 */
export const Switch = defineIsland<SwitchProps>({
  name: 'switch-demo',
  hydrate: './switch.hydrate.ts',
  trigger: 'visible',
  render: (props) => (
    <button data-switch-toggle aria-checked={props.checked}>
      {props.label}
      <span data-switch-thumb />
    </button>
  ),
});
```

**抽出される情報:**
- `SwitchProps` の interface 定義 → IR に変換
- `defineIsland()` の引数 → Island メタデータ

### IR (中間表現)

```typescript
// 内部形式（ユーザーには見えない）
interface IslandIR {
  name: string;
  propsType: TypeIR;
  hydrate: string;
  trigger: 'load' | 'visible' | 'idle' | { media: string };
  sourceFile: string;
  sourceLang: 'moonbit' | 'typescript';
}

interface TypeIR {
  kind: 'struct' | 'interface';
  name: string;
  fields: Array<{
    name: string;
    type: TypeRef;
    optional: boolean;
    default?: unknown;
  }>;
}
```

### Generated: MoonBit Types (from TypeScript source)

TypeScript を Source にした場合、MoonBit 型が生成される:

```moonbit
// generated/islands.mbt (自動生成 from TypeScript)

/// Generated from src/components/switch.tsx
pub struct SwitchProps {
  checked : Bool
  disabled : Bool  // optional, default false
  label : String
} derive(Serialize, Deserialize)
```

### Generated: TypeScript Types (from MoonBit source)

MoonBit を Source にした場合、TypeScript 型が生成される:

```typescript
// generated/islands.ts (自動生成 from MoonBit)

/** Generated from src/components/switch.mbt */
export interface SwitchProps {
  checked: boolean;
  disabled?: boolean;
  label: string;
}

/** Island manifest */
export const islands = {
  'switch-demo': {
    hydrate: () => import('./components/switch.hydrate'),
    trigger: 'visible' as const,
  },
} as const;

export type IslandName = keyof typeof islands;
```

## 1. Component Definition (MoonBit)

```moonbit
// src/components/switch.mbt

// 生成された型をインポート
// SwitchProps は generated/islands.mbt から来る

/// SSR レンダリング（型は自動生成された SwitchProps を使用）
pub fn render_switch(props : @generated.SwitchProps) -> @luna.Node[Unit] {
  @luna.h("button", [
    ("data-switch-toggle", @luna.attr_static("")),
    ("aria-checked", @luna.attr_static(props.checked.to_string())),
    ("aria-disabled", @luna.attr_static(props.disabled.to_string())),
  ], [
    @luna.text(props.label),
    @luna.h("span", [("data-switch-thumb", @luna.attr_static(""))], []),
  ])
}

/// Island ラッパー（型安全な props 渡し）
pub fn switch_island(props : @generated.SwitchProps) -> @luna.Node[Unit] {
  @sol.island(
    name="switch-demo",  // islands.schema.json で定義済み
    props,               // JSON シリアライズして data 属性に埋め込み
    render_switch(props),
  )
}
```

**ポイント:**
- Props 型は `generated/islands.mbt` から来る（手書き不要）
- `@sol.island()` が Island ラッパーを生成
- スキーマで定義済みの name のみ使用可能（typo 防止）

## 2. Hydration Script (TypeScript)

生成された型を使って Hydration を実装:

```typescript
// src/components/switch.hydrate.ts

import { defineHydrator } from '@luna/sol';
// 生成された型をインポート
import type { SwitchProps } from '../generated/islands';

export default defineHydrator<SwitchProps>({
  // props の型が推論される
  setup(element, props) {
    // element は型付き
    const toggle = element.querySelector<HTMLButtonElement>('[data-switch-toggle]');
    if (!toggle) return;

    const handleClick = () => {
      const checked = toggle.getAttribute('aria-checked') !== 'true';
      toggle.setAttribute('aria-checked', String(checked));
    };

    toggle.addEventListener('click', handleClick);

    // cleanup を返す
    return () => {
      toggle.removeEventListener('click', handleClick);
    };
  },
});
```

## 4. Hydration Manifest (Generated)

ビルド時に生成される Island マニフェスト:

```typescript
// generated/islands.manifest.ts (自動生成)

export const islands = {
  'switch-demo': {
    hydrate: () => import('../components/switch.hydrate'),
    propsSchema: { /* JSON Schema */ },
  },
  'accordion-demo': {
    hydrate: () => import('../components/accordion.hydrate'),
    propsSchema: { /* JSON Schema */ },
  },
} as const;

export type IslandName = keyof typeof islands;
```

## 5. Usage in MDX

### Option A: Import + Component (推奨)

```mdx
---
title: Switch Demo
---

import { Switch } from '@components/switch'

# Switch

{/* 型チェック済み、IDE補完あり */}
<Switch checked={true} disabled={false} label="Enable notifications" />
```

コンパイル時に:
- `Switch` コンポーネントの存在を検証
- `checked`, `disabled`, `label` の型を検証
- hydration スクリプトの存在を検証

### Option B: Raw HTML with Validation

型安全な HTML ヘルパー:

```typescript
// mdx-components.ts
import { islands } from './generated/islands.manifest';

export function createIsland<T extends IslandName>(
  name: T,
  props: IslandProps[T],
  trigger: Trigger = 'visible'
): string {
  // ビルド時に props の型チェック
  return `<${name} luna:wc-props='${JSON.stringify(props)}' luna:wc-trigger="${trigger}">
    ${islands[name].render(props)}
  </${name}>`;
}
```

## 6. Trigger Types

```typescript
// @luna/sol/types.ts

export type Trigger =
  | 'load'      // 即座に読み込み
  | 'visible'   // IntersectionObserver
  | 'idle'      // requestIdleCallback
  | { media: string }  // メディアクエリ

// MoonBit 側
pub enum Trigger {
  Load
  Visible
  Idle
  Media(String)
}
```

## 7. Build Pipeline

```
Source Files (*.mbt, *.tsx)
     │
     ▼
┌─────────────────────┐
│ Parse & Extract     │  ← 構文解析して Island 定義を抽出
│ - MoonBit: struct + @island annotation
│ - TypeScript: interface + defineIsland()
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│ Generate IR         │  ← 中間表現を生成
└─────────────────────┘
     │
     ├──────────────────────────────────────┐
     ▼                                      ▼
┌─────────────────────┐          ┌─────────────────────┐
│ Generate MoonBit    │          │ Generate TypeScript │
│ (generated/         │          │ (generated/         │
│  islands.mbt)       │          │  islands.ts)        │
│ ※TS source の場合   │          │ ※MBT source の場合  │
└─────────────────────┘          └─────────────────────┘
     │                                      │
     ▼                                      ▼
┌─────────────────────┐          ┌─────────────────────┐
│ MoonBit Check       │          │ TypeScript Check    │
│ (moon check)        │          │ (tsc --noEmit)      │
└─────────────────────┘          └─────────────────────┘
     │                                      │
     └──────────────────┬───────────────────┘
                        ▼
              ┌─────────────────────┐
              │ Validate Hydration  │  ← hydrate パスの存在確認
              │ Scripts Exist       │
              └─────────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │ MoonBit Build       │  ← SSR renderer
              └─────────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │ Bundle Islands      │  ← 各 Island を個別チャンクに
              └─────────────────────┘
```

**コマンド:**
```bash
# 型生成（ソースを構文解析）
sol generate    # src/**/*.{mbt,tsx} → generated/{islands.mbt, islands.ts}

# ビルド
sol build       # 型生成 + Check + SSR Build + Bundle

# Watch モード（ソース変更で自動再生成）
sol dev         # 型の自動再生成 + HMR
```

**設定 (sol.config.json):**
```json
{
  "islands": {
    "source": ["src/components/**/*.mbt", "src/components/**/*.tsx"],
    "generated": "./generated",
    "hydrate": "./src/hydrate"
  }
}
```

## 8. Error Messages

**コンパイル時エラー:**

```
error[SOL001]: Hydration script not found
  --> src/components/switch.mbt:8:5
   |
 8 |     hydrate="./switch.hydrate.ts",
   |             ^^^^^^^^^^^^^^^^^^^^^^ file does not exist
   |
   = help: create the file at 'src/components/switch.hydrate.ts'
```

```
error[SOL002]: Props type mismatch
  --> pages/demo.mdx:15:1
   |
15 | <Switch checked="yes" />
   |         ^^^^^^^^^^^^^^ expected boolean, got string
   |
   = note: SwitchProps.checked is defined as Bool in switch.mbt:4
```

```
error[SOL003]: Missing required prop
  --> pages/demo.mdx:15:1
   |
15 | <Switch checked={true} />
   |         ^^^^^^^^^^^^^^^^ missing required prop 'label'
   |
   = note: SwitchProps requires: checked, disabled, label
```

## 9. defineHydrator API

```typescript
// @luna/sol

export interface HydratorConfig<Props> {
  /**
   * Setup function called on hydration
   * @param element - Root element of the island
   * @param props - Typed props from SSR
   * @returns Optional cleanup function
   */
  setup(element: HTMLElement, props: Props): void | (() => void);

  /**
   * Optional: validate props at runtime (development only)
   */
  validate?: (props: unknown) => props is Props;
}

export function defineHydrator<Props>(
  config: HydratorConfig<Props>
): (element: Element, props: Props, name: string) => void {
  return (element, props, name) => {
    if (element.dataset.hydrated) return;
    element.dataset.hydrated = 'true';

    const cleanup = config.setup(element as HTMLElement, props);

    // SPA navigation cleanup
    if (cleanup) {
      (element as any).__luna_cleanup = cleanup;
    }
  };
}
```

## 10. 型安全な属性操作

```typescript
// @luna/sol/attributes.ts

/** Type-safe attribute toggle */
export function toggleState<T extends 'open' | 'closed'>(
  element: Element
): T {
  const current = element.getAttribute('data-state') as T;
  const next = current === 'open' ? 'closed' : 'open';
  element.setAttribute('data-state', next);
  return next as T;
}

/** Type-safe aria-checked toggle */
export function toggleChecked(element: Element): boolean {
  const checked = element.getAttribute('aria-checked') !== 'true';
  element.setAttribute('aria-checked', String(checked));
  return checked;
}

/** Type-safe data attribute access */
export function getData<T extends string>(
  element: HTMLElement,
  key: string
): T | undefined {
  return element.dataset[key] as T | undefined;
}
```

## Migration from Conventions

### Before (Convention-based)

```javascript
// components/switch-demo.js
export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;
  // 型なし、検証なし
}
```

### After (Type-safe)

```typescript
// components/switch.hydrate.ts
import { defineHydrator } from '@luna/sol';
import type { SwitchProps } from '../generated/switch.types';

export default defineHydrator<SwitchProps>({
  setup(element, props) {
    // 型あり、IDE補完あり
  },
});
```

## Checklist

- [ ] MoonBit で `@sol.define_island()` を使って Island 定義
- [ ] Props は `derive(Serialize, Deserialize)` で型情報を保持
- [ ] TypeScript で `defineHydrator<Props>()` を使って hydration 実装
- [ ] MDX で型付きコンポーネントとして使用
- [ ] ビルド時に全ての型チェックが通ることを確認
