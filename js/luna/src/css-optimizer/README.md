# CSS Co-occurrence Optimizer

A standalone, framework-agnostic library for optimizing CSS by merging frequently co-occurring classes. Works with HTML, React, Svelte, Vue, and any framework that uses class-based styling.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CSS Optimizer                            │
├─────────────────────────────────────────────────────────────┤
│  Extractors          Core              Transformers         │
│  ┌──────────┐    ┌──────────┐      ┌──────────────┐        │
│  │ HTML     │    │ Pattern  │      │ HTML         │        │
│  │ JSX/TSX  │───▶│ Analysis │─────▶│ JSX/TSX      │        │
│  │ Svelte   │    │ + Merge  │      │ Svelte       │        │
│  │ Custom   │    └──────────┘      │ Custom       │        │
│  └──────────┘                      └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

- **Extractors**: Pluggable class extraction from different source formats
- **Core**: Framework-agnostic pattern analysis and CSS generation
- **Transformers**: Pluggable output transformation for different formats

## Installation

```bash
npm install @luna_ui/luna
```

## Quick Start

### Framework-Agnostic Usage (Recommended)

```typescript
import {
  optimizeCore,
  htmlExtractor,
  htmlTransformer,
} from "@luna_ui/luna/css-optimizer";

// 1. Extract class usages from your source files
const usages = htmlExtractor.extract(html, { classPrefix: "_" });

// 2. Build class-to-declaration mapping
const classToDecl = new Map([
  ["_flex", "display:flex"],
  ["_gap", "gap:1rem"],
  ["_p4", "padding:1rem"],
]);

// 3. Optimize
const result = optimizeCore(usages, css, classToDecl, {
  minFrequency: 2,
  maxPatternSize: 5,
});

// 4. Transform output
const optimizedHtml = htmlTransformer.transform(html, result.mergeMap);

console.log(result.css);        // Optimized CSS
console.log(optimizedHtml);     // Transformed HTML
console.log(result.stats);      // { mergedPatterns, estimatedBytesSaved, ... }
```

### React/JSX Usage

```typescript
import {
  optimizeCore,
  jsxExtractor,
  jsxTransformer,
} from "@luna_ui/luna/css-optimizer";

// Extract from JSX
const usages = jsxExtractor.extract(jsxCode);

// ... optimize ...

// Transform JSX
const optimizedJsx = jsxTransformer.transform(jsxCode, result.mergeMap);
```

### Svelte Usage

```typescript
import {
  optimizeCore,
  svelteExtractor,
  svelteTransformer,
} from "@luna_ui/luna/css-optimizer";

// Extract from Svelte (preserves {expressions})
const usages = svelteExtractor.extract(svelteCode);

// ... optimize ...

// Transform Svelte (preserves {expressions})
const optimizedSvelte = svelteTransformer.transform(svelteCode, result.mergeMap);
```

### Multi-Framework Projects

```typescript
import {
  optimizeCore,
  multiExtractor,
  multiTransformer,
} from "@luna_ui/luna/css-optimizer";

// Extract from multiple file types
const files = [
  { content: htmlCode, path: "index.html" },
  { content: reactCode, path: "app.tsx" },
  { content: svelteCode, path: "widget.svelte" },
];

const usages = multiExtractor.extractFromFiles(files);

// ... optimize ...

// Transform all files
const transformedFiles = multiTransformer.transformFiles(files, result.mergeMap);
```

### Luna-Specific Convenience API

For Luna projects, use the simplified API:

```typescript
import { optimizeCss, optimizeHtml } from "@luna_ui/luna/css-optimizer";

// Luna uses declaration -> className mapping
const mapping = {
  "display:flex": "_flex",
  "gap:1rem": "_gap",
};

const result = optimizeCss(css, html, mapping, {
  minFrequency: 2,
});

const optimizedHtml = optimizeHtml(html, result.mergeMap);
```

## API Reference

### Core Functions

#### `optimizeCore(usages, css, classToDeclaration, options?)`

Framework-agnostic core optimizer.

```typescript
function optimizeCore(
  usages: ClassUsage[],
  css: string,
  classToDeclaration: Map<string, string>,
  options?: CoreOptimizeOptions
): CoreOptimizeResult;
```

#### `applyMergeToClasses(classes, mergeMap, classPrefix?)`

Apply merge map to a class array (useful for runtime optimization).

```typescript
function applyMergeToClasses(
  classes: string[],
  mergeMap: Map<string, string>,
  classPrefix?: string
): string[];
```

### Extractors

All extractors implement the `ClassExtractor` interface:

