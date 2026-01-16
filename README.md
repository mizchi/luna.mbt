# Luna

Island Architecture-based UI library implemented in MoonBit.

## Related Repositories

- **Sol** (SSR/SSG Framework): [mizchi/sol.mbt](https://github.com/mizchi/sol.mbt)

## Installation

```json
// moon.mod.json
{
  "deps": {
    "mizchi/luna": "0.7.0"
  }
}
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
