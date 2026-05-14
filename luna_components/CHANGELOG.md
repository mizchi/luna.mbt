# Changelog

All notable changes to this project will be documented in this file.

## [luna_components-v0.21.0] - 2026-05-14

### Changed

- Align with `mizchi/luna` 0.21.0.

## [luna_components-v0.20.1] - 2026-05-10

### Initial release

Spun out from `mizchi/luna` 0.20.0. Files moved verbatim from the
former `luna/src/x/components/` tree, with import paths rewritten to
the new mooncake namespace and the apg-playground demo carried along
under `src/examples/`.

Contents:

- `src/`           — top-level pattern modules (alert, breadcrumb, button,
  checkbox, combobox, dialog, disclosure, landmarks, link, listbox,
  menu_button, meter, radio, slider, spinbutton, switch, table, tabs,
  toolbar, tooltip, treeview, accordion, …)
- `src/aria/`      — ARIA attribute primitives
- `src/headless/`  — logic-only state machines (no DOM styling)
- `src/styled/`    — default-styled wrappers over `headless`
- `src/apg/`       — APG-pattern reference docs
- `src/examples/apg-playground/` — full demo
