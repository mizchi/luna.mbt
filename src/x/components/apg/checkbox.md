# Checkbox Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/

## Overview

A checkbox allows users to select one or more options from a set. Supports dual-state (checked/unchecked) and tri-state (checked/unchecked/mixed) for parent-child relationships.

## Native HTML vs Custom Implementation

**Prefer native `<input type="checkbox">`** - provides implicit `role="checkbox"` without ARIA attributes.

| Use Case | Recommended |
| --- | --- |
| Standard form input | Native `<input type="checkbox">` |
| Custom styling needed | Native with CSS (visually hidden input) |
| Complex widget without form semantics | Custom `role="checkbox"` |

## ARIA Requirements

### Roles

| Role | Element | Required | Description |
| --- | --- | --- | --- |
| `checkbox` | Control element | Yes | Implicit with `<input type="checkbox">`, explicit with `role="checkbox"` on custom elements |

### States

| Attribute | Element | Values | Required | Change Trigger |
| --- | --- | --- | --- | --- |
| `checked` | `<input>` | boolean | Yes | Click, Space key |
| `aria-checked` | Custom element | `true` / `false` / `mixed` | Yes (custom only) | Click, Space key |
| `indeterminate` | `<input>` | boolean (JS property) | No | Parent-child sync |
| `disabled` | `<input>` | boolean | No | - |
| `aria-disabled` | Custom element | `true` | When disabled | - |

### Properties

| Attribute | Element | Values | Required | Notes |
| --- | --- | --- | --- | --- |
| `aria-label` | Control | string | When no visible label | Accessible name |
| `aria-labelledby` | Control | ID reference | When no visible label | References external text |
| `aria-describedby` | Control | ID reference | No | Additional description |

## Keyboard Support

| Key | Action |
| --- | --- |
| `Space` | Toggle checkbox state |
| `Tab` | Move focus to next focusable element |

**Note**: Enter key does NOT toggle checkbox (unlike Switch pattern).

## Focus Management

- Native `<input type="checkbox">` is focusable by default
- Disabled checkboxes are skipped in Tab order
- Custom implementations require `tabindex="0"`

## Mixed State Behavior

When a mixed (indeterminate) checkbox is activated:

```
mixed → checked (true) → unchecked (false) → checked...
```

### Parent-Child Sync (Groups)

| Children State | Parent State |
| --- | --- |
| All checked | checked |
| All unchecked | unchecked |
| Some checked | mixed |

| Parent Action | Children Effect |
| --- | --- |
| Check | All children checked |
| Uncheck | All children unchecked |
| Activate when mixed | All children checked |

## Test Checklist

### High Priority: DOM State

- [ ] `role="checkbox"` exists (implicit via native or explicit)
- [ ] Unchecked by default
- [ ] Checked when `initialChecked=true`
- [ ] Click toggles checked state
- [ ] `indeterminate` property settable
- [ ] User action clears indeterminate state
- [ ] Disabled state prevents interaction

### High Priority: Label & Form

- [ ] Accessible name via `aria-label`
- [ ] Accessible name via external `<label>`
- [ ] `name` attribute for form submission
- [ ] `value` attribute set correctly

### High Priority: Keyboard

- [ ] Space key toggles state
- [ ] Tab moves focus to/from checkbox
- [ ] Disabled checkbox skipped by Tab
- [ ] Disabled checkbox ignores Space key

### Medium Priority: Accessibility

- [ ] No axe-core violations (all states)
- [ ] State visible without color alone (WCAG 1.4.1)

### Low Priority: HTML Attribute Inheritance

- [ ] Custom `className`/`class` merged correctly
- [ ] `data-*` attributes passed through
- [ ] `id` attribute set for label association

## Implementation Notes

### Common Pitfalls

1. **Form submission**: Unchecked checkbox sends nothing (not `false`). Handle on server or use hidden input.

2. **`indeterminate` is JS-only**: No HTML attribute exists. Must set via `element.indeterminate = true`.

3. **Focus ring on custom control**: Use adjacent sibling selector since input is visually hidden:
   ```css
   .input:focus-visible + .control { outline: 2px solid var(--focus); }
   ```

4. **Touch target size**: WCAG 2.5.5 recommends 44x44px minimum. The 20x20px control relies on wrapping `<label>` for adequate touch area.

### Structure

```
Structure (Native - Label-less Component):
<span class="apg-checkbox">
  <input type="checkbox" class="apg-checkbox-input" />
  <span class="apg-checkbox-control" aria-hidden="true">
    <span class="apg-checkbox-icon--check">✓</span>
    <span class="apg-checkbox-icon--indeterminate">−</span>
  </span>
</span>

Visually Hidden Input (keep 1x1px for compatibility):
.apg-checkbox-input {
  position: absolute;
  width: 1px;   /* Not 0 - some browsers ignore 0-sized elements */
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

Label Association Options:
1. Wrapping label (recommended)
<label>
  <Checkbox name="terms" />
  I agree to the terms
</label>

2. for/id association
<label for="newsletter">Subscribe</label>
<Checkbox id="newsletter" name="newsletter" />

3. aria-label (when no visible label)
<Checkbox aria-label="Select all items" />

4. aria-labelledby
<span id="label">Custom label</span>
<Checkbox aria-labelledby="label" />

Visual States (WCAG 1.4.1 - Use of Color):
- [ ] Empty box = unchecked
- [✓] Checkmark = checked
- [−] Dash = mixed/indeterminate
- Grayed + reduced opacity = disabled
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Role test
it('has role="checkbox"', () => {
  render(<Checkbox aria-label="Accept terms" />);
  expect(screen.getByRole('checkbox')).toBeInTheDocument();
});

// Toggle test
it('toggles checked state on click', async () => {
  const user = userEvent.setup();
  render(<Checkbox aria-label="Accept terms" />);

  const checkbox = screen.getByRole('checkbox');
  expect(checkbox).not.toBeChecked();

  await user.click(checkbox);
  expect(checkbox).toBeChecked();
});

// Keyboard test
it('toggles on Space key', async () => {
  const user = userEvent.setup();
  render(<Checkbox aria-label="Accept terms" />);

  const checkbox = screen.getByRole('checkbox');
  checkbox.focus();

  await user.keyboard(' ');
  expect(checkbox).toBeChecked();
});

// Indeterminate test
it('clears indeterminate on user action', async () => {
  const user = userEvent.setup();
  render(<Checkbox indeterminate aria-label="Select all" />);

  const checkbox = screen.getByRole('checkbox') as HTMLInputElement;
  expect(checkbox.indeterminate).toBe(true);

  await user.click(checkbox);
  expect(checkbox.indeterminate).toBe(false);
  expect(checkbox).toBeChecked();
});

// External label test
it('has accessible name via external label', () => {
  render(
    <>
      <label htmlFor="terms">Accept terms</label>
      <Checkbox id="terms" />
    </>
  );
  expect(
    screen.getByRole('checkbox', { name: 'Accept terms' })
  ).toBeInTheDocument();
});

// Wrapping label test
it('works with wrapping label', async () => {
  const user = userEvent.setup();
  render(
    <label>
      <Checkbox />
      Accept terms
    </label>
  );

  await user.click(screen.getByText('Accept terms'));
  expect(screen.getByRole('checkbox')).toBeChecked();
});
```
