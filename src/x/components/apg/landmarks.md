# Landmarks Pattern - AI Implementation Guide

> APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/landmarks/

## Overview

Landmarks identify the major sections of a page. There are eight landmark roles that enable assistive technology users to efficiently navigate page structure.

## ARIA Requirements

### Roles

| Role            | HTML Element            | Description                      | Constraint                          |
| --------------- | ----------------------- | -------------------------------- | ----------------------------------- |
| `banner`        | `<header>`              | Site-wide header                 | One per page, top-level only        |
| `navigation`    | `<nav>`                 | Navigation links                 | Multiple allowed, label when >1     |
| `main`          | `<main>`                | Primary content                  | One per page, top-level only        |
| `contentinfo`   | `<footer>`              | Site-wide footer                 | One per page, top-level only        |
| `complementary` | `<aside>`               | Supporting content               | Top-level recommended               |
| `region`        | `<section>`             | Named section                    | **Requires aria-label/labelledby**  |
| `search`        | `<form role="search">`  | Search functionality             | Use with form element               |
| `form`          | `<form>`                | Form area                        | **Requires aria-label/labelledby**  |

### Properties (Static Attributes)

| Attribute          | Target          | Values     | Required    | Notes                               |
| ------------------ | --------------- | ---------- | ----------- | ----------------------------------- |
| `aria-label`       | All landmarks   | String     | Conditional | When multiple of same type, or region/form |
| `aria-labelledby`  | All landmarks   | ID ref     | Conditional | Reference visible heading           |

### States (Dynamic Attributes)

None - Landmarks are static structural elements.

## HTML Element Auto-Mapping

| HTML Element  | ARIA Role       | Auto-mapping Condition                           |
| ------------- | --------------- | ------------------------------------------------ |
| `<header>`    | `banner`        | Only when direct child of `<body>`               |
| `<nav>`       | `navigation`    | Always                                           |
| `<main>`      | `main`          | Always                                           |
| `<footer>`    | `contentinfo`   | Only when direct child of `<body>`               |
| `<aside>`     | `complementary` | Always                                           |
| `<section>`   | `region`        | **Only when aria-label/labelledby is present**   |
| `<form>`      | `form`          | **Only when aria-label/labelledby is present**   |

## Keyboard Support

**None** - Landmarks are not interactive elements. Screen readers provide built-in landmark navigation (e.g., NVDA `D` key, VoiceOver rotor).

## Focus Management

Not applicable - Landmarks are not focusable.

## Test Checklist

### High Priority: Landmark Structure

- [ ] Has banner landmark (`<header>` or `role="banner"`)
- [ ] Has navigation landmark (`<nav>` or `role="navigation"`)
- [ ] Has main landmark (`<main>` or `role="main"`)
- [ ] Has contentinfo landmark (`<footer>` or `role="contentinfo"`)
- [ ] Has search landmark (`<form role="search">`)
- [ ] Has form landmark with accessible name
- [ ] Has exactly one main landmark
- [ ] Banner is at top level (not inside article/aside/main/nav/section)
- [ ] Contentinfo is at top level

### High Priority: Labeling

- [ ] Navigation landmarks have unique labels when multiple
- [ ] Complementary landmarks have unique labels when multiple
- [ ] Region landmarks have accessible name (aria-label or aria-labelledby)
- [ ] Form landmarks have accessible name

### Medium Priority: Accessibility

- [ ] No axe-core violations (WCAG 2.1 AA)

### Checklist (Recommendations, Not Test Requirements)

- [ ] All content is within landmarks (recommended but not required)
- [ ] Total landmarks ≤ 7 (too many can be overwhelming)

## Implementation Notes

```
Structure Diagram:
┌─────────────────────────────────────────────────────────────┐
│ <header> role="banner"                                       │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <nav aria-label="Main"> role="navigation"               │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ <main> role="main"                                           │
│ ┌─────────────────────┐ ┌─────────────────────────────────┐ │
│ │ <section            │ │ <aside aria-label="Related">    │ │
│ │   aria-labelledby>  │ │   role="complementary"          │ │
│ │   role="region"     │ │                                 │ │
│ └─────────────────────┘ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <form role="search" aria-label="Site search">           │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <form aria-label="Contact form"> role="form"            │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ <footer> role="contentinfo"                                  │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <nav aria-label="Footer"> role="navigation"             │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

Key Points:
- Prefer semantic HTML elements over ARIA roles
- header/footer only map to banner/contentinfo at body level
- section without label is NOT a region landmark
- form without label is NOT a form landmark
- <search> element has limited browser support, use <form role="search">
```

## Example Test Code (React + Testing Library)

```typescript
import { render, screen } from '@testing-library/react';

// Has banner landmark
it('has banner landmark', () => {
  render(<LandmarkDemo />);
  expect(screen.getByRole('banner')).toBeInTheDocument();
});

// Has navigation landmarks with unique labels
it('has navigation landmarks with unique labels', () => {
  render(<LandmarkDemo />);
  const navs = screen.getAllByRole('navigation');
  const labels = navs.map(nav =>
    nav.getAttribute('aria-label') ||
    nav.querySelector('[aria-labelledby]')?.id
  );
  const uniqueLabels = new Set(labels);
  expect(uniqueLabels.size).toBe(navs.length);
});

// Has exactly one main landmark
it('has exactly one main landmark', () => {
  render(<LandmarkDemo />);
  expect(screen.getAllByRole('main')).toHaveLength(1);
});

// Region has accessible name
it('region has accessible name', () => {
  render(<LandmarkDemo />);
  const region = screen.getByRole('region');
  expect(region).toHaveAccessibleName();
});

// Search landmark exists
it('has search landmark', () => {
  render(<LandmarkDemo />);
  expect(screen.getByRole('search')).toBeInTheDocument();
});
```
