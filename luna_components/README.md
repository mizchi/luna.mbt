# luna_components

Headless + styled UI components for [Luna UI](https://github.com/mizchi/luna.mbt) following the [WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/) patterns.

Status: experimental.

## Layout

| Path | Role |
|------|------|
| `src/`            | Top-level components (one file per pattern) |
| `src/aria/`       | ARIA attribute primitives |
| `src/headless/`   | Logic-only state machines (no DOM styling) |
| `src/styled/`     | Default-styled wrappers over `headless` |
| `src/apg/`        | APG-pattern reference scaffolding |

## Install

```jsonc
// moon.mod.json
{
  "deps": {
    "mizchi/luna": "0.20.0",
    "mizchi/luna_components": "0.20.0"
  }
}
```

## Examples

The APG playground (`examples/apg-playground/`) is the canonical demo and ships with the live deploy at <https://luna-examples.mizchi.workers.dev/apg-playground/>.
