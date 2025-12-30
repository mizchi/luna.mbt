# Shoelace Components (WIP)

> **Note:** This module is experimental and may be moved to a separate repository.

MoonBit bindings for [Shoelace](https://shoelace.style/) Web Components.

## Status

- **WIP** - Work in Progress
- Shoelace does not support Declarative Shadow DOM (DSD)
- Requires JavaScript for hydration
- May cause CLS (Cumulative Layout Shift)

## Recommendation

For SSR-first applications, use `@luna/components/radix` instead which:
- Supports DSD for zero CLS
- Works without JavaScript
- Has smaller bundle size

## Components

- `sl_button` - Button component
- `sl_input` - Input component
- `sl_checkbox` - Checkbox component
- `sl_switch` - Switch component

## Usage

```moonbit
let button = sl_button(variant=Primary, [@luna.text("Click me")])
```
