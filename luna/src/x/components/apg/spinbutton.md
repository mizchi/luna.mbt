# Spinbutton Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/

## Overview

A spinbutton allows users to select a value from a discrete set or range. Contains a text field displaying the current value with optional increment/decrement buttons. Supports direct text input and keyboard navigation.

## Native HTML vs Custom Implementation

**Prefer native `<input type="number">`** when possible - provides implicit semantics.

| Use Case | Recommended |
| --- | --- |
| Simple numeric input | Native `<input type="number">` |
| Custom styling needed | Custom `role="spinbutton"` |
| Consistent keyboard behavior | Custom (browser varies) |
| `aria-valuetext` needed | Custom implementation |

## ARIA Requirements

### Roles

| Role | Element | Required | Description |
| --- | --- | --- | --- |
| `spinbutton` | Input element | Yes | Identifies the element as a spinbutton |

### Properties

| Attribute | Element | Values | Required | Notes |
| --- | --- | --- | --- | --- |
| `aria-valuemin` | spinbutton | number | No | Only set when min is defined |
| `aria-valuemax` | spinbutton | number | No | Only set when max is defined |
| `aria-label` | spinbutton | string | Conditional | When no visible label |
| `aria-labelledby` | spinbutton | ID ref | Conditional | When visible label exists |
| `aria-readonly` | spinbutton | `true` | No | When readOnly is true |
| `aria-disabled` | spinbutton | `true` | No | When disabled is true |

**Label Requirement**: One of `label`, `aria-label`, or `aria-labelledby` is required.

### States

| Attribute | Element | Values | Required | Change Trigger |
| --- | --- | --- | --- | --- |
| `aria-valuenow` | spinbutton | number | Yes | Value change (keyboard/button/input) |
| `aria-valuetext` | spinbutton | string | No | Value change (when format provided) |
| `aria-invalid` | spinbutton | `true`/`false` | No | When value is out of range |

**IME Handling**: During IME composition (`compositionstart` to `compositionend`), `aria-valuenow` retains the previous valid value.

## Keyboard Support

| Key | Action |
| --- | --- |
| `ArrowUp` | Increase value by step |
| `ArrowDown` | Decrease value by step |
| `Home` | Set to minimum value (if defined) |
| `End` | Set to maximum value (if defined) |
| `Page Up` | Increase by large step (default: step × 10) |
| `Page Down` | Decrease by large step (default: step × 10) |
| Text editing keys | Direct value input |

**Note**: When `min`/`max` are undefined, `Home`/`End` keys have no effect.

## Focus Management

- Single focusable element: the input with `role="spinbutton"`
- `tabindex="0"` on input element
- `tabindex="-1"` when disabled
- Increment/decrement buttons have `tabindex="-1"` (not in tab order)
- **Button click does NOT move focus**: Focus stays on spinbutton after button interaction

## Test Checklist

### High Priority: ARIA

- [ ] `role="spinbutton"` exists on input
- [ ] `aria-valuenow` set to current value
- [ ] `aria-valuemin` only set when min is defined
- [ ] `aria-valuemax` only set when max is defined
- [ ] Accessible name required (label/aria-label/aria-labelledby)
- [ ] `aria-valuetext` set when valueText/format provided
- [ ] `aria-disabled="true"` when disabled
- [ ] `aria-readonly="true"` when readOnly
- [ ] `aria-invalid="true"` when value out of range

### High Priority: Keyboard

- [ ] `ArrowUp` increases value by step
- [ ] `ArrowDown` decreases value by step
- [ ] `Home` sets value to min (only when min defined)
- [ ] `End` sets value to max (only when max defined)
- [ ] `Page Up` increases by large step
- [ ] `Page Down` decreases by large step
- [ ] Value stops at min/max boundaries (no wrapping)
- [ ] Keys have no effect when disabled
- [ ] Keys have no effect when readOnly (except navigation)

### High Priority: Focus

- [ ] Input is focusable (tabindex="0")
- [ ] Input not focusable when disabled (tabindex="-1")
- [ ] Buttons have tabindex="-1"
- [ ] Focus stays on input after button click

### Medium Priority: Text Input

- [ ] Direct text input accepted
- [ ] Value validated on blur
- [ ] Invalid input reverts to previous value
- [ ] Value clamped to range on valid input (when min/max defined)
- [ ] Decimal step values work correctly

### Medium Priority: IME

- [ ] `aria-valuenow` keeps previous value during composition
- [ ] `onValueChange` not called during composition
- [ ] `onValueChange` called on compositionend

### Medium Priority: Buttons

