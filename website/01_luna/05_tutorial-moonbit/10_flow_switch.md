---
title: "Control Flow: Switch"
---

# Switch (Multiple Conditions)

Handle multiple mutually exclusive conditions with pattern matching.

## Basic Pattern Matching

```moonbit
enum Status {
  Pending
  Active
  Completed
  Error(String)
}

fn status_badge(status : Status) -> @luna.Node {
  match status {
    Pending => span(class_="yellow", [text("Pending")])
    Active => span(class_="green", [text("Active")])
    Completed => span(class_="blue", [text("Completed")])
    Error(msg) => span(class_="red", [text("Error: " + msg)])
  }
}
```

## String Matching

```moonbit
fn tab_content(tab : String) -> @luna.Node {
  match tab {
    "overview" => overview_panel()
    "details" => details_panel()
    "reviews" => reviews_panel()
    _ => div([text("Unknown tab")])
  }
}
```

## Number Ranges

```moonbit
fn grade_label(score : Int) -> @luna.Node {
  let grade = if score >= 90 {
    "A"
  } else if score >= 80 {
    "B"
  } else if score >= 70 {
    "C"
  } else if score >= 60 {
    "D"
  } else {
    "F"
  }

  span([text(grade)])
}
```

## Option Pattern

```moonbit
fn user_display(user : Option[User]) -> @luna.Node {
  match user {
    Some(u) => div([
      h2([text(u.name)]),
      p([text(u.email)])
    ])
    None => div([text("No user selected")])
  }
}
```

## Result Pattern

```moonbit
fn data_display(result : Result[Data, String]) -> @luna.Node {
  match result {
    Ok(data) => data_view(data)
    Err(msg) => error_view(msg)
  }
}
```

## Nested Pattern Matching

```moonbit
enum LoadState[T] {
  Idle
  Loading
  Success(T)
  Error(String)
}

fn async_content[T](state : LoadState[T], render : (T) -> @luna.Node) -> @luna.Node {
  match state {
    Idle => div([text("Ready to load")])
    Loading => div(class_="spinner", [text("Loading...")])
    Success(data) => render(data)
    Error(msg) => div(class_="error", [
      h3([text("Error")]),
      p([text(msg)])
    ])
  }
}
```

## Multiple Conditions

```moonbit
struct Filters {
  category : Option[String]
  price_range : Option[(Int, Int)]
  in_stock : Bool
}

fn filter_description(filters : Filters) -> @luna.Node {
  let parts = []

  match filters.category {
    Some(cat) => parts.push("Category: " + cat)
    None => ()
  }

  match filters.price_range {
    Some((min, max)) => parts.push("Price: $" + min.to_string() + "-$" + max.to_string())
    None => ()
  }

  if filters.in_stock {
    parts.push("In stock only")
  }

  if parts.length() == 0 {
    p([text("No filters applied")])
  } else {
    ul(parts.map(fn(p) { li([text(p)]) }))
  }
}
```

## Comparison with TypeScript

TypeScript uses `<Switch>` and `<Match>` components:

```typescript
// TypeScript
<Switch fallback={<Default />}>
  <Match when={status() === "loading"}>
    <Loading />
  </Match>
  <Match when={status() === "error"}>
    <Error />
  </Match>
</Switch>
```

MoonBit uses pattern matching:

```moonbit
// MoonBit
match status {
  Loading => loading_view()
  Error(msg) => error_view(msg)
  _ => default_view()
}
```

## Try It

Create a traffic light component:
1. Define a `Light` enum with Red, Yellow, Green
2. Render different colors for each state
3. Add a description text for each state

## Next

Learn about [onMount →](./lifecycle_onmount)
