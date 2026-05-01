---
title: Quick Start
---

# Quick Start

Get up and running with Luna in under 5 minutes.

## Create a New Project

### TypeScript/JSX

```bash
npx @luna_ui/luna new myapp
cd myapp
npm install
npm run dev
```

### MoonBit

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp
moon update
npm install
npm run dev
```

## What's Generated

### TSX Project Structure

```
myapp/
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── src/
    ├── main.tsx
    └── App.tsx
```

### MoonBit Project Structure

```
myapp/
├── index.html
├── package.json
├── moon.mod.json
├── vite.config.ts
├── main.ts
└── src/
    ├── moon.pkg.json
    └── lib.mbt
```

## Manual Setup

If you prefer to set up manually:

### Install

```bash
npm install @luna_ui/luna
```

### Configure TypeScript

**tsconfig.json:**

```json
{
  "compilerOptions": {
    "jsxImportSource": "@luna_ui/luna"
  }
}
```

### Configure Vite

**vite.config.ts:**

```ts
import { defineConfig } from 'vite';

export default defineConfig({
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: '@luna_ui/luna',
  },
});
```

## Next Steps

- [Signals](/luna/tutorial-js/introduction_signals) - Learn reactive state
- [Effects](/luna/tutorial-js/introduction_effects) - Side effects and cleanup
- [Components](/luna/tutorial-js/flow_show) - Conditional and list rendering
