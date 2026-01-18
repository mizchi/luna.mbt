# Alert Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/alert/

## Overview

An alert displays a brief, important message that attracts the user's attention without interrupting their task. Alerts are announced by screen readers immediately when content changes.

## Critical Implementation Rule

**The live region container MUST exist in the DOM from page load.**

```jsx
// ❌ WRONG: Dynamically adding live region
{
  showAlert && <div role="alert">Message</div>;
}

// ✅ CORRECT: Live region always exists, content changes
<div role="alert">{message && <span>{message}</span>}</div>;
```

Screen readers detect changes by observing DOM mutations inside live regions. If the container is added dynamically, announcements may fail.

## ARIA Requirements

### Roles

| Role    | Element         | Description             |
| ------- | --------------- | ----------------------- |
| `alert` | Alert container | Brief important message |

### Implicit Properties (DO NOT add manually)

| Attribute     | Implicit Value | Effect                                     |
| ------------- | -------------- | ------------------------------------------ |
| `aria-live`   | `assertive`    | Interrupts screen reader immediately       |
| `aria-atomic` | `true`         | Announces entire content, not just changes |

## Keyboard Support

**Alerts require NO keyboard interaction.**

If dismiss button is present:
| Key | Action |
|-----|--------|
| `Enter` | Activate dismiss button |
| `Space` | Activate dismiss button |

## Focus Management

- **Alert must NOT move focus** - Non-modal, should not interrupt workflow
- **Alert container is NOT focusable** - No `tabindex`
- **Dismiss button is focusable** - If present, reachable via Tab

## Important Guidelines

### No Auto-Dismissal (WCAG 2.2.3)

- Alerts should NOT disappear automatically
- Users need sufficient time to read
- If auto-dismiss required: provide user control to pause/extend

### Alert Frequency (WCAG 2.2.4)

- Excessive alerts inhibit usability
- Use sparingly for truly important messages

### Alert vs Alert Dialog

| Use Alert                         | Use Alert Dialog                   |
| --------------------------------- | ---------------------------------- |
| Informational, no action required | Requires immediate response        |
| Should NOT interrupt workflow     | Must acknowledge before continuing |
| Focus stays on current task       | Focus moves to dialog              |

## Test Checklist

### High Priority: ARIA

- [ ] Container has `role="alert"`
- [ ] Live region exists in DOM before content
- [ ] Content changes are announced

### High Priority: Focus Management

- [ ] Alert does NOT steal focus
- [ ] Alert container is NOT focusable
- [ ] Dismiss button (if present) is focusable

### High Priority: Behavior

- [ ] Initial page load content is NOT announced
- [ ] Dynamic content changes ARE announced
- [ ] No auto-dismissal (or user control provided)

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

```
Structure:
<!-- Container always in DOM -->
<div role="alert">
  <!-- Content added dynamically -->
  <span>Your changes have been saved.</span>
</div>

Announcement Behavior:
- Page load content: NOT announced
- Dynamic changes: ANNOUNCED immediately
- aria-live="assertive": interrupts current speech

Alert vs Status:
┌─────────────┬──────────────────────┐
│ role="alert"│ role="status"        │
├─────────────┼──────────────────────┤
│ assertive   │ polite               │
│ interrupts  │ waits for pause      │
│ urgent info │ non-urgent updates   │
└─────────────┴──────────────────────┘
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';

// Live region exists
it('has role="alert"', () => {
  render(<Alert message="Saved" />);
  expect(screen.getByRole('alert')).toBeInTheDocument();
});

// Dynamic content announced
it('announces dynamic content', async () => {
  const { rerender } = render(<Alert message="" />);

  // Change content
  rerender(<Alert message="Changes saved" />);

  expect(screen.getByRole('alert')).toHaveTextContent('Changes saved');
});

// Does not steal focus
it('does not move focus', () => {
  const button = document.createElement('button');
  document.body.appendChild(button);
  button.focus();

  render(<Alert message="Saved" />);

  expect(document.activeElement).toBe(button);
  button.remove();
});

// Alert container not focusable
it('is not focusable', () => {
  render(<Alert message="Saved" />);
  const alert = screen.getByRole('alert');
  expect(alert).not.toHaveAttribute('tabindex');
});
```
