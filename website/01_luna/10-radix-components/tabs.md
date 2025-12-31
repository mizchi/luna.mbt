---
title: Tabs
---

# Tabs

Tabbed interface for organizing content into panels.

## Demo

<Island name="tabs-demo" :props='{}' trigger="visible" />

## Usage

```moonbit
radix_tabs(value="account", children=[
  radix_tabs_list(children=[
    radix_tabs_trigger("account", children=[@luna.text("Account")]),
    radix_tabs_trigger("password", children=[@luna.text("Password")]),
    radix_tabs_trigger("notifications", children=[@luna.text("Notifications")]),
  ]),
  radix_tabs_content("account", children=[
    @luna.text("Manage your account settings."),
  ]),
  radix_tabs_content("password", children=[
    @luna.text("Change your password."),
  ]),
  radix_tabs_content("notifications", children=[
    @luna.text("Configure notifications."),
  ]),
])
```

## Controlled vs Uncontrolled

### Uncontrolled (with default)

```moonbit
radix_tabs(default_value="tab1", children=[...])
```

### Controlled

```moonbit
let active_tab = @signal.create("tab1")

radix_tabs(
  value=active_tab.get(),
  on_value_change=fn(v) { active_tab.set(v) },
  children=[...],
)
```

## Props

### Tabs

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| value | String? | None | Controlled active tab |
| default_value | String? | None | Initial tab (uncontrolled) |
| on_value_change | (String) -> Unit | - | Change handler |

### TabsTrigger

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| value | String | - | Tab identifier |
| disabled | Bool | false | Disable this tab |

## Accessibility

- Arrow keys navigate between tabs
- Tab content receives focus after selection
- Proper ARIA roles and attributes
