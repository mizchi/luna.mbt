---
title: Switch
---

# Switch

Toggle switch for boolean settings.

## Demo

<Island name="switch-demo" :props='{}' trigger="visible" />

## Usage

```moonbit
let enabled = @signal.create(false)

radix_switch(
  checked=enabled.get(),
  on_change=fn(v) { enabled.set(v) },
)
```

## With Label

```moonbit
@luna.div([class_("flex items-center gap-2")], [
  radix_label(for_id="notifications", children=[@luna.text("Notifications")]),
  radix_switch(id="notifications", checked=true),
])
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| checked | Bool | false | Current state |
| disabled | Bool | false | Disable interaction |
| on_change | (Bool) -> Unit | - | Change handler |

## Accessibility

- Uses `role="switch"` for screen readers
- Keyboard accessible (Space to toggle)
- Focus visible indicator
