# Changelog

All notable changes to `mizchi/sol_adapter_cloudflare` are documented here.

## [sol_adapter_cloudflare-v0.23.4] - 2026-10-19

- Update Sol and Cloudflare runtime dependencies for compiler compatibility.

## [sol_adapter_cloudflare-v0.23.3] - 2026-09-16

### Dependencies

- Update JavaScript bindings to 0.13.0 and migrate imports to the split modules.
- Align dependencies with the workspace patch releases.

## 0.22.1 (2026-05-15)

- Align the adapter dependency with `mizchi/sol` 0.22.1.

## 0.22.0 (2026-05-15)

- Align with `mizchi/sol` 0.22.0 typed action and contract generation APIs.
- Add coverage for adapter runtime contracts and Cloudflare binding helpers.

## 0.21.1 (2026-05-14)

- Fix generated Cloudflare projects to depend on
  `mizchi/sol_adapter_cloudflare` instead of the Node adapter.

## 0.21.0 (2026-05-14)

- Initial Cloudflare adapter package split from Sol core.
- Add Worker runtime entry helpers, Cloudflare binding validation utilities,
  and Wrangler/entrypoint generators.
