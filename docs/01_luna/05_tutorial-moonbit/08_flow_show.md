---
title: "Control Flow: Show"
---

# Conditional Rendering

Render different content based on conditions.

## Basic Conditional

In MoonBit, use pattern matching or if-else:

```moonbit
using @server_dom { div, p, text }
using @luna { signal }

fn greeting(logged_in : Bool) -> @luna.Node {
  if logged_in {
    p([text("Welcome back!")])
  } else {
    p([text("Please log in")])
  }
}
```

## With Signals

```moonbit
using @server_dom { div, p, text }
using @luna { signal }

fn status_display() -> @luna.Node {
  let is_loading = signal(true)

  div([
    if is_loading.get() {
      p([text("Loading...")])
    } else {
      p([text("Content loaded")])
    }
  ])
}
```

## Conditional Components

```moonbit
fn user_status(user : Option[User]) -> @luna.Node {
  match user {
    Some(u) => logged_in_view(u)
    None => login_prompt()
  }
}

fn logged_in_view(user : User) -> @luna.Node {
  div([
    text("Hello, " + user.name)
  ])
}

fn login_prompt() -> @luna.Node {
  div([
    text("Please log in")
  ])
}
```

## Multiple Conditions

```moonbit
enum Status {
  Loading
  Error(String)
  Success(Data)
}

fn status_view(status : Status) -> @luna.Node {
  match status {
    Loading => p([text("Loading...")])
    Error(msg) => p([text("Error: " + msg)])
    Success(data) => data_view(data)
  }
}
```

## Conditional Attributes

```moonbit
using @server_dom { button, text, attr }

fn submit_button(disabled : Bool) -> @luna.Node {
  let attrs = if disabled {
    [attr("disabled", "")]
  } else {
    []
  }

  button(attrs=attrs, [text("Submit")])
}
```

## Conditional Classes

```moonbit
using @server_dom { div, text }

fn card(active : Bool) -> @luna.Node {
  let class_name = if active {
    "card active"
  } else {
    "card"
  }

  div(class_=class_name, [text("Card content")])
}
```

## Conditional Children

```moonbit
fn notification(show_icon : Bool, message : String) -> @luna.Node {
  let children = if show_icon {
    [span([text("!")]), text(" " + message)]
  } else {
    [text(message)]
  }

  div(children)
}
```

## Comparison with TypeScript

In client-side TypeScript, use `<Show>` component:

```typescript
// TypeScript (client-side)
<Show when={isLoading()} fallback={<Content />}>
  <Loading />
</Show>
```

In MoonBit (server-side), use if-else or match:

```moonbit
// MoonBit (server-side)
if is_loading {
  loading_view()
} else {
  content_view()
}
```

## Try It

Create a component that:
1. Takes a `status` enum (Idle, Loading, Error, Success)
2. Renders different content for each state
3. Shows error message when in Error state

## Next

Learn about [For →](./flow_for)
