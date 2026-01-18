# Radio Group Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/radio/

## Overview

A radio group is a set of checkable buttons where only one can be checked at a time. Arrow keys move focus and selection together. Uses roving tabindex for focus management.

## Native HTML vs Custom Implementation

**Native `<input type="radio">` provides implicit semantics**, but custom implementation offers consistent cross-browser keyboard behavior.

| Use Case | Recommended |
| --- | --- |
| Standard form input | Native `<input type="radio">` with `<fieldset>`/`<legend>` |
| Consistent keyboard behavior | Custom `role="radiogroup"` + `role="radio"` |
| Custom styling needed | Either approach with appropriate CSS |

## ARIA Requirements

### Roles

| Role | Element | Required | Description |
| --- | --- | --- | --- |
| `radiogroup` | Container | Yes | Groups radio buttons |
| `radio` | Each option | Yes | Individual radio button |

### States

| Attribute | Element | Values | Required | Change Trigger |
| --- | --- | --- | --- | --- |
| `aria-checked` | radio | `true` / `false` | Yes | Click, Space, Arrow keys |
| `aria-disabled` | radio | `true` | When disabled | - |

### Properties

| Attribute | Element | Values | Required | Notes |
| --- | --- | --- | --- | --- |
| `aria-label` | radiogroup | string | When no visible label | Accessible name for group |
| `aria-labelledby` | radiogroup | ID reference | When no visible label | References group label |
| `aria-orientation` | radiogroup | `horizontal` | Only when horizontal | Vertical is default |

## Keyboard Support

| Key | Action |
| --- | --- |
| `Tab` | Enter group (focus selected or first radio) |
| `Shift+Tab` | Exit group |
| `Space` | Select focused radio (no unselect) |
| `ArrowDown` | Move to next and select (wraps) |
| `ArrowRight` | Move to next and select (wraps) |
| `ArrowUp` | Move to previous and select (wraps) |
| `ArrowLeft` | Move to previous and select (wraps) |
| `Home` | Move to first and select |
| `End` | Move to last and select |

**Key differences from Checkbox:**
- Arrow keys change selection (not just focus)
- Space cannot unselect (radio stays selected)
- Wrapping: last → first, first → last

## Focus Management (Roving Tabindex)

| Condition | Tabbable Radio |
| --- | --- |
| One selected | Selected radio (`tabindex="0"`) |
| None selected | First enabled radio (`tabindex="0"`) |
| All others | `tabindex="-1"` |
| Disabled | Always `tabindex="-1"` |

**Rule**: Only ONE radio in group has `tabindex="0"` at any time.

## Test Checklist

### High Priority: ARIA

- [ ] Container has `role="radiogroup"`
- [ ] Each option has `role="radio"`
- [ ] `aria-checked="true"` on selected, `"false"` on others
- [ ] Group has accessible name (`aria-label` or `aria-labelledby`)
- [ ] Each radio has accessible name
- [ ] Disabled radios have `aria-disabled="true"`
- [ ] `aria-orientation` only set when horizontal

### High Priority: Keyboard

- [ ] Tab focuses selected radio (or first if none)
- [ ] Tab/Shift+Tab exits group
- [ ] Space selects focused radio
- [ ] Space does NOT unselect
- [ ] ArrowDown/Right moves to next and selects
- [ ] ArrowUp/Left moves to previous and selects
- [ ] Home moves to first and selects
- [ ] End moves to last and selects
- [ ] Arrows wrap (last → first, first → last)
- [ ] Disabled radios skipped by arrows

### High Priority: Focus Management

- [ ] Selected radio has `tabindex="0"`
- [ ] Non-selected radios have `tabindex="-1"`
- [ ] Disabled radios have `tabindex="-1"`
- [ ] Only ONE `tabindex="0"` in group

### Medium Priority: Form & Accessibility

- [ ] Hidden input for form submission
- [ ] No axe-core violations
- [ ] State visible without color alone

## Implementation Notes

### Structure (Custom)

```
<div role="radiogroup" aria-label="Choose color">
  <input type="hidden" name="color" value="selected-value" />

  <div role="radio" aria-checked="false" tabindex="-1">
    <span aria-hidden="true">○</span>
    <span id="label-red">Red</span>
  </div>

  <div role="radio" aria-checked="true" tabindex="0">
    <span aria-hidden="true">●</span>
    <span id="label-blue">Blue</span>
  </div>
</div>
```

### Common Pitfalls

1. **Forgetting roving tabindex**: Only selected/first radio is tabbable
2. **Not wrapping arrows**: APG requires wrap-around navigation
3. **Allowing unselect via Space**: Unlike checkbox, radio stays selected
4. **Missing group label**: radiogroup needs `aria-label` or `aria-labelledby`
5. **Setting `aria-orientation` for vertical**: Only set for horizontal

### Visual States

```
○  = Unchecked (empty circle)
●  = Selected (filled circle)
Grayed + reduced opacity = Disabled
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

const options = [
  { id: 'r', label: 'Red', value: 'red' },
  { id: 'b', label: 'Blue', value: 'blue' },
  { id: 'g', label: 'Green', value: 'green' },
];

// Role tests
it('has role="radiogroup" on container', () => {
  render(<RadioGroup options={options} name="color" aria-label="Color" />);
  expect(screen.getByRole('radiogroup')).toBeInTheDocument();
});

it('has role="radio" on each option', () => {
  render(<RadioGroup options={options} name="color" aria-label="Color" />);
  expect(screen.getAllByRole('radio')).toHaveLength(3);
});

// Selection tests
it('sets aria-checked="true" on selected', () => {
  render(<RadioGroup options={options} name="color" aria-label="Color" defaultValue="blue" />);
  expect(screen.getByRole('radio', { name: 'Blue' })).toHaveAttribute('aria-checked', 'true');
  expect(screen.getByRole('radio', { name: 'Red' })).toHaveAttribute('aria-checked', 'false');
});

// Keyboard navigation
it('moves to next and selects on ArrowDown', async () => {
  const user = userEvent.setup();
  render(<RadioGroup options={options} name="color" aria-label="Color" />);

  await user.tab();
  await user.keyboard('{ArrowDown}');

  expect(screen.getByRole('radio', { name: 'Blue' })).toHaveFocus();
  expect(screen.getByRole('radio', { name: 'Blue' })).toHaveAttribute('aria-checked', 'true');
});

it('wraps from last to first on ArrowDown', async () => {
  const user = userEvent.setup();
  render(<RadioGroup options={options} name="color" aria-label="Color" defaultValue="green" />);

  await user.tab();
  await user.keyboard('{ArrowDown}');

  expect(screen.getByRole('radio', { name: 'Red' })).toHaveFocus();
  expect(screen.getByRole('radio', { name: 'Red' })).toHaveAttribute('aria-checked', 'true');
});

// Roving tabindex
it('has only one tabindex="0" in group', () => {
  render(<RadioGroup options={options} name="color" aria-label="Color" defaultValue="blue" />);
  const radios = screen.getAllByRole('radio');
  const tabbable = radios.filter(r => r.getAttribute('tabIndex') === '0');
  expect(tabbable).toHaveLength(1);
});
```
