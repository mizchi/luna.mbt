# Tooltip Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/
> Note: This pattern is marked as "work in progress" by WAI.

## Overview

A tooltip is a popup that displays information related to an element when the element receives keyboard focus or the mouse hovers over it.

## ARIA Requirements

### Roles

| Role      | Element       | Description                             |
| --------- | ------------- | --------------------------------------- |
| `tooltip` | Tooltip popup | Contextual popup displaying description |

### Properties

| Attribute          | Element | Values            | Required    | Notes                        |
| ------------------ | ------- | ----------------- | ----------- | ---------------------------- |
| `aria-describedby` | Trigger | ID of tooltip     | Conditional | Only when tooltip is visible |
| `aria-hidden`      | Tooltip | `true` \| `false` | No          | Hides from AT when closed    |

## Keyboard Support

| Key      | Action                                   |
| -------- | ---------------------------------------- |
| `Escape` | Close the tooltip                        |
| `Tab`    | Focus navigation; tooltip shows on focus |

## Focus/Hover Behavior

| Event         | Behavior                      |
| ------------- | ----------------------------- |
| Focus trigger | Tooltip appears (after delay) |
| Blur trigger  | Tooltip hides                 |
| Hover trigger | Tooltip appears (after delay) |
| Leave trigger | Tooltip hides                 |

## Important Constraints

- **Tooltip never receives focus** - Must not be focusable
- **No interactive content** - Use Dialog/Popover if interaction needed
- **Configurable delay** - Prevents accidental activation

## Test Checklist

### High Priority: Keyboard

- [ ] Escape closes tooltip
- [ ] Tooltip appears on trigger focus
- [ ] Tooltip hides on trigger blur

### High Priority: ARIA

- [ ] Tooltip has `role="tooltip"`
- [ ] Trigger has `aria-describedby` when tooltip visible
- [ ] `aria-describedby` removed when tooltip hidden
- [ ] Tooltip has correct `aria-hidden` state

### High Priority: Focus Management

- [ ] Tooltip is NOT focusable
- [ ] Focus stays on trigger when tooltip shows
- [ ] Tab moves to next element (not into tooltip)

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

```
Structure:
        ┌─────────────────┐
        │ Tooltip content │  ← role="tooltip", id="tip-1"
        └────────┬────────┘
                 │
    ┌────────────▼────────────┐
    │ [Trigger Element]       │  ← aria-describedby="tip-1" (when visible)
    └─────────────────────────┘

State Flow:
1. Initial: tooltip hidden, aria-describedby absent
2. Focus/Hover: tooltip visible, aria-describedby set
3. Blur/Leave/Escape: tooltip hidden, aria-describedby removed

Do NOT:
- Put focusable elements in tooltip
- Make tooltip itself focusable
- Use for content requiring interaction
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Show on focus
it('shows tooltip on focus', async () => {
  render(<TooltipDemo />);

  const trigger = screen.getByRole('button');
  trigger.focus();

  expect(await screen.findByRole('tooltip')).toBeVisible();
});

// Escape closes
it('closes on Escape', async () => {
  const user = userEvent.setup();
  render(<TooltipDemo />);

  const trigger = screen.getByRole('button');
  trigger.focus();
  await screen.findByRole('tooltip');

  await user.keyboard('{Escape}');

  expect(screen.queryByRole('tooltip')).not.toBeVisible();
});

// aria-describedby test
it('sets aria-describedby when visible', async () => {
  render(<TooltipDemo />);

  const trigger = screen.getByRole('button');
  expect(trigger).not.toHaveAttribute('aria-describedby');

  trigger.focus();
  const tooltip = await screen.findByRole('tooltip');

  expect(trigger).toHaveAttribute('aria-describedby', tooltip.id);
});
```
