---
title: Button
---

# Button

Interactive button component with multiple variants.

## Demo

<Island name="button-demo" :props='{}' trigger="visible" />

## Variants

- **Primary** - Main action button with filled background
- **Secondary** - Alternative action with outline style
- **Destructive** - Dangerous actions (delete, remove)
- **Ghost** - Minimal style for subtle actions

## Usage

```moonbit
// Primary button
radix_button(variant=Primary, size=Md, children=[@luna.text("Click me")])

// Secondary button
radix_button(variant=Secondary, size=Md, children=[@luna.text("Cancel")])

// Destructive button
radix_button(variant=Destructive, size=Md, children=[@luna.text("Delete")])

// Ghost button
radix_button(variant=Ghost, size=Md, children=[@luna.text("More")])
```

## Sizes

- `Sm` - Small (compact UI)
- `Md` - Medium (default)
- `Lg` - Large (prominent actions)

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| variant | ButtonVariant | Primary | Visual style |
| size | ButtonSize | Md | Button size |
| disabled | Bool | false | Disable interaction |
| children | Array[Node] | [] | Button content |
