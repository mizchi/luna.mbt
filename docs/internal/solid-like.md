# SolidJS-like API Design

Luna provides a SolidJS-compatible API layer on top of MoonBit's reactive primitives. This document describes the design decisions and constraints.

## Design Goals

1. **SolidJS API familiarity** - Developers familiar with SolidJS should feel at home
2. **No compile-time transformation** - Unlike SolidJS, Luna doesn't use JSX compilation or Babel plugins
3. **MoonBit-first** - Core reactivity is implemented in MoonBit, JS layer is a thin wrapper

## Constraints

### No JSX Compilation

SolidJS relies heavily on compile-time JSX transformation to optimize reactivity. Luna accepts this limitation and provides function-based alternatives:

```typescript
// SolidJS (with JSX compilation)
<For each={items()}>{(item) => <div>{item}</div>}</For>

// Luna (no compilation)
For({
  each: items,
  children: (item) => createElement("div", [], [text(item)])
})
```

### Component Model

Since there's no compilation, "components" are just functions that return DOM nodes:

```typescript
// Luna component
function Counter() {
  const [count, setCount] = createSignal(0);
  return createElement("button",
    [attr("click", AttrValue.Handler(() => setCount(c => c + 1)))],
    [textDyn(() => `Count: ${count()}`)]
  );
}
```

## API Reference

### Reactive Primitives

| Luna | SolidJS | Notes |
|------|---------|-------|
| `createSignal(v)` | `createSignal(v)` | Returns `[getter, setter]` tuple |
| `createEffect(fn)` | `createEffect(fn)` | Auto-tracks dependencies |
| `createMemo(fn)` | `createMemo(fn)` | Memoized computed value |
| `createRoot(fn)` | `createRoot(fn)` | Creates reactive scope |
| `batch(fn)` | `batch(fn)` | Batches updates |
| `untrack(fn)` | `untrack(fn)` | Runs without tracking |
| `on(deps, fn, opts)` | `on(deps, fn, opts)` | Explicit dependency tracking |
| `onCleanup(fn)` | `onCleanup(fn)` | Cleanup in effects |
| `onMount(fn)` | `onMount(fn)` | Run once after mount |

### Control Flow Components

| Luna | SolidJS | Notes |
|------|---------|-------|
| `For({ each, children })` | `<For each={...}>` | Reference-based list |
| `Index({ each, children })` | `<Index each={...}>` | Index-based list |
| `Show({ when, children })` | `<Show when={...}>` | Conditional rendering |
| `Switch/Match` | `<Switch>/<Match>` | Multiple conditions |
| `Provider` | `<Context.Provider>` | Context provider |
| `Portal` | `<Portal>` | Render outside tree |

### Utility Functions

| Luna | SolidJS | Notes |
|------|---------|-------|
| `mergeProps(...sources)` | `mergeProps(...sources)` | Merge props objects |
| `splitProps(props, keys)` | `splitProps(props, keys)` | Split props |

### Context API

```typescript
// Create context
const ThemeContext = createContext("light");

// Provide value (function-based)
provide(ThemeContext, "dark", () => {
  // descendants can access "dark"
});

// Or use Provider component
Provider({
  context: ThemeContext,
  value: "dark",
  children: () => App()
});

// Consume value
const theme = useContext(ThemeContext); // "dark"
```

Context is **Owner-based** (component-tree-scoped), matching SolidJS behavior. Values are inherited through the reactive Owner chain, not JavaScript call stack.

### Portal API

Portal renders children into a different DOM location, outside the normal component hierarchy.

```typescript
// Render modal to body (default)
Portal({ children: modalContent() })

// Render to specific CSS selector
Portal({ mount: "#modal-root", children: modalContent() })

// Render with Shadow DOM encapsulation
Portal({ useShadow: true, children: modalContent() })
```

Use cases:
- Modals that need to avoid z-index issues
- Dropdowns/tooltips escaping `overflow: hidden`
- Full-screen overlays

Low-level functions are also available:
- `portalToBody(children)` - Portal to document.body
- `portalToSelector(selector, children)` - Portal to CSS selector
- `portalWithShadow(children)` - Portal with Shadow DOM
- `portalToElementWithShadow(element, children)` - Portal to element with Shadow DOM

## Differences from SolidJS

### 1. No JSX

All UI is built with function calls:

```typescript
// Instead of: <div class="foo">Hello</div>
createElement("div", [attr("className", AttrValue.Static("foo"))], [text("Hello")])
```

### 2. Event Handler Syntax

```typescript
// SolidJS: onClick={() => ...}
// Luna: attr("click", AttrValue.Handler(() => ...))
```

### 3. Dynamic Attributes

```typescript
// SolidJS: class={dynamicClass()}
// Luna: attr("className", AttrValue.Dynamic(() => dynamicClass()))
```

### 4. Show Initial True Limitation

`show()` has a known limitation when initial condition is `true` - the content may not render until a re-render. Start with `false` and toggle to `true` for reliable behavior.

### 5. No Suspense

Suspense requires async rendering primitives not yet fully implemented in Luna.

**Note:** ErrorBoundary is now implemented! See `error_boundary()` in `@luna`.

## Future Directions

1. **JSX compilation support** - Optional Babel/SWC plugin for JSX syntax
2. **Suspense** - Async boundary for loading states
3. **Transition API** - Animation coordination
4. **Store** - Nested reactive state (like SolidJS stores)

## Example: Todo App

```typescript
import {
  createSignal,
  For,
  Show,
  createElement,
  text,
  textDyn,
  render,
} from "@luna_ui/luna";

function TodoApp() {
  const [todos, setTodos] = createSignal([
    { id: 1, text: "Learn Luna", done: false },
  ]);
  const [input, setInput] = createSignal("");

  const addTodo = () => {
    const text = input();
    if (text.trim()) {
      setTodos(t => [...t, { id: Date.now(), text, done: false }]);
      setInput("");
    }
  };

  const toggleTodo = (id: number) => {
    setTodos(t => t.map(todo =>
      todo.id === id ? { ...todo, done: !todo.done } : todo
    ));
  };

  return createElement("div", [], [
    createElement("input", [
      attr("value", AttrValue.Dynamic(input)),
      attr("input", AttrValue.Handler((e) => setInput(e.target.value))),
    ], []),
    createElement("button", [
      attr("click", AttrValue.Handler(addTodo)),
    ], [text("Add")]),
    For({
      each: todos,
      children: (todo) => createElement("div", [
        attr("click", AttrValue.Handler(() => toggleTodo(todo.id))),
        attr("style", AttrValue.Static(todo.done ? "text-decoration: line-through" : "")),
      ], [text(todo.text)]),
    }),
  ]);
}

render(document.getElementById("app"), TodoApp());
```
