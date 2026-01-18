# Tabs Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/

## Overview

Tabs are a set of layered sections of content, known as tab panels, that display one panel of content at a time.

## ARIA Requirements

### Roles

| Role       | Element      | Description                |
| ---------- | ------------ | -------------------------- |
| `tablist`  | Container    | Container for tab elements |
| `tab`      | Tab button   | Individual tab element     |
| `tabpanel` | Content area | Content panel for each tab |

### Properties

| Attribute          | Element  | Values                         | Required | Notes                  |
| ------------------ | -------- | ------------------------------ | -------- | ---------------------- |
| `aria-orientation` | tablist  | `"horizontal"` \| `"vertical"` | No       | Defaults to horizontal |
| `aria-controls`    | tab      | ID of associated panel         | Yes      | Auto-generated         |
| `aria-labelledby`  | tabpanel | ID of associated tab           | Yes      | Auto-generated         |

### States

| Attribute       | Element | Values            | Required | Change Trigger                                          |
| --------------- | ------- | ----------------- | -------- | ------------------------------------------------------- |
| `aria-selected` | tab     | `true` \| `false` | Yes      | Tab click, Arrow keys (automatic), Enter/Space (manual) |

## Keyboard Support

### Horizontal Orientation

| Key               | Action                                |
| ----------------- | ------------------------------------- |
| `Tab`             | Move focus into/out of the tablist    |
| `ArrowRight`      | Move to next tab (loops at end)       |
| `ArrowLeft`       | Move to previous tab (loops at start) |
| `Home`            | Move to first tab                     |
| `End`             | Move to last tab                      |
| `Enter` / `Space` | Activate tab (manual mode only)       |

### Vertical Orientation

| Key         | Action                                |
| ----------- | ------------------------------------- |
| `ArrowDown` | Move to next tab (loops at end)       |
| `ArrowUp`   | Move to previous tab (loops at start) |

## Focus Management (Roving Tabindex)

- Selected/focused tab: `tabIndex="0"`
- Other tabs: `tabIndex="-1"`
- Tabpanel: `tabIndex="0"` (focusable)
- Disabled tabs are skipped during keyboard navigation

## Activation Modes

### Automatic (default)

- Arrow keys move focus AND select tab
- Panel content changes immediately

### Manual

- Arrow keys move focus only
- Enter/Space required to select tab
- Panel content changes on explicit activation

## Test Checklist

### High Priority: Keyboard

- [ ] ArrowRight moves to next tab (horizontal)
- [ ] ArrowLeft moves to previous tab (horizontal)
- [ ] ArrowDown moves to next tab (vertical)
- [ ] ArrowUp moves to previous tab (vertical)
- [ ] Arrow keys loop at boundaries
- [ ] Home moves to first tab
- [ ] End moves to last tab
- [ ] Disabled tabs are skipped
- [ ] Tab key moves focus to tabpanel
- [ ] Manual mode: Enter/Space activates focused tab

### High Priority: ARIA

- [ ] Container has `role="tablist"`
- [ ] Each tab has `role="tab"`
- [ ] Panel has `role="tabpanel"`
- [ ] Selected tab has `aria-selected="true"`
- [ ] Non-selected tabs have `aria-selected="false"`
- [ ] Tab `aria-controls` matches panel `id`
- [ ] Panel `aria-labelledby` matches tab `id`
- [ ] `aria-orientation` reflects orientation prop

### High Priority: Focus Management

- [ ] Only selected/focused tab has `tabIndex="0"`
- [ ] Other tabs have `tabIndex="-1"`
- [ ] Tabpanel is focusable (`tabIndex="0"`)

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

```
Structure:
┌─────────────────────────────────────────┐
│ [Tab 1] [Tab 2] [Tab 3]   ← tablist     │
├─────────────────────────────────────────┤
│                                         │
│  Panel content here        ← tabpanel   │
│                                         │
└─────────────────────────────────────────┘

ID Relationships:
- Tab: id="tab-1", aria-controls="panel-1"
- Panel: id="panel-1", aria-labelledby="tab-1"
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Keyboard navigation test
it('ArrowRight moves to next tab', async () => {
  const user = userEvent.setup();
  render(<Tabs tabs={tabs} />);

  const tab1 = screen.getByRole('tab', { name: 'Tab 1' });
  tab1.focus();

  await user.keyboard('{ArrowRight}');

  const tab2 = screen.getByRole('tab', { name: 'Tab 2' });
  expect(tab2).toHaveFocus();
  expect(tab2).toHaveAttribute('aria-selected', 'true');
});

// ARIA attributes test
it('selected tab has aria-selected=true', () => {
  render(<Tabs tabs={tabs} />);
  const tabs = screen.getAllByRole('tab');

  expect(tabs[0]).toHaveAttribute('aria-selected', 'true');
  expect(tabs[1]).toHaveAttribute('aria-selected', 'false');
});

// Roving tabindex test
it('only selected tab has tabIndex=0', () => {
  render(<Tabs tabs={tabs} />);
  const tabs = screen.getAllByRole('tab');

  expect(tabs[0]).toHaveAttribute('tabIndex', '0');
  expect(tabs[1]).toHaveAttribute('tabIndex', '-1');
});
```
