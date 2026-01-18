# Listbox Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/listbox/

## Overview

A listbox widget presents a list of options and allows selection of one or more items. It provides custom selection behavior beyond native `<select>`.

## ARIA Requirements

### Roles

| Role      | Element            | Description       |
| --------- | ------------------ | ----------------- |
| `listbox` | Container (`<ul>`) | Selection widget  |
| `option`  | Each item (`<li>`) | Selectable option |

### Properties

| Attribute              | Element | Values                         | Required | Notes             |
| ---------------------- | ------- | ------------------------------ | -------- | ----------------- |
| `aria-label`           | listbox | String                         | Yes\*    | Accessible name   |
| `aria-labelledby`      | listbox | ID reference                   | Yes\*    | Alternative       |
| `aria-multiselectable` | listbox | `true`                         | No       | For multi-select  |
| `aria-orientation`     | listbox | `"vertical"` \| `"horizontal"` | No       | Default: vertical |

> \*Either `aria-label` or `aria-labelledby` is required

### States

| Attribute       | Element | Values            | Required | Change Trigger                            |
| --------------- | ------- | ----------------- | -------- | ----------------------------------------- |
| `aria-selected` | option  | `true` \| `false` | Yes      | Click, Arrow keys (single), Space (multi) |
| `aria-disabled` | option  | `true`            | No       | When disabled                             |

## Keyboard Support

### Common Navigation

| Key                        | Action                     |
| -------------------------- | -------------------------- |
| `ArrowDown` / `ArrowUp`    | Move focus (vertical)      |
| `ArrowRight` / `ArrowLeft` | Move focus (horizontal)    |
| `Home`                     | Move focus to first option |
| `End`                      | Move focus to last option  |
| Type character             | Type-ahead focus           |

### Single-Select (Selection Follows Focus)

| Key               | Action                   |
| ----------------- | ------------------------ |
| Arrow keys        | Move focus AND selection |
| `Space` / `Enter` | Confirm selection        |

### Multi-Select

| Key             | Action                             |
| --------------- | ---------------------------------- |
| Arrow keys      | Move focus only                    |
| `Space`         | Toggle selection of focused option |
| `Shift + Arrow` | Extend selection range             |
| `Shift + Home`  | Select from anchor to first        |
| `Shift + End`   | Select from anchor to last         |
| `Ctrl + A`      | Select all                         |

## Focus Management (Roving Tabindex)

- Only one option has `tabIndex="0"`
- Other options have `tabIndex="-1"`
- Disabled options are skipped
- Focus does NOT wrap at edges

## Selection Models

| Single-Select           | Multi-Select                    |
| ----------------------- | ------------------------------- |
| Selection follows focus | Focus and selection independent |
| Arrow changes selection | Space toggles selection         |
| Only one selected       | Multiple selected               |

## Test Checklist

### High Priority: Keyboard

- [ ] Arrow keys navigate options
- [ ] Home moves to first option
- [ ] End moves to last option
- [ ] Type-ahead focuses matching option
- [ ] Disabled options are skipped
- [ ] Focus does not wrap

### High Priority: Keyboard (Single-Select)

- [ ] Arrow keys move focus and selection
- [ ] Space/Enter confirms selection

### High Priority: Keyboard (Multi-Select)

- [ ] Arrow keys move focus only
- [ ] Space toggles selection
- [ ] Shift+Arrow extends selection
- [ ] Ctrl+A selects all

### High Priority: ARIA

- [ ] Container has `role="listbox"`
- [ ] Items have `role="option"`
- [ ] Listbox has accessible name
- [ ] Selected options have `aria-selected="true"`
- [ ] Multi-select has `aria-multiselectable="true"`

### High Priority: Focus Management

- [ ] Only focused option has `tabIndex="0"`
- [ ] Other options have `tabIndex="-1"`

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

```html
Structure:
<ul role="listbox" aria-label="Choose color">
  <li role="option" aria-selected="true" tabindex="0">Red</li>
  <li role="option" aria-selected="false" tabindex="-1">Green</li>
  <li role="option" aria-selected="false" tabindex="-1">Blue</li>
</ul>

Multi-Select:
<ul role="listbox" aria-label="Colors" aria-multiselectable="true">
  <li role="option" aria-selected="true" tabindex="0">Red</li>
  <li role="option" aria-selected="true" tabindex="-1">Green</li>
  <li role="option" aria-selected="false" tabindex="-1">Blue</li>
</ul>

Type-Ahead: - Single character: jump to next option starting with that char - Multiple chars (typed
quickly): match prefix - Example: typing "gr" focuses "Green"
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Arrow navigation
it('ArrowDown moves focus', async () => {
  const user = userEvent.setup();
  render(<Listbox options={options} />);

  const firstOption = screen.getByRole('option', { name: 'Red' });
  firstOption.focus();

  await user.keyboard('{ArrowDown}');

  expect(screen.getByRole('option', { name: 'Green' })).toHaveFocus();
});

// Single-select
it('selection follows focus in single-select', async () => {
  const user = userEvent.setup();
  render(<Listbox options={options} />);

  const firstOption = screen.getByRole('option', { name: 'Red' });
  firstOption.focus();

  await user.keyboard('{ArrowDown}');

  const greenOption = screen.getByRole('option', { name: 'Green' });
  expect(greenOption).toHaveAttribute('aria-selected', 'true');
});

// Multi-select toggle
it('Space toggles in multi-select', async () => {
  const user = userEvent.setup();
  render(<Listbox options={options} multiselectable />);

  const option = screen.getByRole('option', { name: 'Red' });
  option.focus();

  await user.keyboard(' ');
  expect(option).toHaveAttribute('aria-selected', 'true');

  await user.keyboard(' ');
  expect(option).toHaveAttribute('aria-selected', 'false');
});

// Type-ahead
it('type-ahead focuses matching option', async () => {
  const user = userEvent.setup();
  render(<Listbox options={options} />);

  screen.getByRole('option', { name: 'Red' }).focus();

  await user.keyboard('g');

  expect(screen.getByRole('option', { name: 'Green' })).toHaveFocus();
});
```
