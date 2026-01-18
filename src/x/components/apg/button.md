# Toggle Button Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/button/

## Overview

A toggle button is a two-state button that can be either pressed or not pressed. It uses `aria-pressed` to communicate state to assistive technology.

## ARIA Requirements

### Roles

| Role     | Element        | Description                  |
| -------- | -------------- | ---------------------------- |
| `button` | Button element | Implicit role for `<button>` |

### States

| Attribute      | Element | Values                         | Required | Change Trigger      |
| -------------- | ------- | ------------------------------ | -------- | ------------------- |
| `aria-pressed` | button  | `true` \| `false` \| `"mixed"` | Yes      | Click, Enter, Space |

## Keyboard Support

| Key     | Action                  |
| ------- | ----------------------- |
| `Space` | Toggle the button state |
| `Enter` | Toggle the button state |

## Test Checklist

### High Priority: Keyboard

- [ ] Space toggles state
- [ ] Enter toggles state
- [ ] Tab navigates to button
- [ ] Disabled button is skipped by Tab

### High Priority: ARIA

- [ ] Has `role="button"` (implicit for `<button>`)
- [ ] Has `aria-pressed` attribute
- [ ] `aria-pressed` toggles between `true` and `false`
- [ ] Has `type="button"` (prevents form submission)
- [ ] Disabled state uses `disabled` attribute

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)
- [ ] Has accessible name (visible text or `aria-label`)

## Implementation Notes

```
Structure:
<button type="button" aria-pressed="false">
  Mute
</button>

State Changes:
- Initial: aria-pressed="false" (not pressed)
- After click: aria-pressed="true" (pressed)

Use type="button":
- Prevents accidental form submission
- Native <button> defaults to type="submit"

Tri-state (rare):
- aria-pressed="mixed" for partially selected state
- Example: "Select All" when some items selected
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Toggle on click
it('toggles aria-pressed on click', async () => {
  const user = userEvent.setup();
  render(<ToggleButton>Mute</ToggleButton>);

  const button = screen.getByRole('button');
  expect(button).toHaveAttribute('aria-pressed', 'false');

  await user.click(button);
  expect(button).toHaveAttribute('aria-pressed', 'true');

  await user.click(button);
  expect(button).toHaveAttribute('aria-pressed', 'false');
});

// Keyboard toggle
it('toggles on Space key', async () => {
  const user = userEvent.setup();
  render(<ToggleButton>Mute</ToggleButton>);

  const button = screen.getByRole('button');
  button.focus();

  await user.keyboard(' ');
  expect(button).toHaveAttribute('aria-pressed', 'true');
});

// Has type="button"
it('has type="button"', () => {
  render(<ToggleButton>Mute</ToggleButton>);
  expect(screen.getByRole('button')).toHaveAttribute('type', 'button');
});
```
