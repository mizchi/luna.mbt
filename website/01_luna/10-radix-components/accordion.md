---
title: Accordion
---

# Accordion

Expandable content sections with header triggers.

## Demo

<Island name="accordion-demo" :props='{}' trigger="visible" />

## Usage

```moonbit
radix_accordion(
  accordion_type=Single,
  collapsible=true,
  children=[
    radix_accordion_item(value="item-1", children=[
      radix_accordion_trigger(children=[@luna.text("What is Luna?")]),
      radix_accordion_content(children=[
        @luna.text("Luna is a blazing-fast reactive UI framework."),
      ]),
    ]),
    radix_accordion_item(value="item-2", children=[
      radix_accordion_trigger(children=[@luna.text("How does it work?")]),
      radix_accordion_content(children=[
        @luna.text("Luna uses signals for reactive state management."),
      ]),
    ]),
  ],
)
```

## Types

- **Single** - Only one item can be open at a time
- **Multiple** - Multiple items can be open simultaneously

## Props

### Accordion

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| accordion_type | AccordionType | Single | Single or Multiple |
| collapsible | Bool | false | Allow closing all items |
| default_value | String? | None | Initially open item |

### AccordionItem

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| value | String | - | Unique identifier |
| disabled | Bool | false | Disable this item |

## Accessibility

- Arrow keys navigate between items
- Enter/Space toggles current item
- Proper ARIA attributes for screen readers
