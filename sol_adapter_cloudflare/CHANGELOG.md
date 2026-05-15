# Changelog

All notable changes to `mizchi/sol_adapter_cloudflare` are documented here.

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
