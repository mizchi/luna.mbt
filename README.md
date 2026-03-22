# Luna

Island Architecture-based UI library implemented in MoonBit.

## Related Repositories

- **Sol** (SSR/SSG Framework): [mizchi/sol.mbt](https://github.com/mizchi/sol.mbt)

## Installation

```sh
moon add mizchi/luna
```

## Quick Start

### TypeScript/JSX Project

```sh
npx @luna_ui/luna new myapp
cd myapp
npm install
npm run dev
```

### MoonBit Project

```sh
npx @luna_ui/luna new myapp --mbt
cd myapp
moon update
npm install
npm run dev
```

## Packages

| Package | Description |
|---------|-------------|
| `mizchi/luna/js/resource` | Reactive signals |
| `mizchi/luna/dom` | DOM operations, Hydration |
| `mizchi/luna/core/render` | VNode → HTML rendering |
| `mizchi/luna/x/css` | CSS Utilities |
| `mizchi/luna/core/routes` | Route matching |
| `mizchi/luna/dom/browser_router` | Browser router |
| `mizchi/luna/x/components` | UI components |

## Development

```bash
just check      # Type check
just fmt        # Format
just test-unit  # MoonBit tests
just test-e2e   # E2E tests
```

## License

MIT
