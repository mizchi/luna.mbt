# Accordion Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/accordion/

## Overview

An accordion is a vertically stacked set of interactive headings that each reveal an associated section of content.

## ARIA Requirements

### Roles

| Role      | Element                | Description                            |
| --------- | ---------------------- | -------------------------------------- |
| `heading` | Header wrapper (h2-h6) | Contains the accordion trigger button  |
| `button`  | Header trigger         | Interactive element that toggles panel |
| `region`  | Panel (optional)       | Content area (omit for 6+ panels)      |

### Properties

| Attribute         | Element | Values       | Required        | Notes                       |
| ----------------- | ------- | ------------ | --------------- | --------------------------- |
| `aria-level`      | heading | `2` - `6`    | Yes             | Set via `headingLevel` prop |
| `aria-controls`   | button  | ID of panel  | Yes             | Auto-generated              |
| `aria-labelledby` | region  | ID of button | Yes (if region) | Auto-generated              |

### States

| Attribute       | Element | Values            | Required | Change Trigger      |
| --------------- | ------- | ----------------- | -------- | ------------------- |
| `aria-expanded` | button  | `true` \| `false` | Yes      | Click, Enter, Space |
| `aria-disabled` | button  | `true`            | No       | Only when disabled  |

## Keyboard Support

| Key               | Action                                   |
| ----------------- | ---------------------------------------- |
| `Tab`             | Move focus to next focusable element     |
| `Enter` / `Space` | Toggle panel expansion                   |
| `ArrowDown`       | Move focus to next header (optional)     |
| `ArrowUp`         | Move focus to previous header (optional) |
| `Home`            | Move focus to first header (optional)    |
| `End`             | Move focus to last header (optional)     |

> Note: Arrow key navigation is optional but recommended. Focus does not wrap.

## Focus Management

- Headers are focusable via their button elements
- Arrow keys navigate between headers (skip disabled)
- Focus does not wrap at edges

## Test Checklist

### High Priority: Keyboard

- [ ] Enter/Space toggles panel expansion
- [ ] ArrowDown moves to next header
- [ ] ArrowUp moves to previous header
- [ ] Home moves to first header
- [ ] End moves to last header
- [ ] Disabled headers are skipped

### High Priority: ARIA

- [ ] Button has `aria-expanded` matching panel state
- [ ] Button has `aria-controls` referencing panel id
- [ ] Panel (if region) has `aria-labelledby` referencing button
- [ ] 6 or fewer panels have `role="region"`
- [ ] 7+ panels omit `role="region"`
- [ ] Disabled items have `aria-disabled="true"`

### High Priority: Focus Management

- [ ] Focus stays on header after toggle
- [ ] Arrow keys skip disabled headers

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)
- [ ] Proper heading level hierarchy

## Implementation Notes

```
Structure:
┌─────────────────────────────────────┐
│ [▼] Section 1                       │  ← button (aria-expanded="true")
├─────────────────────────────────────┤
│ Panel 1 content...                  │  ← region (aria-labelledby)
├─────────────────────────────────────┤
│ [▶] Section 2                       │  ← button (aria-expanded="false")
├─────────────────────────────────────┤
│ [▶] Section 3                       │  ← button (aria-expanded="false")
└─────────────────────────────────────┘

ID Relationships:
- Button: id="header-1", aria-controls="panel-1"
- Panel: id="panel-1", aria-labelledby="header-1"

Region Role Rule:
- ≤6 panels: use role="region" on panels
- >6 panels: omit role="region" (too many landmarks)
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Toggle test
it('toggles panel on Enter/Space', async () => {
  const user = userEvent.setup();
  render(<Accordion items={items} />);

  const header = screen.getByRole('button', { name: 'Section 1' });
  expect(header).toHaveAttribute('aria-expanded', 'false');

  await user.click(header);
  expect(header).toHaveAttribute('aria-expanded', 'true');
});

// Arrow navigation test
it('ArrowDown moves to next header', async () => {
  const user = userEvent.setup();
  render(<Accordion items={items} />);

  const header1 = screen.getByRole('button', { name: 'Section 1' });
  header1.focus();

  await user.keyboard('{ArrowDown}');

  const header2 = screen.getByRole('button', { name: 'Section 2' });
  expect(header2).toHaveFocus();
});

// Skip disabled
it('skips disabled headers', async () => {
  const user = userEvent.setup();
  render(<Accordion items={itemsWithDisabled} />);

  const header1 = screen.getByRole('button', { name: 'Section 1' });
  header1.focus();

  await user.keyboard('{ArrowDown}');
  // Section 2 is disabled, should skip to Section 3
  expect(screen.getByRole('button', { name: 'Section 3' })).toHaveFocus();
});
```
