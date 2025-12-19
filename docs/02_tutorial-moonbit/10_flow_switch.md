---
title: "Control Flow: Switch"
---

# Switch (Multiple Conditions)

Handle multiple mutually exclusive conditions.

## Basic Usage

### TypeScript

```typescript
import { createSignal, Switch, Match } from '@mizchi/luna';

function StatusBadge() {
  const [status, setStatus] = createSignal("pending");

  return (
    <Switch fallback={<span>Unknown</span>}>
      <Match when={status() === "pending"}>
        <span class="yellow">Pending</span>
      </Match>
      <Match when={status() === "active"}>
        <span class="green">Active</span>
      </Match>
      <Match when={status() === "error"}>
        <span class="red">Error</span>
      </Match>
    </Switch>
  );
}
```

### MoonBit

```moonbit
///|
using @element {
  span, text, switch_, match_,
  type DomNode,
}
using @luna { signal }

fn status_badge() -> DomNode {
  let status = signal("pending")

  switch_(
    fallback=span([text("Unknown")]),
    [
      match_(
        when=fn() { status.get() == "pending" },
        span([text("Pending")]),
      ),
      match_(
        when=fn() { status.get() == "active" },
        span([text("Active")]),
      ),
      match_(
        when=fn() { status.get() == "error" },
        span([text("Error")]),
      ),
    ],
  )
}
```

## Switch vs Nested Show

### Nested Show (verbose)

```typescript
<Show when={status() === "loading"} fallback={
  <Show when={status() === "error"} fallback={
    <Show when={status() === "success"} fallback={
      <DefaultView />
    }>
      <SuccessView />
    </Show>
  }>
    <ErrorView />
  </Show>
}>
  <LoadingView />
</Show>
```

### Switch (clean)

```typescript
<Switch fallback={<DefaultView />}>
  <Match when={status() === "loading"}>
    <LoadingView />
  </Match>
  <Match when={status() === "error"}>
    <ErrorView />
  </Match>
  <Match when={status() === "success"}>
    <SuccessView />
  </Match>
</Switch>
```

## Extracting Values

Like `<Show>`, `<Match>` can extract truthy values:

```typescript
const [response, setResponse] = createSignal(null);

<Switch>
  <Match when={response()?.error}>
    {(error) => <p>Error: {error.message}</p>}
  </Match>
  <Match when={response()?.data}>
    {(data) => <DataView data={data} />}
  </Match>
</Switch>
```

## Order Matters

The first matching `<Match>` wins:

```typescript
const [score, setScore] = createSignal(85);

<Switch fallback={<p>F</p>}>
  <Match when={score() >= 90}><p>A</p></Match>
  <Match when={score() >= 80}><p>B</p></Match>  {/* This matches for 85 */}
  <Match when={score() >= 70}><p>C</p></Match>
  <Match when={score() >= 60}><p>D</p></Match>
</Switch>
```

## Common Patterns

### Tab Content

```typescript
const [tab, setTab] = createSignal("overview");

<div>
  <nav>
    <button onClick={() => setTab("overview")}>Overview</button>
    <button onClick={() => setTab("details")}>Details</button>
    <button onClick={() => setTab("reviews")}>Reviews</button>
  </nav>

  <Switch>
    <Match when={tab() === "overview"}>
      <OverviewPanel />
    </Match>
    <Match when={tab() === "details"}>
      <DetailsPanel />
    </Match>
    <Match when={tab() === "reviews"}>
      <ReviewsPanel />
    </Match>
  </Switch>
</div>
```

### Loading/Error/Success

```typescript
const [state, setState] = createSignal({ status: "idle" });

<Switch fallback={<IdleState />}>
  <Match when={state().status === "loading"}>
    <Spinner />
  </Match>
  <Match when={state().status === "error"}>
    <ErrorMessage error={state().error} />
  </Match>
  <Match when={state().status === "success"}>
    <DataView data={state().data} />
  </Match>
</Switch>
```

### User Roles

```typescript
const [user, setUser] = createSignal(null);

<Switch fallback={<GuestView />}>
  <Match when={user()?.role === "admin"}>
    <AdminDashboard user={user()} />
  </Match>
  <Match when={user()?.role === "moderator"}>
    <ModeratorDashboard user={user()} />
  </Match>
  <Match when={user()}>
    {(u) => <UserDashboard user={u} />}
  </Match>
</Switch>
```

### Step Wizard

```typescript
const [step, setStep] = createSignal(1);

<div>
  <Switch>
    <Match when={step() === 1}>
      <Step1 onNext={() => setStep(2)} />
    </Match>
    <Match when={step() === 2}>
      <Step2
        onBack={() => setStep(1)}
        onNext={() => setStep(3)}
      />
    </Match>
    <Match when={step() === 3}>
      <Step3
        onBack={() => setStep(2)}
        onSubmit={handleSubmit}
      />
    </Match>
  </Switch>

  <p>Step {step()} of 3</p>
</div>
```

### Media Type

```typescript
const [media, setMedia] = createSignal({ type: "image", url: "..." });

<Switch fallback={<p>Unsupported media</p>}>
  <Match when={media().type === "image"}>
    <img src={media().url} />
  </Match>
  <Match when={media().type === "video"}>
    <video src={media().url} controls />
  </Match>
  <Match when={media().type === "audio"}>
    <audio src={media().url} controls />
  </Match>
</Switch>
```

## Dynamic Fallback

The fallback can also be reactive:

```typescript
<Switch fallback={<p>No data for {category()}</p>}>
  <Match when={items().length > 0}>
    <ItemList items={items()} />
  </Match>
</Switch>
```

## Try It

Create a traffic light component with three states (red, yellow, green) that cycles through them:

<details>
<summary>Solution</summary>

```typescript
function TrafficLight() {
  const [light, setLight] = createSignal("red");

  const cycle = () => {
    setLight(current => {
      switch (current) {
        case "red": return "green";
        case "green": return "yellow";
        case "yellow": return "red";
      }
    });
  };

  return (
    <div>
      <div class="traffic-light">
        <Switch>
          <Match when={light() === "red"}>
            <div class="light red">STOP</div>
          </Match>
          <Match when={light() === "yellow"}>
            <div class="light yellow">CAUTION</div>
          </Match>
          <Match when={light() === "green"}>
            <div class="light green">GO</div>
          </Match>
        </Switch>
      </div>
      <button onClick={cycle}>Next</button>
    </div>
  );
}
```

</details>

## Next

Learn about [onMount →](./lifecycle_onmount)
