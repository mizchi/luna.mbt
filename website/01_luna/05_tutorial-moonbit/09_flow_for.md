---
title: "Control Flow: For"
---

# List Rendering

Render lists of items efficiently.

## Basic List Rendering

```moonbit
using @server_dom { ul, li, text }

fn item_list(items : Array[String]) -> @luna.Node {
  ul(
    items.map(fn(item) {
      li([text(item)])
    })
  )
}
```

## With Index

```moonbit
fn numbered_list(items : Array[String]) -> @luna.Node {
  ul(
    items.mapi(fn(index, item) {
      li([text((index + 1).to_string() + ". " + item)])
    })
  )
}
```

## Rendering Structs

```moonbit
struct User {
  id : Int
  name : String
  email : String
}

fn user_list(users : Array[User]) -> @luna.Node {
  ul(
    users.map(fn(user) {
      li([
        text(user.name + " (" + user.email + ")")
      ])
    })
  )
}
```

## Nested Lists

```moonbit
struct Category {
  name : String
  items : Array[String]
}

fn category_list(categories : Array[Category]) -> @luna.Node {
  div(
    categories.map(fn(cat) {
      div([
        h3([text(cat.name)]),
        ul(
          cat.items.map(fn(item) {
            li([text(item)])
          })
        )
      ])
    })
  )
}
```

## Filtering

```moonbit
fn active_users(users : Array[User], active_only : Bool) -> @luna.Node {
  let filtered = if active_only {
    users.filter(fn(u) { u.active })
  } else {
    users
  }

  ul(
    filtered.map(fn(user) {
      li([text(user.name)])
    })
  )
}
```

## Empty State

```moonbit
fn item_list_with_empty(items : Array[String]) -> @luna.Node {
  if items.length() == 0 {
    p([text("No items found")])
  } else {
    ul(
      items.map(fn(item) {
        li([text(item)])
      })
    )
  }
}
```

## Key Attribute for Client Hydration

When rendering lists for hydration, provide keys for efficient updates:

```moonbit
using @server_dom { li, text, attr }

fn todo_list(todos : Array[Todo]) -> @luna.Node {
  ul(
    todos.map(fn(todo) {
      li(
        attrs=[attr("data-key", todo.id.to_string())],
        [text(todo.text)]
      )
    })
  )
}
```

## Table Rendering

```moonbit
struct Product {
  name : String
  price : Double
  stock : Int
}

fn product_table(products : Array[Product]) -> @luna.Node {
  table([
    thead([
      tr([
        th([text("Name")]),
        th([text("Price")]),
        th([text("Stock")]),
      ])
    ]),
    tbody(
      products.map(fn(p) {
        tr([
          td([text(p.name)]),
          td([text("$" + p.price.to_string())]),
          td([text(p.stock.to_string())]),
        ])
      })
    )
  ])
}
```

## Comparison with TypeScript

TypeScript (client-side) uses `<For>` component:

```typescript
// TypeScript
<For each={items()}>
  {(item, index) => <li>{item}</li>}
</For>
```

MoonBit (server-side) uses array methods:

```moonbit
// MoonBit
items.map(fn(item) {
  li([text(item)])
})
```

## Try It

Create a component that:
1. Takes an array of products
2. Filters out items with zero stock
3. Renders a list with name and price
4. Shows "No products available" when empty

## Next

Learn about [Switch →](./flow_switch)
