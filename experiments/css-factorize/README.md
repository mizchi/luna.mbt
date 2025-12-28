# CSS Rule Factorization / Automatic Utility Class Derivation

## Problem

BEM and similar naming conventions cause CSS bloat:

```css
/* 154 bytes */
.card__header--highlighted { display: flex; align-items: center; padding: 1rem; }
.modal__footer--actions { display: flex; align-items: center; padding: 1rem; }
.sidebar__nav--expanded { display: flex; align-items: center; }
```

## Idea: CSS as Set of Rules

Treat CSS as a mathematical set. Given rules `{R1, R2, R3...}`, each rule is a set of declarations:

```
R1 = {display:flex, align-items:center, padding:1rem}
R2 = {display:flex, align-items:center, padding:1rem}
R3 = {display:flex, align-items:center}
```

### Factorization

Find common subsets and extract as utility classes:

```
U1 = R1 ∩ R2 ∩ R3 = {display:flex, align-items:center}  → .u0
U2 = R1 ∩ R2 - U1 = {padding:1rem}                      → .u1
```

Result:

```css
/* 89 bytes - 42% smaller */
.u0{display:flex;align-items:center}
.u1{padding:1rem}
```

Elements get composed classes:
- `card__header--highlighted` → `class="u0 u1"`
- `modal__footer--actions` → `class="u0 u1"`
- `sidebar__nav--expanded` → `class="u0"`

## Algorithm

1. **Parse**: Extract all CSS rules as `selector → Set<declaration>`
2. **Fingerprint**: Hash each declaration (e.g., `display:flex` → `df`)
3. **Cluster**: Find frequently co-occurring declaration sets
4. **Factor**: Extract common sets as utility classes
5. **Compress**:
   - Utility class names: single char (`a`, `b`, ... `z`, `a0`, ...)
   - Property names: abbreviate (`display` → `d`, `flex` → `f`)

## Runtime Compression Option

Instead of expanding utilities at build time, use runtime expansion:

```js
// Compressed payload
const U = {a:"display:flex",b:"align-items:center",c:"padding:1rem"};
const M = {"card__header--highlighted":"abc","modal__footer":"ab"};

// Runtime: inject <style> with expanded rules
```

This trades CPU for bandwidth - good for large CSS bundles.

## Comparison with Tailwind

| Approach | Tailwind | This |
|----------|----------|------|
| Class definition | Manual (write `flex`, `items-center`) | Automatic (derived from existing CSS) |
| Granularity | Fixed utility set | Adaptive to actual usage |
| Class names | Semantic (`flex`) | Minimal (`a`) |
| Build step | Required | Required |

## Implementation Phases

1. **Phase 1**: Static factorization (build time)
   - Parse CSS → factor → output minified CSS + class mapping

2. **Phase 2**: Runtime expansion
   - Output compressed payload + tiny runtime (~200b)

3. **Phase 3**: MoonBit integration
   - Track styles in Luna components
   - Automatic class composition

## Benchmark Results

### Test CSS (BEM-style components)

```
Original: 2,172 bytes
Optimized: 932 bytes
Reduction: 57.1%
Utilities: 7
```

### Real CSS (Astra main.css - 43KB)

```
Original: 43,164 bytes
Optimized: 20,480 bytes
Reduction: 52.6%
Utilities: 167
Selectors factored: 274/329
```

### Bootstrap 5.3 (232KB)

```
Original: 232,911 bytes
Optimized: 108,382 bytes
Reduction: 53.5%
Utilities: 519
Selectors factored: 2,120/2,455
```

### Bulma 0.9 (207KB)

```
Original: 207,302 bytes
Optimized: 43,124 bytes
Reduction: 79.2%  ← Best case!
Utilities: 444
Selectors factored: 1,774/2,102
```

### Tailwind Preflight (8KB)

```
Original: 7,695 bytes
Optimized: 6,556 bytes
Reduction: 14.8%  ← Already utility-first, minimal gain
```

**Observation**: Component-based CSS (BEM, Bulma) benefits most. Utility-first CSS (Tailwind) already optimized.

## Runtime Compression (Experimental)

For even smaller payloads, the runtime format further compresses:

```js
// Compressed payload (~2KB for 43KB CSS)
const payload = {
  D: { A: "display:flex", B: "align-items:center", ... },  // Declaration dict
  U: { a: "AB", b: "C", ... },                              // Utility defs
  M: { "card__header": "a b", ... }                         // Class mapping
};

// Runtime expander (~180 bytes)
expandCSS(payload);  // Injects <style>
```

Total: ~2.2KB payload + 180 byte runtime = **~95% reduction** vs 43KB original

## Files

- `factorize.js` - Core algorithm prototype
- `runtime.js` - Runtime CSS expander
- `test.css` - Sample BEM-style CSS for testing

## Usage

```bash
# Static factorization
node factorize.js input.css

# Show class mapping
node factorize.js input.css --mapping

# Runtime format
node factorize.js input.css --runtime
```

## Next Steps

1. **Property name shortening**: `display` → `d`, `flex` → `f`
2. **Value deduplication**: Common values like `1rem`, `#fff`
3. **Selector optimization**: Combine same-content rules
4. **MoonBit integration**: Track styles at compile time
