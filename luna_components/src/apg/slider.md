# Slider Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/slider/

## Overview

A slider allows users to select a value from within a continuous range by moving a thumb along a track. Used for volume controls, brightness settings, range selections, etc. Interactive element requiring keyboard support and focus management.

## Native HTML vs Custom Implementation

**Prefer native `<input type="range">`** when possible - provides implicit semantics and keyboard support.

| Use Case | Recommended |
| --- | --- |
| Simple value input | Native `<input type="range">` |
| Custom styling needed | Custom `role="slider"` |
| Consistent keyboard behavior | Custom (browser varies) |
| Full visual control | Custom implementation |

## ARIA Requirements

### Roles

| Role | Element | Required | Description |
| --- | --- | --- | --- |
| `slider` | Thumb element | Yes | Identifies the element as a slider |

### Properties

| Attribute | Element | Values | Required | Notes |
| --- | --- | --- | --- | --- |
| `aria-valuenow` | slider | number | Yes | Current value |
| `aria-valuemin` | slider | number | Yes | Minimum value (default: 0) |
| `aria-valuemax` | slider | number | Yes | Maximum value (default: 100) |
| `aria-valuetext` | slider | string | No | Human-readable value (e.g., "50%") |
| `aria-label` | slider | string | Conditional | When no visible label |
| `aria-labelledby` | slider | ID ref | Conditional | When visible label exists |
| `aria-orientation` | slider | `horizontal` / `vertical` | No | Only set when vertical |
| `aria-disabled` | slider | `true` / `false` | No | When slider is disabled |

**Label Requirement**: One of `label`, `aria-label`, or `aria-labelledby` is required.
- `label` prop: Renders visible label element with auto-generated ID, slider references via `aria-labelledby`
- `aria-label`: Screen-reader only name directly on slider
- `aria-labelledby`: References external label element ID

### States

| Attribute | Element | Values | Required | Change Trigger |
| --- | --- | --- | --- | --- |
| `aria-valuenow` | slider | number | Yes | User interaction (keyboard/pointer) |
| `aria-valuetext` | slider | string | No | Value change (when format used) |

## Keyboard Support

| Key | Action |
| --- | --- |
| `ArrowRight` | Increase value by step |
| `ArrowUp` | Increase value by step |
| `ArrowLeft` | Decrease value by step |
| `ArrowDown` | Decrease value by step |
| `Home` | Set to minimum value |
| `End` | Set to maximum value |
| `Page Up` | Increase by large step (default: step × 10) |
| `Page Down` | Decrease by large step (default: step × 10) |

**Note**: Arrow keys should NOT wrap - value stops at min/max boundaries.

## Focus Management

- Single focusable element: the thumb with `role="slider"`
- `tabindex="0"` on thumb element
- `tabindex="-1"` when disabled
- No roving tabindex (single control)
- **Pointer interaction moves focus**: On track click or thumb drag start, call `thumb.focus()` to ensure keyboard accessibility after pointer use

## Test Checklist

### High Priority: Keyboard

- [ ] `ArrowRight` increases value by step
- [ ] `ArrowLeft` decreases value by step
- [ ] `ArrowUp` increases value by step
- [ ] `ArrowDown` decreases value by step
- [ ] `Home` sets value to min
- [ ] `End` sets value to max
- [ ] `Page Up` increases by large step
- [ ] `Page Down` decreases by large step
- [ ] Value does not exceed min/max
- [ ] Keys have no effect when disabled

### High Priority: ARIA

- [ ] `role="slider"` exists on thumb
- [ ] `aria-valuenow` set to current value
- [ ] `aria-valuemin` always set
- [ ] `aria-valuemax` always set
- [ ] Accessible name required (label/aria-label/aria-labelledby)
- [ ] `aria-valuetext` set when valueText/format provided
- [ ] `aria-orientation="vertical"` only when vertical
- [ ] `aria-disabled="true"` when disabled

### High Priority: Focus

- [ ] Thumb is focusable (tabindex="0")
- [ ] Thumb not focusable when disabled (tabindex="-1")
- [ ] Focus ring visible on focus-visible
- [ ] Track click moves focus to thumb
- [ ] Thumb drag start moves focus to thumb
- [ ] Focus remains on thumb during drag

### Medium Priority: Pointer

- [ ] Thumb drag changes value
- [ ] Track click sets value to clicked position
- [ ] Drag continues when pointer leaves thumb
- [ ] Touch drag works
- [ ] Vertical slider drag works correctly
- [ ] Track click does not change value when disabled
- [ ] Thumb drag does not change value when disabled

