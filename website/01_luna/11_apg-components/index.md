---
title: APG Components
---

# APG Components

Luna provides accessible UI components following [WAI-ARIA Authoring Practices Guide (APG)](https://www.w3.org/WAI/ARIA/apg/) patterns.

Each component includes:
- **Semantic HTML** with proper ARIA attributes
- **Keyboard navigation** following APG recommendations
- **BEM class names** for consistent styling
- **CSS variables** for theming (light/dark mode)

## Component Variants

| Variant | Description |
|---------|-------------|
| **Headless** | Behavior + attributes only, bring your own DOM |
| **Styled** | Complete UI with BEM classes and theme CSS |

## Interactive Demos

### Form Controls

| Component | Description |
|-----------|-------------|
| [Alert](./alert/) | Status messages with severity levels |
| [Switch](./switch/) | Toggle switches with on/off states |
| [Checkbox](./checkbox/) | Checkbox with check/unchecked/indeterminate |

### Data Display

| Component | Description |
|-----------|-------------|
| [Table](./table/) | Sortable data table |

## All APG Components

### Implemented

| Component | APG Pattern | Description |
|-----------|-------------|-------------|
| Alert | [Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) | Status messages |
| Accordion | [Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) | Expandable sections |
| Checkbox | [Checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) | Tri-state checkbox |
| Disclosure | [Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) | Show/hide content |
| Listbox | [Listbox](https://www.w3.org/WAI/ARIA/apg/patterns/listbox/) | Selectable list |
| Menu Button | [Menu Button](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/) | Dropdown menu |
| Meter | [Meter](https://www.w3.org/WAI/ARIA/apg/patterns/meter/) | Value in range |
| Radio Group | [Radio Group](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) | Single selection |
| Slider | [Slider](https://www.w3.org/WAI/ARIA/apg/patterns/slider/) | Range input |
| Spinbutton | [Spinbutton](https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/) | Numeric input |
| Switch | [Switch](https://www.w3.org/WAI/ARIA/apg/patterns/switch/) | Toggle switch |
| Table | [Table](https://www.w3.org/WAI/ARIA/apg/patterns/table/) | Data table |
| Tabs | [Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/) | Tabbed interface |
| Toolbar | [Toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) | Action toolbar |
| Tooltip | [Tooltip](https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/) | Hover info |
| Tree View | [Tree View](https://www.w3.org/WAI/ARIA/apg/patterns/treeview/) | Hierarchical data |

## CSS Variables

All components use these CSS variables for theming:

```css
:root {
  --background: #ffffff;
  --foreground: #1a1a1a;
  --muted: #f7f7f8;
  --muted-foreground: #666666;
  --border: #e5e5e5;
  --accent: #6366f1;
  --accent-foreground: #ffffff;
  --destructive: #ef4444;
  --warning: #f59e0b;
  --success: #10b981;
}
```

See [Theme Variables](/luna/css/) for dark mode and customization.
