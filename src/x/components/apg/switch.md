# Switch Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/switch/

## Overview

A switch is a type of checkbox that represents on/off values, as opposed to checked/unchecked. It uses `role="switch"` and `aria-checked` instead of a checkbox.

## ARIA Requirements

### Roles

| Role     | Element        | Description          |
| -------- | -------------- | -------------------- |
| `switch` | Switch element | On/off toggle widget |

### States

| Attribute       | Element | Values            | Required | Change Trigger      |
| --------------- | ------- | ----------------- | -------- | ------------------- |
| `aria-checked`  | switch  | `true` \| `false` | Yes      | Click, Enter, Space |
| `aria-disabled` | switch  | `true`            | No       | Only when disabled  |

## Keyboard Support

| Key     | Action                       |
| ------- | ---------------------------- |
| `Space` | Toggle switch state (on/off) |
| `Enter` | Toggle switch state (on/off) |

## Accessible Naming

One of these is required:

- **Visible label** (recommended) - Child content as accessible name
- `aria-label` - Invisible label
- `aria-labelledby` - Reference to external label element

## Visual Design (WCAG 1.4.1)

Do not rely solely on color to indicate state:

- **Thumb position** - Left = off, Right = on
- **Checkmark icon** - Visible only when on
- **Forced colors mode** - Use system colors for Windows High Contrast

## Test Checklist

### High Priority: Keyboard

- [ ] Space toggles state
- [ ] Enter toggles state
- [ ] Tab navigates to switch
- [ ] Disabled switch behavior correct

### High Priority: ARIA

- [ ] Has `role="switch"`
- [ ] Has `aria-checked` attribute
- [ ] `aria-checked` toggles between `true` and `false`
- [ ] Disabled state has `aria-disabled="true"`
- [ ] Has accessible name

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)
- [ ] State distinguishable without color alone

## Implementation Notes

```
Structure:
<button role="switch" aria-checked="false">
  <span class="switch-track">
    <span class="switch-thumb" />
  </span>
  Enable notifications
</button>

Visual States:
┌─────────┬────────────┐
│ OFF     │ ON         │
├─────────┼────────────┤
│ [○    ] │ [    ✓]   │
│ Left    │ Right+icon │
└─────────┴────────────┘

Switch vs Checkbox:
- Switch: immediate effect, on/off semantics
- Checkbox: may require form submit, checked/unchecked semantics

Use Switch when:
- Action takes effect immediately
- Represents on/off, enable/disable
- Similar to a physical switch
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Toggle test
it('toggles aria-checked on click', async () => {
  const user = userEvent.setup();
  render(<Switch>Enable</Switch>);

  const switchEl = screen.getByRole('switch');
  expect(switchEl).toHaveAttribute('aria-checked', 'false');

  await user.click(switchEl);
  expect(switchEl).toHaveAttribute('aria-checked', 'true');
});

// Keyboard test
it('toggles on Space key', async () => {
  const user = userEvent.setup();
  render(<Switch>Enable</Switch>);

  const switchEl = screen.getByRole('switch');
  switchEl.focus();

  await user.keyboard(' ');
  expect(switchEl).toHaveAttribute('aria-checked', 'true');
});

// Accessible name test
it('has accessible name', () => {
  render(<Switch>Enable notifications</Switch>);
  expect(screen.getByRole('switch', { name: /enable notifications/i }))
    .toBeInTheDocument();
});
```
