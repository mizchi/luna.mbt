# Breadcrumb Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/

## Overview

A breadcrumb trail shows the user's location in a site hierarchy and provides navigation to ancestor pages.

## ARIA Requirements

### Roles

| Role         | Element | Description                      |
| ------------ | ------- | -------------------------------- |
| `navigation` | `<nav>` | Implicit role, provides landmark |

### Properties

| Attribute      | Element      | Values                      | Required | Notes               |
| -------------- | ------------ | --------------------------- | -------- | ------------------- |
| `aria-label`   | `<nav>`      | "Breadcrumb" (or localized) | Yes      | Labels the landmark |
| `aria-current` | Current page | `"page"`                    | Yes      | On last item        |

## Keyboard Support

| Key     | Action                   |
| ------- | ------------------------ |
| `Tab`   | Move focus between links |
| `Enter` | Activate focused link    |

> Uses native `<a>` element behavior. No additional handlers needed.

## Test Checklist

### High Priority: ARIA

- [ ] `<nav>` element is used
- [ ] `<nav>` has `aria-label="Breadcrumb"` (or localized)
- [ ] Last item has `aria-current="page"`
- [ ] Links use native `<a>` elements

### High Priority: Structure

- [ ] Uses ordered list (`<ol>`) for hierarchy
- [ ] Each breadcrumb is a list item (`<li>`)
- [ ] Current page is identifiable (text or aria-current)

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)
- [ ] Visual separators are decorative (hidden from AT)

## Implementation Notes

```html
Structure:
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/shoes" aria-current="page">Shoes</a></li>
  </ol>
</nav>

Separators: - Use CSS (::before/::after) for visual separators - Do NOT use text separators that are
read by screen readers - If using icons, add aria-hidden="true" Current Page Options: 1. Link with
aria-current="page" (navigable) 2. Plain text (not linked) - less common Screen Reader Announcement:
"Breadcrumb navigation, list, 3 items, Home, link, 1 of 3, Products, link, 2 of 3, Shoes, link,
current page, 3 of 3"
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';

// Navigation landmark
it('has navigation with aria-label', () => {
  render(<Breadcrumb items={items} />);
  expect(screen.getByRole('navigation', { name: /breadcrumb/i }))
    .toBeInTheDocument();
});

// Current page
it('marks current page with aria-current', () => {
  render(<Breadcrumb items={items} />);
  const currentLink = screen.getByRole('link', { name: 'Shoes' });
  expect(currentLink).toHaveAttribute('aria-current', 'page');
});

// List structure
it('uses ordered list', () => {
  render(<Breadcrumb items={items} />);
  expect(screen.getByRole('list')).toBeInTheDocument();
  expect(screen.getAllByRole('listitem')).toHaveLength(3);
});
```
