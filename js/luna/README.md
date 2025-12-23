# @mizchi/luna

A lightweight reactive UI library with SolidJS-compatible API. Implemented in MoonBit.

## Documentation

- [API Reference](https://luna.mizchi.workers.dev/luna/api/js/)
- [Tutorial](https://luna.mizchi.workers.dev/luna/tutorial/js/)

## Installation

```bash
npm install @mizchi/luna
```

## Setup

### TypeScript + Vite

**tsconfig.json:**

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "jsxImportSource": "@mizchi/luna",
    "strict": true
  }
}
```

**vite.config.ts:**

```ts
import { defineConfig } from 'vite';

export default defineConfig({});
```

### esbuild

```ts
esbuild.build({
  jsx: 'automatic',
  jsxImportSource: '@mizchi/luna',
});
```

## Basic Usage

```tsx
import { createSignal, createMemo, render } from '@mizchi/luna';

function Counter() {
  const [count, setCount] = createSignal(0);
  const doubled = createMemo(() => count() * 2);

  return (
    <div>
      <p>Count: {count}</p>
      <p>Doubled: {doubled}</p>
      <button onClick={() => setCount(c => c + 1)}>+</button>
      <button onClick={() => setCount(c => c - 1)}>-</button>
      <button onClick={() => setCount(0)}>Reset</button>
    </div>
  );
}

render(document.getElementById('app')!, <Counter />);
```

## API

### Signal

```tsx
import { createSignal, createMemo, createEffect } from '@mizchi/luna';

// Signal: reactive value
const [count, setCount] = createSignal(0);
count();              // get value
setCount(5);          // set value
setCount(c => c + 1); // update with function

// Memo: derived value
const doubled = createMemo(() => count() * 2);

// Effect: side effects
createEffect(() => {
  console.log('Count changed:', count());
});
```

### Components

```tsx
import { For, Show } from '@mizchi/luna';

// For: list rendering
<For each={items}>
  {(item) => <li>{item.name}</li>}
</For>

// Show: conditional rendering
<Show when={() => isVisible()}>
  <div>Visible content</div>
</Show>
```

### Styles

```tsx
// Object syntax (camelCase → kebab-case auto-conversion)
<div style={{ backgroundColor: 'red', maxWidth: '600px' }}>
  styled content
</div>

// String syntax
<div style="color: blue; margin: 10px">
  styled content
</div>
```

### Event Handlers

```tsx
<button onClick={() => console.log('clicked')}>Click</button>
<input onInput={(e) => setValue(e.target.value)} />
<form onSubmit={(e) => { e.preventDefault(); submit(); }}>
```

## License

MIT
