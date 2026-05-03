# Sol Native Compatibility Roadmap

## Current State (2026-03-18)

### What's done

- `ApiHandler`: `async (PageProps) -> Json` — no `@js.Any`
- `ApiResponse` enum and helpers — pure MoonBit
- Route helpers (`route`, `api_get`, `wrap`, `with_mw`, `nodes`) — pure MoonBit
- Streaming SSR uses portable `luna/core/stream_render` (native + js + wasm-gc)
- Router JS FFI isolated in `sol_routes_ffi_js.mbt`
- `router_core` package compiles on native (RequestProps, ApiResponse, helpers)
- Bench servers: `src/bench_native_api/` (native) and `src/bench_js_api/` (JS)
- Header/footer streaming logic moved to MoonBit side (only ReadableStream FFI wrapper is JS)

### Benchmark (k6, 10 VUs, 10s)

| | Native | JS (Node.js) | Ratio |
|---|---|---|---|
| req/s | ~12,400 | ~16,800 | Native ≈ 73% of JS |
| avg latency | ~768µs | ~556µs | |
| keep-alive single | 175µs | — | |

### Profile Analysis (macOS `sample`, under k6 load)

| Category | % of CPU | Top functions |
|---|---|---|
| **RC (refcount)** | ~15% | `decref_inlined`(206), `incref_inlined`(138), `drop_object`(71), `malloc/free`(111) |
| **String/Buffer** | ~13% | `write_string_utf8`(90), `encode_utf8`(85), `write_char`(78), `json.stringify`(72) |
| **HTTP send** | ~11% | `Sender::write`(101+50), `send_headers`(56), `send_response`(51) |
| **Hash/Map** | ~6% | `Hasher::combine_string`(49), `hash`(43) |
| **to_lower** | ~1% | `String::to_lower`(33) |

### Key findings

1. **RC overhead is dominant** (~15%). MoonBit's reference counting for short-lived HTTP objects (headers Map, response strings) causes high incref/decref traffic. This is a compiler optimization issue (escape analysis, RC elision).

2. **Json.stringify → String → UTF-8 encode is triple-copy** (~13%). The path is `Json → String (stringify) → Bytes (encode) → socket write`. A direct Json-to-bytes serializer would halve this.

3. **HTTP headers are written in 4+ small writes per header** (~11%). `send_headers` calls `write(k)`, `write(": ")`, `write(v)`, `write("\r\n")` per header. Concatenating into a single buffer write would reduce overhead.

4. **HashMap for header storage** (~6%). Header keys are hashed with `combine_string` on every lookup. For the small number of headers in API responses (2-3), a simple array of pairs would be faster.

5. **Content-Length optimization showed no improvement**. Tested adding `SendingFixedBody` mode to skip chunked encoding — performance was the same, confirming the bottleneck is not in chunked encoding but in the layers above (RC, string ops).

## What can be improved (by layer)

### Application layer (sol/mars) — Low impact

- [x] Content-Length responses — tested, no measurable improvement
- [ ] Pre-serialize common JSON responses (cache stringify result)
- [ ] Avoid HashMap for response headers when count < 4

### moonbitlang/async HTTP layer — Medium impact

- [ ] Batch header writes into single buffer write in `send_headers`
- [ ] send_buf size increase (1024 → 8192) — tested, no measurable improvement
- [ ] Direct Json-to-bytes path bypassing String intermediate

### MoonBit runtime — High impact (not actionable by us)

- [ ] RC elision for short-lived objects (escape analysis)
- [ ] Faster string hashing
- [ ] Arena allocator for request-scoped objects

## Phase 1 (completed)

- [x] Replace `ffi_parse_int`/`ffi_is_nan` with `@strconv.parse_int`
- [x] Move streaming FFI to `_js.mbt` files
- [x] Replace `ffi_json_stringify_error` with `Json.stringify()`
- [x] Streaming SSR logic moved to MoonBit (portable `luna/core/stream_render`)
- [x] `router_core` package (native-compatible types + helpers)

## Phase 2: Streaming SSR on native

- [x] `luna/core/stream_render` — 10 tests pass on native
- [x] `node.resolve()` moved inside ReadableStream for proper TTFB
- [ ] Native streaming via `mars Context::write_raw` + `end_response`
  (code path is ready, needs `sol_routes_ffi_native.mbt`)

## Phase 3: Package split

Blocked by `import ... for "js"` not supported in MoonBit.
Alternative: `router_core` package provides portable types.
Full router remains JS-only due to `@middleware`, `@isr` deps.

## Dependency chain for native patches

```
moonbitlang/async (send.mbt, parser.mbt)
  ↓
mizchi/x (http_native.mbt — wraps async/http)
  ↓
mizchi/mars (context_native.mbt — uses x/http)
  ↓
mizchi/sol (bench_native_api — uses mars)
```

All 4 repos need `path` overrides in moon.mod.json for local patching.
