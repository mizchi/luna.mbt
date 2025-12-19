---
title: "Control Flow: Show"
---

# Show (Conditional Rendering)

Render content conditionally based on a signal.

## Basic Usage

### TypeScript

```typescript
import { createSignal, Show } from '@mizchi/luna';

function Toggle() {
  const [visible, setVisible] = createSignal(false);

  return (
    <div>
      <button onClick={() => setVisible(v => !v)}>
        Toggle
      </button>

      <Show when={visible()}>
        <p>Now you see me!</p>
      </Show>
    </div>
  );
}
```

### MoonBit

```moonbit
///|
using @element {
  div, button, p, text, events, show,
  type DomNode,
}
using @luna { signal }

fn toggle() -> DomNode {
  let visible = signal(false)

  div([
    button(
      on=events().click(_ => visible.update(fn(v) { not(v) })),
      [text("Toggle")],
    ),
    show(
      when=fn() { visible.get() },
      [p([text("Now you see me!")])],
    ),
  ])
}
```

## Fallback Content

Show alternate content when the condition is false:

```typescript
<Show when={isLoggedIn()} fallback={<LoginForm />}>
  <Dashboard />
</Show>
```

```moonbit
///|
using @element { show }

show(
  when=fn() { is_logged_in.get() },
  fallback=login_form(),
  [dashboard()],
)
```

## Extracting Values

When the condition is a value (not just boolean), you can access it:

```typescript
const [user, setUser] = createSignal(null);

<Show when={user()} fallback={<p>Loading...</p>}>
  {(u) => <p>Welcome, {u.name}!</p>}
</Show>
```

The render function receives the truthy value, guaranteed to be non-null.

## Why Show vs Ternary?

You might wonder why use `<Show>` instead of a ternary:

```typescript
// Ternary - works but has downsides
{visible() ? <Content /> : <Fallback />}

// Show - preferred
<Show when={visible()} fallback={<Fallback />}>
  <Content />
</Show>
```

### Benefits of Show

1. **Lazy Evaluation**: Children only render when condition is true
2. **Cleaner Syntax**: Especially for complex conditions
3. **Keyed Rendering**: Can preserve or reset state

## Keyed Show

By default, Show preserves DOM nodes when toggling. Use `keyed` to force recreation:

```typescript
const [tab, setTab] = createSignal("home");

// Preserved: same component instance, state retained
<Show when={tab() === "home"}>
  <Counter />
</Show>

// Keyed: new instance each time, state reset
<Show when={tab()} keyed>
  {(currentTab) => <TabContent tab={currentTab} />}
</Show>
```

## Nested Conditions

```typescript
<Show when={user()}>
  <Show when={user().isAdmin} fallback={<UserDashboard />}>
    <AdminDashboard />
  </Show>
</Show>
```

## Common Patterns

### Loading States

```typescript
const [loading, setLoading] = createSignal(true);
const [data, setData] = createSignal(null);
const [error, setError] = createSignal(null);

<Show when={!loading()} fallback={<Spinner />}>
  <Show when={!error()} fallback={<ErrorMessage error={error()} />}>
    <DataView data={data()} />
  </Show>
</Show>
```

### Feature Flags

```typescript
const [features] = createSignal({ newUI: true, beta: false });

<Show when={features().newUI}>
  <NewHeader />
</Show>

<Show when={features().beta}>
  <BetaFeature />
</Show>
```

### Auth Guards

```typescript
const [user, setUser] = createSignal(null);

<Show when={user()} fallback={<Navigate to="/login" />}>
  {(u) => (
    <Show when={u.verified} fallback={<VerifyEmail />}>
      <App user={u} />
    </Show>
  )}
</Show>
```

## Show vs CSS Display

| Approach | DOM | State | Use When |
|----------|-----|-------|----------|
| `<Show>` | Added/removed | Reset (or keyed) | Content expensive to render |
| `style={{ display }}` | Always present | Preserved | Frequent toggles, state preservation |

```typescript
// DOM removed when hidden
<Show when={visible()}>
  <HeavyComponent />
</Show>

// DOM hidden but present
<div style={{ display: visible() ? "block" : "none" }}>
  <LightComponent />
</div>
```

## Try It

Create a login/logout toggle that shows different content based on auth state:

<details>
<summary>Solution</summary>

```typescript
function AuthExample() {
  const [user, setUser] = createSignal(null);

  const login = () => setUser({ name: "Alice", role: "admin" });
  const logout = () => setUser(null);

  return (
    <div>
      <Show
        when={user()}
        fallback={
          <div>
            <p>Please log in</p>
            <button onClick={login}>Log In</button>
          </div>
        }
      >
        {(u) => (
          <div>
            <p>Welcome, {u.name}!</p>
            <Show when={u.role === "admin"}>
              <p>Admin Panel</p>
            </Show>
            <button onClick={logout}>Log Out</button>
          </div>
        )}
      </Show>
    </div>
  );
}
```

</details>

## Next

Learn about [For (List Rendering) →](./flow_for)
