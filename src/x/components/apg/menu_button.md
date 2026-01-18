# Menu Button Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/

## Overview

A menu button is a button that opens a menu. The button element has `aria-haspopup="menu"` and controls a dropdown menu containing menu items.

## ARIA Requirements

### Roles

| Role       | Element                | Description              |
| ---------- | ---------------------- | ------------------------ |
| `button`   | Trigger (`<button>`)   | Opens/closes the menu    |
| `menu`     | Container (`<ul>`)     | Contains menu items      |
| `menuitem` | Each item (`<li>`)     | Actionable menu option   |

### Properties

| Attribute         | Element  | Values                 | Required | Notes                        |
| ----------------- | -------- | ---------------------- | -------- | ---------------------------- |
| `aria-haspopup`   | button   | `"menu"`               | Yes      | Indicates popup type         |
| `aria-controls`   | button   | ID of menu             | Yes      | Links button to menu         |
| `aria-labelledby` | menu     | ID of button           | Yes\*    | Provides accessible name     |
| `aria-label`      | menu     | String                 | Yes\*    | Alternative accessible name  |

> \*Either `aria-labelledby` or `aria-label` is required for menu

### States

| Attribute       | Element  | Values            | Required | Change Trigger              |
| --------------- | -------- | ----------------- | -------- | --------------------------- |
| `aria-expanded` | button   | `true` \| `false` | Yes      | Open/close menu             |
| `aria-disabled` | menuitem | `true`            | No       | When item is disabled       |

## Keyboard Support

### Button Focused

| Key               | Action                                     |
| ----------------- | ------------------------------------------ |
| `Enter` / `Space` | Open menu, focus first enabled item        |
| `ArrowDown`       | Open menu, focus first enabled item        |
| `ArrowUp`         | Open menu, focus last enabled item         |

### Menu Open

| Key               | Action                                     |
| ----------------- | ------------------------------------------ |
| `ArrowDown`       | Move focus to next enabled item (wrap)     |
| `ArrowUp`         | Move focus to previous enabled item (wrap) |
| `Home`            | Move focus to first enabled item           |
| `End`             | Move focus to last enabled item            |
| `Escape`          | Close menu, return focus to button         |
| `Tab`             | Close menu, move focus out                 |
| `Enter` / `Space` | Activate item, close menu                  |
| Type character    | Type-ahead: focus matching item            |

## Focus Management (Roving Tabindex)

- Only one menu item has `tabIndex="0"`
- Other items have `tabIndex="-1"`
- Disabled items are skipped during keyboard navigation
- Focus wraps from last to first (and vice versa)

## Type-Ahead Search

- Single character: focus next item starting with that character
- Multiple characters (typed within 500ms): match prefix
- Search wraps around the menu
- Example: typing "sa" focuses "Save As..." if present

## Test Checklist

### High Priority: Mouse Interaction

- [ ] Click button opens menu
- [ ] Click button again closes menu (toggle)
- [ ] Click menu item activates and closes menu
- [ ] Click disabled item does nothing
- [ ] Click outside menu closes it

### High Priority: Keyboard (Button)

- [ ] Enter opens menu, focuses first enabled item
- [ ] Space opens menu, focuses first enabled item
- [ ] ArrowDown opens menu, focuses first enabled item
- [ ] ArrowUp opens menu, focuses last enabled item

### High Priority: Keyboard (Menu)

- [ ] ArrowDown moves to next item (wraps)
- [ ] ArrowUp moves to previous item (wraps)
- [ ] Home moves to first enabled item
- [ ] End moves to last enabled item
- [ ] Escape closes menu, returns focus to button
- [ ] Tab closes menu
- [ ] Enter/Space activates item, closes menu
- [ ] Disabled items are skipped

### High Priority: Type-Ahead

- [ ] Single character focuses matching item
- [ ] Multiple characters match prefix
- [ ] Search wraps around
- [ ] Buffer resets after 500ms

### High Priority: ARIA

- [ ] Button has `role="button"` (implicit or explicit)
- [ ] Button has `aria-haspopup="menu"`
- [ ] Button has `aria-expanded` (true/false)
- [ ] Button has `aria-controls` linking to menu
- [ ] Menu has `role="menu"`
- [ ] Menu has accessible name
- [ ] Items have `role="menuitem"`
- [ ] Disabled items have `aria-disabled="true"`

### High Priority: Focus Management

- [ ] Only focused item has `tabIndex="0"`
- [ ] Other items have `tabIndex="-1"`

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

```html
Structure (closed):
<button
  aria-haspopup="menu"
  aria-expanded="false"
  aria-controls="menu-id"
>
  Actions ▼
</button>
<ul id="menu-id" role="menu" aria-labelledby="button-id" hidden>
  <li role="menuitem" tabindex="-1">Cut</li>
  <li role="menuitem" tabindex="-1">Copy</li>
  <li role="menuitem" tabindex="-1">Paste</li>
</ul>

Structure (open):
<button
  aria-haspopup="menu"
  aria-expanded="true"
  aria-controls="menu-id"
>
  Actions ▼
</button>
<ul id="menu-id" role="menu" aria-labelledby="button-id">
  <li role="menuitem" tabindex="0">Cut</li>      <!-- focused -->
  <li role="menuitem" tabindex="-1">Copy</li>
  <li role="menuitem" tabindex="-1">Paste</li>
</ul>

With disabled item:
<li role="menuitem" aria-disabled="true" tabindex="-1">Export</li>

Type-Ahead:
- Characters typed within 500ms form search string
- After 500ms idle, buffer resets
- Search is case-insensitive
- Wraps from end to beginning
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Open menu with Enter
it('Enter opens menu and focuses first item', async () => {
  const user = userEvent.setup();
  render(<MenuButton items={items} label="Actions" />);

  const button = screen.getByRole('button', { name: 'Actions' });
  button.focus();

  await user.keyboard('{Enter}');

  expect(button).toHaveAttribute('aria-expanded', 'true');
  expect(screen.getByRole('menuitem', { name: 'Cut' })).toHaveFocus();
});

// Arrow navigation with wrap
it('ArrowDown wraps from last to first', async () => {
  const user = userEvent.setup();
  render(<MenuButton items={items} label="Actions" defaultOpen />);

  screen.getByRole('menuitem', { name: 'Delete' }).focus(); // last item

  await user.keyboard('{ArrowDown}');

  expect(screen.getByRole('menuitem', { name: 'Cut' })).toHaveFocus();
});

// Escape closes menu
it('Escape closes menu and returns focus to button', async () => {
  const user = userEvent.setup();
  render(<MenuButton items={items} label="Actions" defaultOpen />);

  const button = screen.getByRole('button');

  await user.keyboard('{Escape}');

  expect(button).toHaveAttribute('aria-expanded', 'false');
  expect(button).toHaveFocus();
});

// Type-ahead
it('type-ahead focuses matching item', async () => {
  const user = userEvent.setup();
  render(<MenuButton items={items} label="Actions" defaultOpen />);

  screen.getByRole('menuitem', { name: 'Cut' }).focus();

  await user.keyboard('p');

  expect(screen.getByRole('menuitem', { name: 'Paste' })).toHaveFocus();
});

// Click outside closes menu
it('clicking outside closes menu', async () => {
  const user = userEvent.setup();
  render(<MenuButton items={items} label="Actions" defaultOpen />);

  await user.click(document.body);

  expect(screen.getByRole('button')).toHaveAttribute('aria-expanded', 'false');
});
```
