# Combobox Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/

## Overview

A combobox is a composite widget with a text input field and an associated popup (listbox). Users can either type a value or select from the popup. This guide covers the **Editable Combobox with List Autocomplete** variant.

## ARIA Requirements

### Roles

| Role       | Element     | Description                              |
| ---------- | ----------- | ---------------------------------------- |
| `combobox` | `<input>`   | Main input element for value entry       |
| `listbox`  | `<ul>`      | Popup container for selectable options   |
| `option`   | `<li>`      | Individual selectable option in listbox  |

### Properties (Static)

| Attribute           | Element | Values                    | Required | Notes                                       |
| ------------------- | ------- | ------------------------- | -------- | ------------------------------------------- |
| `role="combobox"`   | input   | -                         | Yes      | Not implicit on input                       |
| `aria-controls`     | input   | listbox ID                | Yes      | Points to listbox even when closed          |
| `aria-haspopup`     | input   | `listbox`                 | No       | Default value for combobox                  |
| `aria-autocomplete` | input   | `list` / `none` / `both`  | Yes      | Describes autocomplete behavior             |
| `aria-labelledby`   | input   | label ID                  | Yes*     | Or use `aria-label`                         |
| `aria-disabled`     | option  | `true`                    | No       | For disabled options                        |

### States (Dynamic)

| Attribute                | Element | Values               | Required | Change Trigger                   |
| ------------------------ | ------- | -------------------- | -------- | -------------------------------- |
| `aria-expanded`          | input   | `true` / `false`     | Yes      | Popup open/close                 |
| `aria-activedescendant`  | input   | option ID / `""`     | Yes      | Focus moves in popup; clear when closed or empty |
| `aria-selected`          | option  | `true` / `false`     | Yes      | Selection state change           |

## Keyboard Support

### Input Focused

| Key               | Action                                              |
| ----------------- | --------------------------------------------------- |
| `ArrowDown`       | Open popup, focus first option                      |
| `ArrowUp`         | Open popup, focus last option                       |
| `Enter`           | Commit selection, close popup                       |
| `Escape`          | Close popup, restore previous value                 |
| `Alt + ArrowDown` | Open popup without changing focus position          |
| `Alt + ArrowUp`   | Commit selection, close popup                       |
| `Tab`             | Close popup, move to next focusable element         |
| Printable chars   | Type in input, filter list, open popup if closed    |

### Listbox Navigation (via aria-activedescendant)

| Key         | Action                               |
| ----------- | ------------------------------------ |
| `ArrowDown` | Move to next enabled option          |
| `ArrowUp`   | Move to previous enabled option      |
| `Home`      | Move to first enabled option         |
| `End`       | Move to last enabled option          |
| `Enter`     | Commit selection, close popup        |
| `Escape`    | Close popup, restore previous value  |

## Focus Management

- **DOM focus stays on input at all times**
- Use `aria-activedescendant` for virtual focus in listbox
- Clear `aria-activedescendant` when:
  - Popup closes
  - Filter results are empty
- Skip disabled options during navigation
- `aria-activedescendant` must reference an existing DOM element ID

## Test Checklist

### High Priority: ARIA

- [ ] Input has `role="combobox"`
- [ ] Input has `aria-controls` pointing to listbox
- [ ] `aria-controls` valid even when popup closed
- [ ] `aria-expanded` toggles correctly
- [ ] `aria-autocomplete="list"` present
- [ ] `aria-activedescendant` updates on navigation
- [ ] `aria-activedescendant` clears when closed/empty
- [ ] Listbox has `role="listbox"` and `hidden` when closed
- [ ] Options have `role="option"` and `aria-selected`
- [ ] Disabled options have `aria-disabled="true"`

### High Priority: Keyboard

- [ ] ArrowDown opens popup, focuses first
- [ ] ArrowUp opens popup, focuses last
- [ ] ArrowDown/Up navigates options
- [ ] Home/End jump to first/last
- [ ] Enter commits selection
- [ ] Escape closes and restores value
- [ ] Tab closes popup
- [ ] Alt+ArrowDown/Up combos work
- [ ] Typing filters list and opens popup

