# Toolbar Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/

## Overview

A toolbar is a container for grouping a set of controls, such as buttons, toggle buttons, or menus.

## ARIA Requirements

### Roles

| Role        | Element         | Description                              |
| ----------- | --------------- | ---------------------------------------- |
| `toolbar`   | Container       | Container for grouping controls          |
| `button`    | Button elements | Implicit role for `<button>`             |
| `separator` | Separator       | Visual/semantic separator between groups |

### Properties

| Attribute          | Element | Values                         | Required | Notes                     |
| ------------------ | ------- | ------------------------------ | -------- | ------------------------- |
| `aria-label`       | toolbar | String                         | Yes\*    | Accessible name           |
| `aria-labelledby`  | toolbar | ID reference                   | Yes\*    | Alternative to aria-label |
| `aria-orientation` | toolbar | `"horizontal"` \| `"vertical"` | No       | Default: horizontal       |

> \*Either `aria-label` or `aria-labelledby` is required

### States

| Attribute      | Element       | Values            | Required          | Change Trigger      |
| -------------- | ------------- | ----------------- | ----------------- | ------------------- |
| `aria-pressed` | toggle button | `true` \| `false` | Yes (for toggles) | Click, Enter, Space |

## Keyboard Support

| Key                        | Action                                           |
| -------------------------- | ------------------------------------------------ |
| `Tab`                      | Move focus into/out of toolbar (single tab stop) |
| `ArrowRight` / `ArrowLeft` | Navigate between controls (horizontal)           |
| `ArrowDown` / `ArrowUp`    | Navigate between controls (vertical)             |
| `Home`                     | Move focus to first control                      |
| `End`                      | Move focus to last control                       |
| `Enter` / `Space`          | Activate button / toggle pressed state           |

## Focus Management (Roving Tabindex)

- Only one control has `tabIndex="0"` at a time
- Other controls have `tabIndex="-1"`
- Arrow keys move focus between controls
- Disabled controls and separators are skipped
- Focus does NOT wrap (stops at edges)

## Test Checklist

### High Priority: Keyboard

- [ ] ArrowRight moves to next control (horizontal)
- [ ] ArrowLeft moves to previous control (horizontal)
- [ ] ArrowDown moves to next control (vertical)
- [ ] ArrowUp moves to previous control (vertical)
- [ ] Home moves to first control
- [ ] End moves to last control
- [ ] Enter/Space activates button
- [ ] Enter/Space toggles toggle button
- [ ] Disabled controls are skipped
- [ ] Separators are skipped
- [ ] Focus does not wrap at edges

### High Priority: ARIA

- [ ] Container has `role="toolbar"`
- [ ] Toolbar has `aria-label` or `aria-labelledby`
- [ ] Toggle buttons have `aria-pressed`
- [ ] `aria-orientation` reflects orientation

### High Priority: Focus Management

- [ ] Only focused control has `tabIndex="0"`
- [ ] Other controls have `tabIndex="-1"`
- [ ] Tab enters toolbar at last focused control
- [ ] Tab exits toolbar (single tab stop)

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

```
Structure (horizontal):
┌──────────────────────────────────────────────────┐
│ [B] [I] [U]  │  [Left] [Center] [Right]  │  [🔗] │
│              ↑                            ↑      │
│          separator                    separator  │
└──────────────────────────────────────────────────┘
   ↑
   toolbar (role="toolbar", aria-label="Text formatting")

Tab Stop Behavior:
- Tab → enters toolbar at last focused control
- Tab again → exits toolbar to next focusable element
- Arrow keys → navigate within toolbar

Roving Tabindex:
[tabIndex=0] [tabIndex=-1] [tabIndex=-1] ...
     ↑
   focused
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Arrow navigation test
it('ArrowRight moves to next control', async () => {
  const user = userEvent.setup();
  render(<Toolbar aria-label="Formatting" />);

  const boldButton = screen.getByRole('button', { name: 'Bold' });
  boldButton.focus();

  await user.keyboard('{ArrowRight}');

  const italicButton = screen.getByRole('button', { name: 'Italic' });
  expect(italicButton).toHaveFocus();
});

// Toggle button test
it('toggles aria-pressed on click', async () => {
  const user = userEvent.setup();
  render(<Toolbar aria-label="Formatting" />);

  const boldButton = screen.getByRole('button', { name: 'Bold' });
  expect(boldButton).toHaveAttribute('aria-pressed', 'false');

  await user.click(boldButton);
  expect(boldButton).toHaveAttribute('aria-pressed', 'true');
});

// Roving tabindex test
it('maintains roving tabindex', async () => {
  const user = userEvent.setup();
  render(<Toolbar aria-label="Formatting" />);

  const buttons = screen.getAllByRole('button');

  buttons[0].focus();
  expect(buttons[0]).toHaveAttribute('tabIndex', '0');
  expect(buttons[1]).toHaveAttribute('tabIndex', '-1');

  await user.keyboard('{ArrowRight}');
  expect(buttons[0]).toHaveAttribute('tabIndex', '-1');
  expect(buttons[1]).toHaveAttribute('tabIndex', '0');
});
```
