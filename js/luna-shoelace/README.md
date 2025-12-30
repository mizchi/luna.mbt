# @luna_ui/shoelace

Shoelace component bindings for Luna.

## Installation

```bash
pnpm add @luna_ui/shoelace @shoelace-style/shoelace
```

## Usage

### With CDN (Recommended)

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn/themes/light.css">
<script type="module" src="https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn/shoelace-autoloader.js"></script>
```

### Components

```typescript
import { slButton, slInput, slCheckbox, slSwitch } from '@luna_ui/shoelace';

// Create a button
const button = slButton(
  { variant: 'primary', onClick: () => console.log('clicked') },
  ['Click me']
);

// Create an input
const input = slInput({
  label: 'Email',
  type: 'email',
  placeholder: 'you@example.com',
  onInput: (e) => console.log(e.target.value)
});

// Create a checkbox
const checkbox = slCheckbox(
  { onChange: (e) => console.log(e.target.checked) },
  ['Accept terms']
);

// Create a switch
const toggle = slSwitch(
  { checked: true },
  ['Enable notifications']
);
```

### Signal Integration

For reactive bindings with Luna signals:

```typescript
import { slButtonReactive, slInputReactive } from '@luna_ui/shoelace';

// Assuming you have a Signal implementation
const count = new Signal(0);
const loading = new Signal(false);

const button = slButtonReactive({
  variant: 'primary',
  loadingSignal: loading,
  onClick: () => {
    loading.set(true);
    setTimeout(() => {
      count.update(n => n + 1);
      loading.set(false);
    }, 500);
  }
}, ['Submit']);

const email = new Signal('');
const input = slInputReactive({
  label: 'Email',
  valueSignal: email,
});
```

### SSR Support

All components automatically detect the environment and return HTML strings in SSR contexts:

```typescript
// In Node.js (SSR)
const html = slButton({ variant: 'primary' }, ['Click me']);
// Returns: '<sl-button variant="primary">Click me</sl-button>'
```

## Components

| Component | Function | Reactive Version |
|-----------|----------|------------------|
| Button | `slButton()` | `slButtonReactive()` |
| Input | `slInput()` | `slInputReactive()` |
| Checkbox | `slCheckbox()` | `slCheckboxReactive()` |
| Switch | `slSwitch()` | `slSwitchReactive()` |

## API

### Button Props

- `variant`: 'default' | 'primary' | 'success' | 'neutral' | 'warning' | 'danger'
- `size`: 'small' | 'medium' | 'large'
- `disabled`: boolean
- `loading`: boolean
- `outline`: boolean
- `pill`: boolean
- `circle`: boolean
- `href`: string (renders as link)
- `target`: string
- `onClick`: (e: Event) => void

### Input Props

- `type`: 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search' | 'date'
- `label`: string
- `placeholder`: string
- `value`: string
- `size`: 'small' | 'medium' | 'large'
- `disabled`: boolean
- `readonly`: boolean
- `required`: boolean
- `clearable`: boolean
- `passwordToggle`: boolean
- `helpText`: string
- `minlength`: number
- `maxlength`: number
- `pattern`: string
- `onInput`: (e: Event) => void
- `onChange`: (e: Event) => void

### Checkbox Props

- `checked`: boolean
- `indeterminate`: boolean
- `disabled`: boolean
- `required`: boolean
- `size`: 'small' | 'medium' | 'large'
- `helpText`: string
- `onChange`: (e: Event) => void

### Switch Props

- `checked`: boolean
- `disabled`: boolean
- `required`: boolean
- `size`: 'small' | 'medium' | 'large'
- `helpText`: string
- `onChange`: (e: Event) => void

## License

MIT