### Medium Priority: Accessibility

- [ ] No axe-core violations
- [ ] No axe violations when disabled
- [ ] Focus visible indicator meets WCAG

### Low Priority: Props

- [ ] `className` applied to container
- [ ] `data-*` attributes pass through
- [ ] `onValueChange` callback fires on change
- [ ] `defaultValue` sets initial value
- [ ] Decimal `step` values work correctly

## Implementation Notes

### Props Design (Exclusive Types)

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

type SliderBaseProps = {
  defaultValue?: number;
  min?: number;           // default: 0
  max?: number;           // default: 100
  step?: number;          // default: 1
  largeStep?: number;     // default: step * 10
  orientation?: 'horizontal' | 'vertical';
  disabled?: boolean;
  showValue?: boolean;    // default: true
  onValueChange?: (value: number) => void;
  className?: string;
  id?: string;
  'aria-describedby'?: string;
};

export type SliderProps = SliderBaseProps & LabelProps & ValueTextProps;
```

### Structure

```
┌─────────────────────────────────────────────────────────┐
│ <div class="apg-slider">                                │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ <span class="apg-slider-label" id="label-id">       │ │
│ │   Volume                                            │ │
│ │ </span>                                             │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ <div class="apg-slider-track">                      │ │
│ │   <div class="apg-slider-fill" style="width: 50%"/> │ │
│ │   <div                                              │ │
│ │     role="slider"                                   │ │
│ │     class="apg-slider-thumb"                        │ │
│ │     tabindex="0"                                    │ │
│ │     aria-valuenow="50"                              │ │
│ │     aria-valuemin="0"                               │ │
│ │     aria-valuemax="100"                             │ │
│ │     aria-labelledby="label-id"                      │ │
│ │     style="left: 50%"                               │ │
│ │   />                                                │ │
│ │ </div>                                              │ │
│ └─────────────────────────────────────────────────────┘ │
│ <span class="apg-slider-value" aria-hidden="true">50</span>
└─────────────────────────────────────────────────────────┘
```

### Value Calculation

```typescript
// Clamp value to range
const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value));

// Round to step
const roundToStep = (value: number, step: number, min: number) => {
  const steps = Math.round((value - min) / step);
  return min + steps * step;
};

// Calculate percentage for visual position
const getPercent = (value: number, min: number, max: number) =>
  ((value - min) / (max - min)) * 100;

// Calculate value from pointer position
const getValueFromPosition = (
  position: number,   // mouse/touch X or Y
  trackStart: number, // track left/top
  trackSize: number,  // track width/height
  min: number,
  max: number,
  step: number,
  isVertical: boolean
) => {
  const percent = isVertical
    ? 1 - (position - trackStart) / trackSize  // Invert for vertical
    : (position - trackStart) / trackSize;
  const rawValue = min + percent * (max - min);
  return clamp(roundToStep(rawValue, step, min), min, max);
};
```

### Keyboard Handler

```typescript
const handleKeyDown = (event: KeyboardEvent) => {
  if (disabled) return;

  let newValue = value;
  const effectiveLargeStep = largeStep ?? step * 10;

  switch (event.key) {
    case 'ArrowRight':
    case 'ArrowUp':
      newValue = value + step;
      break;
    case 'ArrowLeft':
    case 'ArrowDown':
      newValue = value - step;
      break;
    case 'Home':
      newValue = min;
      break;
    case 'End':
      newValue = max;
      break;
    case 'PageUp':
      newValue = value + effectiveLargeStep;
      break;
    case 'PageDown':
      newValue = value - effectiveLargeStep;
      break;
    default:
      return; // Don't prevent default for other keys
  }

  event.preventDefault();
  setValue(clamp(roundToStep(newValue, step, min), min, max));
};
```

### Pointer Handler (Drag)

Pointer events should be handled on **both the thumb and the track**:
- **Track click**: Set value to clicked position immediately, move focus to thumb
- **Thumb drag**: Use pointer capture for smooth dragging even when pointer leaves thumb

```typescript
// Track: handle click to jump to position
const handleTrackPointerDown = (event: PointerEvent) => {
  if (disabled) return;
  event.preventDefault();

  updateValueFromPointer(event);
  thumb.focus(); // Move focus after track click
};

// Thumb: handle drag with pointer capture
const handleThumbPointerDown = (event: PointerEvent) => {
  if (disabled) return;

  event.preventDefault();
  thumb.setPointerCapture(event.pointerId);
  thumb.focus(); // Ensure focus on drag start
};

