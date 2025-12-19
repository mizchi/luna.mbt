---
title: Sol Framework
---

# Sol Framework

> **Experimental**: Sol is under active development. APIs will change without notice.

Sol is a full-stack SSR framework built on Luna UI and MoonBit.

## Features

- **File-based Routing** - Pages and API routes from directory structure
- **Island Hydration** - Ship minimal JavaScript with smart triggers
- **Type-safe Server/Client** - MoonBit types flow from server to browser
- **Hono Integration** - Fast, lightweight HTTP server

## Quick Start

```bash
# Create a new Sol project
npx sol new my-app
cd my-app

# Development
npm run dev

# Production build
npm run build
```

## Project Structure

```
my-app/
├── app/
│   ├── pages/           # File-based routes
│   │   ├── index.mbt    # /
│   │   └── about.mbt    # /about
│   ├── islands/         # Interactive components
│   │   └── counter.mbt
│   └── api/             # API routes
│       └── hello.mbt    # /api/hello
├── sol.config.json
└── moon.mod.json
```

## Pages

```moonbit
// app/pages/index.mbt
pub fn page() -> @luna.Node[Unit] {
  @luna.h("div", [], [
    @luna.h("h1", [], [@luna.text("Welcome to Sol")]),
    @luna.h("p", [], [@luna.text("A MoonBit SSR framework")]),
  ])
}
```

## Islands

```moonbit
// app/islands/counter.mbt
pub fn hydrate(el : @dom.Element, state : CounterState) -> Unit {
  let count = @luna.signal(state.initial)

  @dom.render(el, @dom.button(
    on=@dom.events().click(_ => count.update(n => n + 1)),
    [@dom.text_dyn(() => "Count: " + count.get().to_string())]
  ))
}
```

## Status

Sol is experimental and not ready for production use. We recommend:

- Use [Astra](/astra/) for static documentation sites
- Use Luna UI directly for client-side applications
- Follow the [GitHub repository](https://github.com/aspect-build/aspect-cli) for updates

## See Also

- [Luna UI Guide](/guide/) - Core reactivity concepts
- [Astra SSG](/astra/) - Static site generation
