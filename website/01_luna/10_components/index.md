---
title: Components
---

# Components

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

## All Components

### Styled Components

Complete UI with BEM classes and theme CSS.

| Component | APG Pattern | Description |
|-----------|-------------|-------------|
| Accordion | [Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) | Expandable sections |
| Alert | [Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) | Status messages |
| Checkbox | [Checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) | Tri-state checkbox |
| Disclosure | [Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) | Show/hide content |
| Meter | [Meter](https://www.w3.org/WAI/ARIA/apg/patterns/meter/) | Value in range |
| Radio Group | [Radio Group](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) | Single selection |
| Spinbutton | [Spinbutton](https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/) | Numeric input |
| Switch | [Switch](https://www.w3.org/WAI/ARIA/apg/patterns/switch/) | Toggle switch |
| Table | [Table](https://www.w3.org/WAI/ARIA/apg/patterns/table/) | Data table |
| Tabs | [Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/) | Tabbed interface |
| Toolbar | [Toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) | Action toolbar |
| Tree View | [Tree View](https://www.w3.org/WAI/ARIA/apg/patterns/treeview/) | Hierarchical data |

### Headless Components

Behavior + ARIA attributes only. Bring your own styles.

| Component | APG Pattern | Description |
|-----------|-------------|-------------|
| Accordion | [Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) | Expandable sections |
| Alert | [Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) | Status messages |
| Breadcrumb | [Breadcrumb](https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/) | Navigation trail |
| Button | [Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) | Click actions |
| Checkbox | [Checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) | Tri-state checkbox |
| Combobox | [Combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) | Autocomplete input |
| Dialog | [Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) | Modal dialogs |
| Disclosure | [Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) | Show/hide content |
| Landmarks | [Landmarks](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/) | Page regions |
| Link | [Link](https://www.w3.org/WAI/ARIA/apg/patterns/link/) | Navigation links |
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
