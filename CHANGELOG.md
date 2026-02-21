# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Add hydration module URL origin policy in `loader.js` with `window.__LUNA_ALLOWED_HOSTS__` and `window.__LUNA_SET_ALLOWED_HOSTS__`
- Add asset sync workflows and checks: `scripts/sync-example-static-assets.mjs`, `scripts/sync-luna-loader-assets.mjs`, `just sync-*` tasks, and E2E sync tests

### Changed

- Unify loader runtime asset sources under `src/ssg/assets/scripts/*` and keep `examples/*/static/*` synchronized from canonical sources
- Update example package scripts (`predev` / `prebuild` / `preserve` / `pretest`) to auto-sync runtime static assets

### Fixed

- Preserve API response headers set in handlers while keeping JSON `Content-Type` and `X-Content-Type-Options: nosniff` defaults

## [0.8.0] - 2026-02-19

### Added

- Add blackbox tests for `register_sol_routes` streaming/fragment/ISR branching via `app.to_handler`
- Add `render_streaming_template_parts` to apply `root_template` in streaming SSR path

### Changed

- Merge streaming SSR and route rendering behavior around `root_template`
- Improve route/middleware/runtime cleanup and duplication reduction toward thin `mars` wrapper
- Expand docs coverage and consistency checks (`test-docs`, benchmark docs, routing/docs references)

### Fixed

- Preserve `ctx.set_header` headers in streaming responses (`X-Sol-Cache-Strategy` etc.)
- Harden cleanup order for `target -> _build` transition
- Align generated/scaffolded project templates with latest Sol/Mars setup

## [0.7.1] - 2026-02-19

### Changed

- Upgrade `mizchi/mars` dependency to `0.3.9`
- Align example modules to `mizchi/mars` `0.3.9`

## [0.2.0] - 2026-01-13

### Added

- **ISR (Incremental Static Regeneration)**: Add ISR cache system with Cloudflare KV support
- **Cloudflare Workers**: Add deployment support with KV-based ISR
- **TypeScript Support**: Add JSX runtime for TypeScript SSR (`@luna_ui/luna` package)
- **sol_tsx example**: Pure TypeScript mode example project
- **sol_blog example**: Blog with ISR caching demonstration
- **Benchmark suite**: Add Sol vs Hono comparison and k6 load testing scripts
- **sol CLI npm bin**: Install sol CLI via npm package

### Changed

- **luna 0.5.2**: Upgrade luna dependency with updated import paths (`mizchi/luna/*`)
- **pnpm monorepo**: Convert to pnpm workspace with package references
- **CI**: Migrate from illusory0x0/setup-moonbit to hustcer/setup-moonbit@v1
- **Templates**: Align with `app/server` structure and `sol.config.ts`

### Fixed

- WC (Web Component) hydration after CSR navigation
- Dev mode cache control headers
- CLI paths in example projects
- E2E test stability improvements

## [0.1.0] - Initial Release

- SSR/SSG Framework for Luna UI
- Island Architecture with partial hydration
- File-based routing
- Markdown/MDX support
- CSS Utilities extraction