```typescript
interface ClassExtractor {
  name: string;
  extract(content: string, options?: ExtractorOptions): ClassUsage[];
}

interface ExtractorOptions {
  classPrefix?: string;  // Filter classes by prefix (default: "_")
  minClasses?: number;   // Minimum classes per element (default: 2)
  source?: string;       // Source identifier for debugging
}
```

| Extractor | Description | Import |
|-----------|-------------|--------|
| `HtmlExtractor` | Extracts from `class="..."` | `htmlExtractor` |
| `JsxExtractor` | Extracts from `className="..."` | `jsxExtractor` |
| `SvelteExtractor` | Extracts from `class="..."`, preserves `{expr}` | `svelteExtractor` |
| `MultiExtractor` | Auto-selects by file extension | `multiExtractor` |

### Transformers

All transformers implement the `ClassTransformer` interface:

```typescript
interface ClassTransformer {
  name: string;
  transform(
    content: string,
    mergeMap: Map<string, string>,
    options?: TransformerOptions
  ): string;
}

interface TransformerOptions {
  classPrefix?: string;  // Class prefix for identifying mergeable classes
}
```

| Transformer | Description | Import |
|-------------|-------------|--------|
| `HtmlTransformer` | Transforms `class="..."` | `htmlTransformer` |
| `JsxTransformer` | Transforms `className="..."` | `jsxTransformer` |
| `SvelteTransformer` | Transforms `class="..."`, preserves `{expr}` | `svelteTransformer` |
| `MultiTransformer` | Auto-selects by file extension | `multiTransformer` |

### Options

```typescript
interface CoreOptimizeOptions {
  minFrequency?: number;     // Min occurrences to merge (default: 2)
  maxPatternSize?: number;   // Max classes per pattern (default: 5)
  pretty?: boolean;          // Pretty-print CSS (default: false)
  verbose?: boolean;         // Enable logging (default: false)
}
```

### Custom Extractors

```typescript
import { ClassExtractor, ClassUsage } from "@luna_ui/luna/css-optimizer";

class VueExtractor implements ClassExtractor {
  name = "vue";

  extract(content: string, options = {}): ClassUsage[] {
    // Parse Vue SFC template section
    // Return array of ClassUsage objects
  }
}

// Register with MultiExtractor
multiExtractor.register("vue", new VueExtractor());
```

## Build Tool Integration

### Vite Plugin (Luna)

```typescript
// vite.config.ts
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default {
  plugins: [
    lunaCss({
      src: ["src"],
      experimental: {
        optimize: true,
        optimizeMinFrequency: 2,
        optimizeMaxPatternSize: 5,
      },
    }),
  ],
};
```

### Generic Build Pipeline

```typescript
// build.ts
import {
  optimizeCore,
  multiExtractor,
  multiTransformer,
} from "@luna_ui/luna/css-optimizer";
import { readFileSync, writeFileSync } from "fs";
import { glob } from "glob";

// 1. Collect source files
const files = glob.sync("src/**/*.{html,jsx,tsx,svelte}").map((path) => ({
  path,
  content: readFileSync(path, "utf-8"),
}));

// 2. Extract class usages
const usages = multiExtractor.extractFromFiles(files);

// 3. Build class-to-declaration map (from your CSS tool)
const classToDecl = buildClassMap(css);

// 4. Optimize
const result = optimizeCore(usages, css, classToDecl);

// 5. Write optimized CSS
writeFileSync("dist/styles.css", result.css);

// 6. Transform source files
const transformed = multiTransformer.transformFiles(files, result.mergeMap);
for (const file of transformed) {
  writeFileSync(`dist/${file.path}`, file.content);
}
```

## How It Works

### Pattern Mining

1. **Extract**: Parse source files to find class attribute values
2. **Analyze**: Count co-occurrence frequency of class combinations
3. **Mine**: Find patterns (pairs, triples, etc.) that meet frequency threshold
4. **Filter**: Remove subsumed patterns (subsets with similar frequency)
5. **Merge**: Generate combined CSS rules with deterministic class names

### Savings Estimation

```
HTML savings = (classCount - 1) * avgClassNameLength * frequency
CSS savings  = (classCount - 1) * avgRuleSize
```

### Deterministic Naming

Merged classes use DJB2 hash of sorted declarations:
```
_flex _gap _p4 → _m2rld5
```

This ensures consistent naming across builds.

## Limitations

- Regex-based extraction (not full AST)
- Only static class values (not computed/dynamic)
- Pseudo-class/media rules preserved but not merged
- Single-quoted class attributes not supported (use double quotes)

## Future Improvements

- [ ] AST-based extraction for React/Svelte
- [ ] Dynamic class detection
- [ ] Pseudo-class pattern merging
- [ ] Source map generation
- [ ] Webpack plugin
- [ ] CLI tool
