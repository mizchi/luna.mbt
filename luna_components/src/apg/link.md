# Link Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/link/

## Overview

A link is an interactive element that navigates to a resource when activated. Provides keyboard-accessible navigation with proper screen reader announcement.

## Native HTML vs Custom Implementation

**Prefer native `<a href>`** - provides full browser functionality automatically.

| Use Case | Recommended |
| --- | --- |
| Standard navigation | Native `<a href>` |
| JavaScript-driven navigation | Native `<a href>` with `event.preventDefault()` |
| Non-link element that navigates | Custom `role="link"` (educational purposes only) |

### Native `<a>` Advantages (Not Available in Custom)

| Feature | Native `<a>` | Custom `role="link"` |
| --- | --- | --- |
| Ctrl+Click new tab | Standard | Not supported |
| Right-click menu | Full | Limited |
| URL copy | Supported | Not supported |
| Drag to bookmarks | Supported | Not supported |
| SEO recognition | Yes | No |
| Works without JS | Yes | No |

## ARIA Requirements

### Roles

| Role | Element | Required | Description |
| --- | --- | --- | --- |
| `link` | `<span>`, `<div>`, etc. | Yes (custom only) | Implicit with `<a href>`, explicit with `role="link"` on custom elements |

### Properties

| Attribute | Element | Values | Required | Notes |
| --- | --- | --- | --- | --- |
| `tabindex` | Custom element | `0` / `-1` | Yes (custom only) | `0` = focusable, `-1` = disabled |
| `aria-label` | Link element | string | When no visible text | Accessible name |
| `aria-labelledby` | Link element | ID reference | When no visible text | References external text |
| `aria-current` | Link element | `page` / `step` / `location` / `date` / `time` / `true` | No | Indicates current item in a set |

### States

| Attribute | Element | Values | Required | Change Trigger |
| --- | --- | --- | --- | --- |
| `aria-disabled` | Link element | `true` / `false` | No | Disabled state change |

## Keyboard Support

| Key | Action |
| --- | --- |
| `Enter` | Activate link and navigate to target |

**Note**: Space key does NOT activate links (unlike buttons).

## Focus Management

- Native `<a href>` is focusable by default
- Custom links require `tabindex="0"`
- Disabled links use `tabindex="-1"` (removed from tab order)
- No roving tabindex needed (single element)

## Test Checklist

### High Priority: ARIA Attributes

- [ ] `role="link"` exists (implicit via native or explicit)
- [ ] `tabindex="0"` on custom link element
- [ ] Accessible name from text content
- [ ] Accessible name from `aria-label` when no text
- [ ] `aria-disabled="true"` when disabled
- [ ] `tabindex="-1"` when disabled

### High Priority: Keyboard

- [ ] Enter key activates link
- [ ] Space key does NOT activate link
- [ ] Ignores keydown when `event.isComposing === true` (IME)
- [ ] Ignores keydown when `event.defaultPrevented === true`

### High Priority: Click Behavior

- [ ] Click activates link
- [ ] Disabled link ignores click
- [ ] Disabled link ignores Enter key

### High Priority: Focus Management

- [ ] Focusable via Tab key
- [ ] Not focusable when disabled

### Medium Priority: Accessibility

- [ ] No axe-core violations (all states)

### Low Priority: Props & Navigation

- [ ] Navigates to `href` on activation
- [ ] Opens in new tab when `target="_blank"`
- [ ] Custom `className` applied correctly
- [ ] `data-*` attributes passed through

## Implementation Notes

### Common Pitfalls

1. **Space key**: Links are activated by Enter only, NOT Space. Space scrolls the page.

2. **IME input**: Check `event.isComposing` to avoid triggering during IME composition.

3. **Security for `target="_blank"`**: Always use `noopener,noreferrer` with `window.open()`.

4. **Disabled state**: Use both `aria-disabled="true"` AND `tabindex="-1"`. Prevent click/keydown handlers.

### Structure (Custom Implementation)

```
<span
  role="link"
  tabindex="0" (or "-1" when disabled)
  aria-disabled="false" (or "true")
>
  Link Text
</span>
```

### Navigation Logic

```typescript
const navigate = (href: string, target?: string) => {
  if (target === '_blank') {
    window.open(href, '_blank', 'noopener,noreferrer');
  } else {
    window.location.href = href;
  }
};
```

### CSS Requirements

```css
[role="link"] {
  cursor: pointer;
  text-decoration: underline;
  color: var(--link-color, blue);
}

[role="link"]:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

[role="link"][aria-disabled="true"] {
  cursor: not-allowed;
  opacity: 0.5;
  text-decoration: none;
}
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Role test
it('has role="link"', () => {
  render(<Link href="#">Click here</Link>);
  expect(screen.getByRole('link')).toBeInTheDocument();
});

// Accessible name test
it('has accessible name from text content', () => {
  render(<Link href="#">Learn more</Link>);
  expect(screen.getByRole('link', { name: 'Learn more' })).toBeInTheDocument();
});

// Enter key test
it('activates on Enter key', async () => {
  const handleClick = vi.fn();
  const user = userEvent.setup();
  render(<Link onClick={handleClick}>Click me</Link>);

  const link = screen.getByRole('link');
  link.focus();
  await user.keyboard('{Enter}');

  expect(handleClick).toHaveBeenCalledTimes(1);
});

// Space key should NOT activate
it('does not activate on Space key', async () => {
  const handleClick = vi.fn();
  const user = userEvent.setup();
  render(<Link onClick={handleClick}>Click me</Link>);

  const link = screen.getByRole('link');
  link.focus();
  await user.keyboard(' ');

  expect(handleClick).not.toHaveBeenCalled();
});

// Disabled test
it('is not focusable when disabled', () => {
  render(<Link href="#" disabled>Disabled link</Link>);

  const link = screen.getByRole('link');
  expect(link).toHaveAttribute('tabindex', '-1');
  expect(link).toHaveAttribute('aria-disabled', 'true');
});

// Click test
it('calls onClick on click', async () => {
  const handleClick = vi.fn();
  const user = userEvent.setup();
  render(<Link onClick={handleClick}>Click me</Link>);

  await user.click(screen.getByRole('link'));
  expect(handleClick).toHaveBeenCalledTimes(1);
});

// Disabled ignores interaction
it('does not call onClick when disabled', async () => {
  const handleClick = vi.fn();
  const user = userEvent.setup();
  render(<Link onClick={handleClick} disabled>Disabled</Link>);

  await user.click(screen.getByRole('link'));
  expect(handleClick).not.toHaveBeenCalled();
});
```