- [ ] Increment button increases value
- [ ] Decrement button decreases value
- [ ] Increment button has `aria-label` or hidden from AT
- [ ] Decrement button has `aria-label` or hidden from AT
- [ ] Buttons work when showButtons=true
- [ ] Keyboard still works when showButtons=false

### Medium Priority: Accessibility

- [ ] No axe-core violations
- [ ] No axe violations when disabled
- [ ] No axe violations when readOnly

### Low Priority: Props

- [ ] `className` applied to container
- [ ] `data-*` attributes pass through
- [ ] `onValueChange` callback fires on change
- [ ] `defaultValue` sets initial value

## Implementation Notes

### Props Design

```typescript
// Label: one of these required (exclusive)
type LabelProps =
  | { label: string; 'aria-label'?: never; 'aria-labelledby'?: never }
  | { label?: never; 'aria-label': string; 'aria-labelledby'?: never }
  | { label?: never; 'aria-label'?: never; 'aria-labelledby': string };

// ValueText: exclusive with format
type ValueTextProps =
  | { valueText: string; format?: never }
  | { valueText?: never; format?: string }
  | { valueText?: never; format?: never };

type SpinbuttonBaseProps = {
  defaultValue?: number;
  min?: number;           // default: undefined (no limit)
  max?: number;           // default: undefined (no limit)
  step?: number;          // default: 1
  largeStep?: number;     // default: step * 10
  disabled?: boolean;
  readOnly?: boolean;
  showButtons?: boolean;  // default: true
  onValueChange?: (value: number) => void;
  className?: string;
  id?: string;
  'aria-describedby'?: string;
  'aria-invalid'?: boolean;
};

export type SpinbuttonProps = SpinbuttonBaseProps & LabelProps & ValueTextProps;
```

### Structure

```
┌─────────────────────────────────────────────────────────────┐
│ <div class="apg-spinbutton">                                │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <span class="apg-spinbutton-label" id="label-id">       │ │
│ │   Quantity                                              │ │
│ │ </span>                                                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <div class="apg-spinbutton-controls">  ← focus ring here│ │
│ │   <button tabindex="-1" aria-label="Decrement">−</button│ │
│ │   <input                                                │ │
│ │     role="spinbutton"                                   │ │
│ │     tabindex="0"                                        │ │
│ │     aria-valuenow="5"                                   │ │
│ │     aria-valuemin="0"      (only if min defined)        │ │
│ │     aria-valuemax="100"    (only if max defined)        │ │
│ │     aria-labelledby="label-id"                          │ │
│ │     inputmode="numeric"                                 │ │
│ │   />                                                    │ │
│ │   <button tabindex="-1" aria-label="Increment">+</button│ │
│ │ </div>                                                  │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Focus Ring**: The focus ring appears on the entire `.apg-spinbutton-controls` container (using `:has()` selector) rather than just the input, providing clearer visual feedback that includes the buttons.

### Value Calculation

```typescript
// Clamp value to range (only if min/max defined)
const clamp = (value: number, min?: number, max?: number) => {
  let result = value;
  if (min !== undefined) result = Math.max(min, result);
  if (max !== undefined) result = Math.min(max, result);
  return result;
};

// Guard against invalid step values
const ensureValidStep = (step: number): number => {
  return step > 0 ? step : 1;
};

// Round to step (with precision handling)
const roundToStep = (value: number, step: number, min?: number) => {
  const validStep = ensureValidStep(step);
  const base = min ?? 0;
  const steps = Math.round((value - base) / validStep);
  const result = base + steps * validStep;
  // Handle floating-point precision
  const decimals = (validStep.toString().split('.')[1] || '').length;
  return Number(result.toFixed(decimals));
};
```

### Keyboard Handler

```typescript
const handleKeyDown = (event: KeyboardEvent) => {
  if (disabled || (readOnly && !['Home', 'End'].includes(event.key))) return;

  let newValue = value;
  const effectiveLargeStep = largeStep ?? step * 10;

  switch (event.key) {
    case 'ArrowUp':
      newValue = value + step;
      event.preventDefault();
      break;
    case 'ArrowDown':
      newValue = value - step;
      event.preventDefault();
      break;
    case 'Home':
      if (min !== undefined) {
        newValue = min;
        event.preventDefault();
      }
      break;
    case 'End':
      if (max !== undefined) {
        newValue = max;
        event.preventDefault();
      }
      break;
    case 'PageUp':
      newValue = value + effectiveLargeStep;
      event.preventDefault();
      break;
    case 'PageDown':
      newValue = value - effectiveLargeStep;
      event.preventDefault();
      break;
    default:
      return;
  }

  setValue(clamp(roundToStep(newValue, step, min), min, max));
};
```

### IME Handling

```typescript
const [isComposing, setIsComposing] = useState(false);

