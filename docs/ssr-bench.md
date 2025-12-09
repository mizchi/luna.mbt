# SSR Benchmark Results

MoonBit SSR rendering performance across different targets.

## Environment

- MoonBit SSR using StringBuilder for string building
- Targets: JS (V8), Native, Wasm-GC

## Results (StringBuilder version)

| Benchmark | JS | Native | Wasm-GC |
|-----------|-----|--------|---------|
| ssr_simple_text | 0.16 µs | 0.19 µs | **0.11 µs** |
| ssr_simple_div | 0.07 µs | 0.15 µs | 0.12 µs |
| ssr_div_with_text | 0.15 µs | 0.23 µs | **0.16 µs** |
| ssr_div_with_attrs | 0.37 µs | 0.44 µs | 0.37 µs |
| ssr_nested_3_levels | 0.23 µs | 0.40 µs | 0.35 µs |
| ssr_nested_5_levels | 0.39 µs | 0.63 µs | 0.53 µs |
| ssr_nested_10_levels | 0.68 µs | 0.98 µs | 0.87 µs |
| ssr_list_10_items | 1.38 µs | 1.61 µs | **1.14 µs** |
| ssr_list_100_items | 14.08 µs | 14.73 µs | **10.82 µs** |
| ssr_list_1000_items | 150.08 µs | 158.87 µs | **113.47 µs** |
| ssr_card_component | 1.39 µs | 1.52 µs | **1.21 µs** |
| ssr_100_cards | 87.39 µs | 98.29 µs | **75.74 µs** |
| ssr_dynamic_text | 0.20 µs | 0.18 µs | **0.12 µs** |
| ssr_dynamic_attr | 0.19 µs | 0.25 µs | 0.20 µs |
| ssr_100_dynamic_items | 21.09 µs | 20.35 µs | **13.41 µs** |
| ssr_hydration_simple | 0.17 µs | 0.24 µs | 0.18 µs |

## Comparison: String Concatenation vs StringBuilder

Before StringBuilder (using `result = result + ...`):

| Target | ssr_1000_items | ssr_100_cards |
|--------|----------------|---------------|
| JS | ~130 µs | ~81 µs |
| Native | ~814 µs | ~413 µs |
| Wasm-GC | ~350 µs | ~185 µs |

After StringBuilder:

| Target | ssr_1000_items | ssr_100_cards | Improvement |
|--------|----------------|---------------|-------------|
| JS | 150 µs | 87 µs | -15% (slight overhead) |
| Native | 159 µs | 98 µs | **5.1x faster** |
| Wasm-GC | 113 µs | 76 µs | **3.1x faster** |

## Key Findings

1. **Wasm-GC is fastest** after StringBuilder optimization
2. **Native improved 5x+** - string concatenation was the bottleneck
3. **JS slightly slower** - V8's string optimization was already efficient
4. **All targets now comparable** - portable SSR with consistent performance

## Additional Optimizations

After StringBuilder, the following optimizations were applied:

1. **Escape fast path**: Skip character-by-character escaping when string doesn't contain special characters
2. **Fixed size_hint**: Use `StringBuilder::new(size_hint=256)` to reduce initial allocations
3. **Kebab-case fast path**: Skip camelCase conversion when string is already lowercase

### Results After All Optimizations

| Benchmark | Wasm-GC | Native |
|-----------|---------|--------|
| ssr_list_100_items | 10.56 µs | 13.10 µs |
| ssr_list_1000_items | 118.67 µs | 160.43 µs |
| ssr_100_cards | 72.18 µs | 87.06 µs |
| ssr_full_page | 2.51 µs | 2.74 µs |
| ssr_inline_style | 0.41 µs | 0.39 µs |

### Total Improvement from Initial (String Concatenation)

| Target | ssr_1000_items | Total Speedup |
|--------|----------------|---------------|
| Native | 814 µs → 160 µs | **5.1x** |
| Wasm-GC | 350 µs → 119 µs | **2.9x** |

## Running Benchmarks

```bash
# JS target
moon bench --target js --package ssr

# Native target
moon bench --target native --package ssr

# Wasm-GC target
moon bench --target wasm-gc --package ssr
```
