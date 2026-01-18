# Dialog Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/

## Overview

A dialog is a window overlaid on the primary content, requiring user interaction. Modal dialogs trap focus and prevent interaction with content outside the dialog.

## ARIA Requirements

### Roles

| Role     | Element          | Description                              |
| -------- | ---------------- | ---------------------------------------- |
| `dialog` | Dialog container | Indicates the element is a dialog window |

### Properties

| Attribute          | Element | Values                      | Required | Notes                            |
| ------------------ | ------- | --------------------------- | -------- | -------------------------------- |
| `aria-modal`       | dialog  | `true`                      | Yes      | Indicates this is a modal dialog |
| `aria-labelledby`  | dialog  | ID reference to title       | Yes      | References the dialog title      |
| `aria-describedby` | dialog  | ID reference to description | No       | References optional description  |

## Keyboard Support

| Key           | Action                                                   |
| ------------- | -------------------------------------------------------- |
| `Tab`         | Move to next focusable element (loops within dialog)     |
| `Shift + Tab` | Move to previous focusable element (loops within dialog) |
| `Escape`      | Close the dialog                                         |

## Focus Management

| Event         | Behavior                                               |
| ------------- | ------------------------------------------------------ |
| Dialog opens  | Focus moves to first focusable element inside dialog   |
| Dialog closes | Focus returns to the element that triggered the dialog |
| Focus trap    | Tab/Shift+Tab cycles only within dialog                |
| Background    | Content outside dialog is inert (not focusable)        |

## Test Checklist

### High Priority: Keyboard

- [ ] Escape closes the dialog
- [ ] Tab moves to next focusable element
- [ ] Shift+Tab moves to previous focusable element
- [ ] Tab wraps from last to first element
- [ ] Shift+Tab wraps from first to last element

### High Priority: ARIA

- [ ] Container has `role="dialog"`
- [ ] Dialog has `aria-modal="true"`
- [ ] Dialog has `aria-labelledby` referencing title
- [ ] Title element id matches `aria-labelledby` value

### High Priority: Focus Management

- [ ] Focus moves into dialog on open
- [ ] Focus returns to trigger on close
- [ ] Focus is trapped within dialog
- [ ] Background content is inert

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)
- [ ] Page scrolling is disabled while open
- [ ] Close button has accessible label

## Implementation Notes

```
Structure:
┌─────────────────────────────────────┐
│ Dialog Title          [X]          │  ← aria-labelledby target
├─────────────────────────────────────┤
│                                     │
│ Dialog content...                   │  ← aria-describedby target (optional)
│                                     │
│ [Cancel]  [Confirm]                 │  ← focusable elements
└─────────────────────────────────────┘

Focus Trap:
- First focusable → ... → Last focusable → First focusable (loop)
- Store trigger element reference before opening
- Restore focus to trigger on close
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Focus trap test
it('traps focus within dialog', async () => {
  const user = userEvent.setup();
  render(<Dialog open />);

  const closeButton = screen.getByRole('button', { name: /close/i });
  const confirmButton = screen.getByRole('button', { name: /confirm/i });

  closeButton.focus();
  await user.tab();
  // Focus should cycle within dialog
});

// Escape closes dialog
it('closes on Escape', async () => {
  const onClose = vi.fn();
  const user = userEvent.setup();
  render(<Dialog open onClose={onClose} />);

  await user.keyboard('{Escape}');
  expect(onClose).toHaveBeenCalled();
});

// Focus restoration
it('returns focus to trigger on close', async () => {
  const user = userEvent.setup();
  render(<DialogWithTrigger />);

  const trigger = screen.getByRole('button', { name: /open/i });
  await user.click(trigger);
  await user.keyboard('{Escape}');

  expect(trigger).toHaveFocus();
});
```