### High Priority: Focus

- [ ] DOM focus remains on input during navigation
- [ ] `aria-activedescendant` references valid element
- [ ] Disabled options are skipped

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

## Implementation Notes

### Structure

```
Container (div)
├── Label (label) id="combobox-label"
├── Input (input)
│   role="combobox"
│   aria-controls="listbox-id"
│   aria-expanded="true/false"
│   aria-autocomplete="list"
│   aria-activedescendant="option-id" (or "")
│   aria-labelledby="combobox-label"
└── Listbox (ul) id="listbox-id" hidden={!isOpen}
    role="listbox"
    ├── Option (li) role="option" id="opt-1" aria-selected
    └── Option (li) role="option" id="opt-2" aria-disabled
```

### Key Implementation Points

1. **Listbox always in DOM**: Keep listbox in DOM with `hidden` attribute when closed (for `aria-controls` reference)
2. **IME Handling**: Track composition state to prevent filtering during IME input
3. **Click Outside**: Use event listener to close popup on outside clicks
4. **Filter Reset**: Clear `aria-activedescendant` when filter results change
5. **Value Restoration**: Store pre-edit value to restore on Escape

### Disabled Options

- Set `aria-disabled="true"`
- Skip during keyboard navigation
- Prevent selection on Enter/click
- Keep visible in filtered results

### Search Mode Management

When an option is already selected, the input displays the selected label. To provide a better UX, implement a "search mode" state:

- **Focus with selection**: Show all options (no filtering)
- **User types/edits**: Enter search mode, filter options
- **Selection or Escape**: Exit search mode

```typescript
// Filtering logic
const shouldFilter = isSearching || inputValue !== selectedLabel;
const filteredOptions = shouldFilter
  ? options.filter(...)
  : options;
```

### Visual Selection vs Focus State

Use separate attributes for different states:

| Attribute       | Meaning         | Visual Effect        |
| --------------- | --------------- | -------------------- |
| `aria-selected` | Focused option  | Background highlight |
| `data-selected` | Selected option | Checkmark visible    |

These can be on different options simultaneously (e.g., Apple is selected with checkmark, Banana is focused with highlight).

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { Combobox } from './Combobox';

const options = [
  { id: 'apple', label: 'Apple' },
  { id: 'banana', label: 'Banana' },
  { id: 'cherry', label: 'Cherry', disabled: true },
];

describe('Combobox', () => {
  it('has correct ARIA attributes', () => {
    render(<Combobox options={options} label="Fruit" />);
    const input = screen.getByRole('combobox');

    expect(input).toHaveAttribute('aria-expanded', 'false');
    expect(input).toHaveAttribute('aria-autocomplete', 'list');
    expect(input).toHaveAttribute('aria-controls');
  });

  it('opens popup on ArrowDown and focuses first option', async () => {
    const user = userEvent.setup();
    render(<Combobox options={options} label="Fruit" />);
    const input = screen.getByRole('combobox');

    await user.click(input);
    await user.keyboard('{ArrowDown}');

    expect(input).toHaveAttribute('aria-expanded', 'true');
    const listbox = screen.getByRole('listbox');
    expect(listbox).toBeVisible();
    expect(input).toHaveAttribute('aria-activedescendant', 'apple');
  });

  it('skips disabled options', async () => {
    const user = userEvent.setup();
    render(<Combobox options={options} label="Fruit" />);
    const input = screen.getByRole('combobox');

    await user.click(input);
    await user.keyboard('{ArrowDown}{ArrowDown}{ArrowDown}');

    // Should skip 'cherry' (disabled) and wrap or stop
    expect(input).toHaveAttribute('aria-activedescendant', 'banana');
  });

  it('has no accessibility violations', async () => {
    const { container } = render(<Combobox options={options} label="Fruit" />);
    expect(await axe(container)).toHaveNoViolations();
  });
});
```
