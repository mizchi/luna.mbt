# Meter Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/meter/

## Overview

A meter displays a numeric value within a defined range as a graphical gauge. Used for battery level, storage usage, CPU load, etc. Non-interactive (no keyboard/focus management required).

## Native HTML vs Custom Implementation

**Prefer native `<meter>`** when possible - provides implicit semantics without ARIA.

| Use Case | Recommended |
| --- | --- |
| Simple value display | Native `<meter>` |
| Custom styling needed | Custom `role="meter"` |
| `low`/`high`/`optimum` thresholds | Native `<meter>` |
| Full visual control | Custom implementation |

## ARIA Requirements

### Roles

| Role | Element | Required | Description |
| --- | --- | --- | --- |
| `meter` | Container | Yes | Identifies the element as a meter |

### Properties

| Attribute | Element | Values | Required | Notes |
| --- | --- | --- | --- | --- |
| `aria-valuenow` | meter | number | Yes | Current value (clamped to min/max) |
| `aria-valuemin` | meter | number | Yes | Minimum value (default: 0) |
| `aria-valuemax` | meter | number | Yes | Maximum value (default: 100) |
| `aria-valuetext` | meter | string | No | Human-readable value (e.g., "75%") |
| `aria-label` | meter | string | Conditional | When no visible label |
| `aria-labelledby` | meter | ID ref | Conditional | When visible label exists |

**Label Requirement**: One of `label`, `aria-label`, or `aria-labelledby` is required.

### States

No dynamic states. `aria-valuenow` updates when value changes.

## Keyboard Support

**Not applicable** - Meter is a display-only element, not interactive.

## Focus Management

**Not applicable** - Meter should not receive focus by default. Only focusable if `tabIndex` is explicitly provided.

## Test Checklist

### High Priority: ARIA

- [ ] `role="meter"` exists
- [ ] `aria-valuenow` set to current value
- [ ] `aria-valuemin` always set (even with default)
- [ ] `aria-valuemax` always set (even with default)
- [ ] Accessible name required (label/aria-label/aria-labelledby)
- [ ] `aria-valuetext` set when `valueText` or `format` provided
- [ ] Value clamped to min/max range when `clamp=true`

### High Priority: Accessibility

- [ ] No axe-core violations
- [ ] Not focusable by default (no tabIndex)

### Medium Priority: Edge Cases

- [ ] Decimal values handled correctly
- [ ] Negative min/max range works
- [ ] Large values don't break display
- [ ] `valueText` overrides `format`
- [ ] `tabIndex` opt-in makes it focusable

### Low Priority: Negative Tests

- [ ] `min >= max` throws warning/error
- [ ] `NaN`/`Infinity` value throws warning/error
- [ ] Missing label triggers axe warning

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

export type MeterProps = {
  value: number;
  min?: number;      // default: 0
  max?: number;      // default: 100
  clamp?: boolean;   // default: true
  showValue?: boolean; // default: true
  id?: string;
  className?: string;
  tabIndex?: number;
  'aria-describedby'?: string;
} & LabelProps & ValueTextProps;
```

### Structure

```
┌─────────────────────────────────────────────────────────┐
│ <div> role="meter"                                      │
│   aria-valuenow="75"                                    │
│   aria-valuemin="0"                                     │
│   aria-valuemax="100"                                   │
│   aria-valuetext="75%"                                  │
│   aria-label="CPU Usage"                                │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ <span> label (if visible)                           │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ <div> class="meter-track" aria-hidden="true"        │ │
│ │   <div> class="meter-fill" style="width: 75%"       │ │
│ └─────────────────────────────────────────────────────┘ │
│ <span> class="meter-value" aria-hidden="true">75%</span>│
└─────────────────────────────────────────────────────────┘
```

### Value Clamping

```typescript
const clampNumber = (value: number, min: number, max: number, clamp: boolean) => {
  if (!Number.isFinite(value) || !Number.isFinite(min) || !Number.isFinite(max)) {
    return value; // Let validation handle non-finite
  }
  return clamp ? Math.min(max, Math.max(min, value)) : value;
};
```

### Format Prop

The `format` prop accepts a string pattern for displaying values. Available placeholders:
- `{value}` - Current value
- `{min}` - Minimum value
- `{max}` - Maximum value

```typescript
// Examples
<Meter value={75} format="{value}%" />           // "75%"
<Meter value={3} max={5} format="{value} of {max}" />   // "3 of 5"
```

This is used for both the visual display and `aria-valuetext`. Using a string pattern instead of a function ensures compatibility with Astro Islands (functions cannot be serialized).

### Common Pitfalls

1. **Missing accessible name**: Always require label, aria-label, or aria-labelledby
2. **Conflicting props**: Use TypeScript exclusive types to prevent aria-valuenow override via rest props
3. **Visual-ARIA mismatch**: Ensure visual bar width matches aria-valuenow percentage
4. **Non-finite values**: Validate and warn on NaN/Infinity

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

// Role test
it('has role="meter"', () => {
  render(<Meter value={50} aria-label="Progress" />);
  expect(screen.getByRole('meter')).toBeInTheDocument();
});

// ARIA values test
it('has correct aria-valuenow/min/max', () => {
  render(<Meter value={75} min={0} max={100} aria-label="CPU" />);
  const meter = screen.getByRole('meter');
  expect(meter).toHaveAttribute('aria-valuenow', '75');
  expect(meter).toHaveAttribute('aria-valuemin', '0');
  expect(meter).toHaveAttribute('aria-valuemax', '100');
});

// Clamping test
it('clamps value to min/max range', () => {
  render(<Meter value={150} min={0} max={100} aria-label="Progress" />);
  expect(screen.getByRole('meter')).toHaveAttribute('aria-valuenow', '100');
});

// aria-valuetext test
it('sets aria-valuetext when valueText provided', () => {
  render(<Meter value={75} valueText="75 percent" aria-label="Progress" />);
  expect(screen.getByRole('meter')).toHaveAttribute('aria-valuetext', '75 percent');
});

// format test
it('uses format for aria-valuetext', () => {
  render(<Meter value={75} min={0} max={100} format="{value}%" aria-label="Progress" />);
  expect(screen.getByRole('meter')).toHaveAttribute('aria-valuetext', '75%');
});

// Not focusable by default
it('is not focusable by default', () => {
  render(<Meter value={50} aria-label="Progress" />);
  expect(screen.getByRole('meter')).not.toHaveAttribute('tabindex');
});

// axe test
it('has no axe violations', async () => {
  const { container } = render(<Meter value={50} aria-label="Progress" />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});

// Negative range test
it('handles negative min/max range', () => {
  render(<Meter value={0} min={-50} max={50} aria-label="Temperature" />);
  const meter = screen.getByRole('meter');
  expect(meter).toHaveAttribute('aria-valuenow', '0');
  expect(meter).toHaveAttribute('aria-valuemin', '-50');
  expect(meter).toHaveAttribute('aria-valuemax', '50');
});
```