const handleCompositionStart = () => setIsComposing(true);
const handleCompositionEnd = () => {
  setIsComposing(false);
  // Validate and update value
  validateAndUpdate(inputValue);
};

const handleInput = (e: React.ChangeEvent<HTMLInputElement>) => {
  setInputValue(e.target.value);
  if (!isComposing) {
    // Update aria-valuenow immediately for non-IME input
    const parsed = parseFloat(e.target.value);
    if (!isNaN(parsed)) {
      const newValue = clamp(roundToStep(parsed, step, min), min, max);
      setValue(newValue);
      onValueChange?.(newValue);
    }
  }
};
```

### Common Pitfalls

1. **Missing accessible name**: Always require label, aria-label, or aria-labelledby
2. **Unconditional aria-valuemin/max**: Only set when min/max props are defined
3. **IME input handling**: Don't update aria-valuenow during composition
4. **Button focus steal**: Buttons must not receive focus on click - use `mousedown.preventDefault()` to prevent focus shift
5. **Floating-point precision**: Round to step to avoid 0.1 + 0.2 = 0.30000000000000004
6. **Home/End without bounds**: These keys should have no effect when min/max undefined
7. **Invalid step values**: Guard against `step <= 0` which causes division errors in `roundToStep`. Use `ensureValidStep(step)` to default to 1
8. **Redundant callbacks**: Only fire `onValueChange` when the value actually changes, not on every input
9. **Label exclusivity**: When visible `label` exists, set `aria-label` to undefined to avoid conflicts

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

// Role test
it('has role="spinbutton"', () => {
  render(<Spinbutton aria-label="Quantity" />);
  expect(screen.getByRole('spinbutton')).toBeInTheDocument();
});

// ARIA values test
it('has aria-valuenow set to current value', () => {
  render(<Spinbutton defaultValue={5} aria-label="Quantity" />);
  expect(screen.getByRole('spinbutton')).toHaveAttribute('aria-valuenow', '5');
});

// No aria-valuemin when undefined
it('does not have aria-valuemin when min is undefined', () => {
  render(<Spinbutton aria-label="Quantity" />);
  expect(screen.getByRole('spinbutton')).not.toHaveAttribute('aria-valuemin');
});

// Keyboard: ArrowUp
it('increases value on ArrowUp', async () => {
  const user = userEvent.setup();
  render(<Spinbutton defaultValue={5} step={1} aria-label="Quantity" />);
  const spinbutton = screen.getByRole('spinbutton');

  await user.click(spinbutton);
  await user.keyboard('{ArrowUp}');

  expect(spinbutton).toHaveAttribute('aria-valuenow', '6');
});

// Boundary test with max
it('does not exceed max on ArrowUp', async () => {
  const user = userEvent.setup();
  render(<Spinbutton defaultValue={10} max={10} aria-label="Quantity" />);
  const spinbutton = screen.getByRole('spinbutton');

  await user.click(spinbutton);
  await user.keyboard('{ArrowUp}');

  expect(spinbutton).toHaveAttribute('aria-valuenow', '10');
});

// Home key without min (no effect)
it('Home key has no effect when min is undefined', async () => {
  const user = userEvent.setup();
  render(<Spinbutton defaultValue={50} aria-label="Quantity" />);
  const spinbutton = screen.getByRole('spinbutton');

  await user.click(spinbutton);
  await user.keyboard('{Home}');

  expect(spinbutton).toHaveAttribute('aria-valuenow', '50');
});

// Disabled test
it('does not change value when disabled', async () => {
  const user = userEvent.setup();
  render(<Spinbutton defaultValue={5} disabled aria-label="Quantity" />);
  const spinbutton = screen.getByRole('spinbutton');

  spinbutton.focus();
  await user.keyboard('{ArrowUp}');

  expect(spinbutton).toHaveAttribute('aria-valuenow', '5');
});

// Button focus test
it('focus stays on spinbutton after increment button click', async () => {
  const user = userEvent.setup();
  render(<Spinbutton defaultValue={5} aria-label="Quantity" />);
  const spinbutton = screen.getByRole('spinbutton');

  await user.click(spinbutton);
  await user.click(screen.getByRole('button', { name: /increment/i }));

  expect(spinbutton).toHaveFocus();
});

// axe test
it('has no axe violations', async () => {
  const { container } = render(<Spinbutton aria-label="Quantity" />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```