const handlePointerMove = (event: PointerEvent) => {
  if (!thumb.hasPointerCapture(event.pointerId)) return;
  updateValueFromPointer(event);
};

const handlePointerUp = (event: PointerEvent) => {
  thumb.releasePointerCapture(event.pointerId);
};
```

### Format Prop

The `format` prop accepts a string pattern for displaying values. Available placeholders:
- `{value}` - Current value
- `{min}` - Minimum value
- `{max}` - Maximum value

```typescript
// Examples
<Slider format="{value}%" />           // "50%"
<Slider format="{value} of {max}" />   // "3 of 5"
```

This is used for both the visual display and `aria-valuetext`. Using a string pattern instead of a function ensures compatibility with Astro Islands (functions cannot be serialized).

### Common Pitfalls

1. **Missing accessible name**: Always require label, aria-label, or aria-labelledby
2. **Keyboard wrapping**: Arrow keys should NOT wrap - stop at boundaries
3. **Visual-ARIA mismatch**: Thumb position must match aria-valuenow
4. **Vertical inversion**: Y-axis increases downward, but value increases upward
5. **Floating-point precision**: Round to step to avoid 0.1 + 0.2 = 0.30000000000000004
6. **Pointer capture**: Use setPointerCapture for drag outside thumb
7. **Touch scrolling**: Use `touch-action: none` to prevent scroll during drag

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

// Role test
it('has role="slider"', () => {
  render(<Slider aria-label="Volume" />);
  expect(screen.getByRole('slider')).toBeInTheDocument();
});

// ARIA values test
it('has correct aria-valuenow/min/max', () => {
  render(<Slider defaultValue={50} min={0} max={100} aria-label="Volume" />);
  const slider = screen.getByRole('slider');
  expect(slider).toHaveAttribute('aria-valuenow', '50');
  expect(slider).toHaveAttribute('aria-valuemin', '0');
  expect(slider).toHaveAttribute('aria-valuemax', '100');
});

// Keyboard: ArrowRight
it('increases value on ArrowRight', async () => {
  const user = userEvent.setup();
  render(<Slider defaultValue={50} step={1} aria-label="Volume" />);
  const slider = screen.getByRole('slider');

  await user.click(slider);
  await user.keyboard('{ArrowRight}');

  expect(slider).toHaveAttribute('aria-valuenow', '51');
});

// Keyboard: Home
it('sets min value on Home', async () => {
  const user = userEvent.setup();
  render(<Slider defaultValue={50} min={0} aria-label="Volume" />);
  const slider = screen.getByRole('slider');

  await user.click(slider);
  await user.keyboard('{Home}');

  expect(slider).toHaveAttribute('aria-valuenow', '0');
});

// Boundary test
it('does not exceed max on ArrowRight', async () => {
  const user = userEvent.setup();
  render(<Slider defaultValue={100} max={100} aria-label="Volume" />);
  const slider = screen.getByRole('slider');

  await user.click(slider);
  await user.keyboard('{ArrowRight}');

  expect(slider).toHaveAttribute('aria-valuenow', '100');
});

// Disabled test
it('does not change value when disabled', async () => {
  const user = userEvent.setup();
  render(<Slider defaultValue={50} disabled aria-label="Volume" />);
  const slider = screen.getByRole('slider');

  await user.click(slider);
  await user.keyboard('{ArrowRight}');

  expect(slider).toHaveAttribute('aria-valuenow', '50');
});

// aria-valuetext test
it('sets aria-valuetext with format', () => {
  render(
    <Slider
      defaultValue={50}
      format="{value}%"
      aria-label="Volume"
    />
  );
  expect(screen.getByRole('slider')).toHaveAttribute('aria-valuetext', '50%');
});

// Vertical orientation test
it('sets aria-orientation for vertical slider', () => {
  render(<Slider orientation="vertical" aria-label="Volume" />);
  expect(screen.getByRole('slider')).toHaveAttribute('aria-orientation', 'vertical');
});

// axe test
it('has no axe violations', async () => {
  const { container } = render(<Slider aria-label="Volume" />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});

// Callback test
it('calls onValueChange on value change', async () => {
  const handleChange = vi.fn();
  const user = userEvent.setup();
  render(<Slider defaultValue={50} onValueChange={handleChange} aria-label="Volume" />);

  await user.click(screen.getByRole('slider'));
  await user.keyboard('{ArrowRight}');

  expect(handleChange).toHaveBeenCalledWith(51);
});
```
