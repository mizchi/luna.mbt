# Alert Dialog Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/

## Overview

An alert dialog is a modal dialog that interrupts the user's workflow to communicate an important message and require a response. Unlike regular dialogs, it uses `role="alertdialog"` which may trigger system alert sounds in assistive technologies.

## Key Differences from Dialog

| Feature | Dialog | Alert Dialog | Reason |
|---------|--------|--------------|--------|
| `role` | `dialog` | `alertdialog` | Signals urgency to AT |
| `aria-describedby` | Optional | **Required** | Alert message is mandatory |
| `Escape` key | Always closes | **Disabled by default** | Prevent accidental dismissal |
| Initial focus | First focusable | **Safest action (Cancel)** | Prevent accidental destructive action |
| Close button (×) | Present | **Hidden by default** | Force explicit choice |

## ARIA Requirements

### Roles

| Role | Element | Description |
|------|---------|-------------|
| `alertdialog` | Dialog container | Indicates urgent modal requiring response |

### Properties

| Attribute | Element | Values | Required | Notes |
|-----------|---------|--------|----------|-------|
| `aria-modal` | alertdialog | `true` | Implicit | Provided by `showModal()`. No explicit attribute needed when using native `<dialog>` |
| `aria-labelledby` | alertdialog | ID ref to title | Yes | References dialog title |
| `aria-describedby` | alertdialog | ID ref to message | **Yes** | References alert message (**required unlike Dialog**) |

### States

None (open/close managed by DOM)

## Keyboard Support

| Key | Action | Notes |
|-----|--------|-------|
| `Tab` | Move to next focusable (loops) | Same as Dialog |
| `Shift + Tab` | Move to previous focusable (loops) | Same as Dialog |
| `Escape` | Close dialog (if allowed) | **Disabled by default** for destructive actions |
| `Enter` | Activate focused button | Standard button behavior |
| `Space` | Activate focused button | Standard button behavior |

## Focus Management

| Event | Behavior |
|-------|----------|
| Dialog opens | Focus moves to **Cancel button** (safest action) |
| Dialog closes | Focus returns to trigger element |
| Focus trap | Tab/Shift+Tab cycles within dialog only |
| Background | Content outside dialog is inert |

## Test Checklist

### High Priority: ARIA

- [ ] Container has `role="alertdialog"` (NOT `dialog`)
- [ ] Is modal (opened via `showModal()`, confirmed by `::backdrop` existence)
- [ ] Has `aria-labelledby` referencing title element
- [ ] Has `aria-describedby` referencing message element (required)
- [ ] Title element id matches `aria-labelledby` value
- [ ] Message element id matches `aria-describedby` value

### High Priority: Keyboard

- [ ] Tab moves to next focusable element
- [ ] Shift+Tab moves to previous focusable element
- [ ] Tab wraps from last to first element
- [ ] Shift+Tab wraps from first to last element
- [ ] Escape does NOT close when `allowEscapeClose=false`
- [ ] Escape closes when `allowEscapeClose=true`
- [ ] Enter activates focused button
- [ ] Space activates focused button

### High Priority: Focus Management

- [ ] Focus moves to Cancel button on open (safest action)
- [ ] Focus is trapped within dialog
- [ ] Focus returns to trigger on close
- [ ] Background content is inert

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

### Low Priority: Props & Callbacks

- [ ] Calls `onConfirm` when confirm button clicked
- [ ] Calls `onCancel` when cancel button clicked
- [ ] Closes dialog after confirm/cancel action

## Implementation Notes

```
Structure (uses native <dialog> element):
┌─────────────────────────────────────────────────┐
│ <dialog role="alertdialog">                     │
│   aria-labelledby="title-id"                    │
│   aria-describedby="message-id"                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ <h2 id="title-id">Confirm Delete</h2>       │ │
│ ├─────────────────────────────────────────────┤ │
│ │ <p id="message-id">                         │ │
│ │   This action cannot be undone.             │ │
│ │ </p>                                        │ │
│ ├─────────────────────────────────────────────┤ │
│ │ [Cancel] ← initial focus    [Delete]        │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

Key Implementation Points:
- Uses native <dialog> element with showModal() for modal behavior
- showModal() provides: backdrop, focus trap, inert background
- NO explicit aria-modal needed (showModal() handles it implicitly)
- NO close button (×) by default
- Cancel button receives initial focus (safest action)
- Escape disabled by default (allowEscapeClose=false)
- aria-describedby is REQUIRED (message prop required)
```

## Props Interface

```typescript
interface AlertDialogProps {
  // Required
  title: string;
  message: string;  // Required (unlike Dialog)

  // Optional
  confirmLabel?: string;      // default: "OK"
  cancelLabel?: string;       // default: "Cancel"
  confirmVariant?: 'default' | 'danger';
  allowEscapeClose?: boolean; // default: false (unlike Dialog)

  // Callbacks
  onConfirm?: () => void;
  onCancel?: () => void;
}
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Role check (NOT dialog)
it('has role="alertdialog"', () => {
  render(<AlertDialog title="Confirm" message="Are you sure?" open />);
  expect(screen.getByRole('alertdialog')).toBeInTheDocument();
});

// aria-describedby is required
it('has aria-describedby referencing message', () => {
  render(<AlertDialog title="Confirm" message="Are you sure?" open />);
  const dialog = screen.getByRole('alertdialog');
  expect(dialog).toHaveAttribute('aria-describedby');
  const messageId = dialog.getAttribute('aria-describedby');
  expect(document.getElementById(messageId!)).toHaveTextContent('Are you sure?');
});

// Initial focus on cancel (safe action)
it('focuses cancel button on open', async () => {
  render(<AlertDialog title="Confirm" message="Delete?" open />);
  const cancelButton = screen.getByRole('button', { name: /cancel/i });
  expect(cancelButton).toHaveFocus();
});

// Escape disabled by default
it('does NOT close on Escape by default', async () => {
  const onCancel = vi.fn();
  const user = userEvent.setup();
  render(<AlertDialog title="Confirm" message="Delete?" open onCancel={onCancel} />);

  await user.keyboard('{Escape}');
  expect(onCancel).not.toHaveBeenCalled();
  expect(screen.getByRole('alertdialog')).toBeInTheDocument();
});

// Escape closes when allowed
it('closes on Escape when allowEscapeClose=true', async () => {
  const onCancel = vi.fn();
  const user = userEvent.setup();
  render(
    <AlertDialog
      title="Info"
      message="Note this."
      open
      allowEscapeClose
      onCancel={onCancel}
    />
  );

  await user.keyboard('{Escape}');
  expect(onCancel).toHaveBeenCalled();
});

// Focus trap
it('traps focus within dialog', async () => {
  const user = userEvent.setup();
  render(<AlertDialog title="Confirm" message="Delete?" open />);

  const cancelButton = screen.getByRole('button', { name: /cancel/i });
  const confirmButton = screen.getByRole('button', { name: /ok|confirm|delete/i });

  expect(cancelButton).toHaveFocus();
  await user.tab();
  expect(confirmButton).toHaveFocus();
  await user.tab();
  expect(cancelButton).toHaveFocus(); // wraps
});
```
