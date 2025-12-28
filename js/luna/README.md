# @luna_ui/luna

A lightweight reactive UI library with SolidJS-Like API. Implemented in MoonBit.

## Documentation

- [API Reference](https://luna.mizchi.workers.dev/luna/api/js/)
- [Tutorial](https://luna.mizchi.workers.dev/luna/tutorial/js/)

## Quick Start

```bash
# Create a new TSX project
npx @luna_ui/luna new myapp
cd myapp
npm install
npm run dev

# Or create a MoonBit project
npx @luna_ui/luna new myapp --mbt
cd myapp
moon update
npm install
npm run dev
```

## Manual Setup

### Installation

```bash
npm install @luna_ui/luna
```

### TypeScript + Vite

**tsconfig.json:**

```json
{
  "compilerOptions": {
    "jsxImportSource": "@luna_ui/luna"
  }
}
```

**vite.config.ts:**

```ts
import { defineConfig } from 'vite';

export default defineConfig({
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: '@luna_ui/luna',
  },
});
```

## Basic Usage

```tsx
import { createSignal, createMemo, render } from '@luna_ui/luna';

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
import { createSignal, createMemo, createEffect } from '@luna_ui/luna';

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
import { For, Show, Switch, Match } from '@luna_ui/luna';

// For: list rendering
<For each={items}>
  {(item) => <li>{item.name}</li>}
</For>

// Show: conditional rendering
// ⚠️ Children must be a function for proper lifecycle support
<Show when={() => isVisible()}>
  {() => <MyComponent />}
</Show>

// Switch/Match: multiple conditions
<Switch fallback={<p>Default</p>}>
  <Match when={() => value() === 'a'}>{() => <ComponentA />}</Match>
  <Match when={() => value() === 'b'}>{() => <ComponentB />}</Match>
</Switch>
```

### Lifecycle Hooks

```tsx
import { onMount, onCleanup } from '@luna_ui/luna';

function Timer() {
  const [count, setCount] = createSignal(0);

  // Run after component mounts
  onMount(() => {
    console.log('Timer mounted');
  });

  // Cleanup when component unmounts
  onCleanup(() => {
    console.log('Timer cleanup');
  });

  return <p>Count: {count()}</p>;
}

// ⚠️ Important: For onCleanup to work inside Show/For/Switch,
// children must be passed as a function:
<Show when={isVisible}>
  {() => <Timer />}  {/* ✅ Correct */}
</Show>

// This won't trigger cleanup properly:
<Show when={isVisible}>
  <Timer />  {/* ❌ Wrong - Timer runs outside owner scope */}
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

### Context (Provider)

```tsx
import { createContext, useContext, Provider } from '@luna_ui/luna';

// Create a context with default value
const ThemeContext = createContext('light');

function App() {
  return (
    // ⚠️ Children must be a function for proper context access
    <Provider context={ThemeContext} value="dark">
      {() => <ThemedComponent />}
    </Provider>
  );
}

function ThemedComponent() {
  const theme = useContext(ThemeContext);
  return <div>Current theme: {theme}</div>;
}
```

### Portal

```tsx
import { Portal } from '@luna_ui/luna';

function Modal() {
  return (
    // ⚠️ Children must be a function for proper lifecycle support
    <Portal mount="#modal-root">
      {() => (
        <div class="modal">
          <h2>Modal Content</h2>
        </div>
      )}
    </Portal>
  );
}
```

## License

MIT
