# MoonBit Native HTTP Server Performance Analysis (Sol/Mars)

## Context

I'm building [Sol](https://github.com/mizchi/sol.mbt), an SSR web framework for MoonBit that uses [Mars](https://github.com/mizchi/mars.mbt) (Hono-inspired router) on top of `moonbitlang/async` HTTP server. As part of native target support, I benchmarked a minimal JSON API server comparing MoonBit native vs Node.js (same MoonBit code compiled to JS, using `@hono/node-server`).

## Setup

- **MoonBit**: latest nightly (2026-03-18)
- **moonbitlang/async**: 0.16.6 (mooncakes release)
- **Platform**: macOS Darwin 25.2.0, Apple Silicon (arm64)
- **Benchmark**: k6 v1.5.0, 10 VUs, 10s duration
- **Workload**: 3 JSON API endpoints (`/api/health`, `/api/items`, `/api/echo/:msg`)

Both servers use identical MoonBit handler code — only the transport layer differs:
- **Native**: `mars` → `mizchi/x/http` → `moonbitlang/async/http` → kqueue
- **JS**: `mars` → `@hono/node-server` → Node.js HTTP (libuv)

### Server code (identical for both)

```moonbit
app.get("/api/health", @mars.handler(async fn(c) {
  let json : Json = { "status": "ok".to_json() }
  c.json(json)
}))

app.get("/api/items", @mars.handler(async fn(c) {
  let json : Json = { "items": items_json, "total": (3).to_json() }
  c.json(json)
}))

app.get("/api/echo/:msg", @mars.handler(async fn(c) {
  let msg = c.param("msg").unwrap_or("hello")
  let json : Json = { "echo": msg.to_json() }
  c.json(json)
}))
```

## Benchmark Results

| Metric | Native | JS (Node.js) | Ratio |
|--------|--------|-------------|-------|
| **Requests/sec** | 12,376 | 16,820 | 73.6% |
| **Avg latency** | 768µs | 556µs | 1.38x slower |
| **Median latency** | 711µs | 443µs | |
| **p95 latency** | 1.0ms | 1.1ms | ~equal |
| **Keep-alive single req** | 175µs | — | |

Native achieves ~74% of Node.js throughput for simple JSON API responses.

## Profile Analysis

Profiled with macOS `sample` command during k6 load (5 VUs, 2s sample).

### CPU Time Breakdown

| Category | Samples | Est. % | Key Functions |
|----------|---------|--------|---------------|
| **Reference Counting** | 475 | **~15%** | `moonbit_decref_inlined` (206), `moonbit_incref_inlined` (138), `moonbit_drop_object` (71), `malloc_inlined` (59), `free` (62) |
| **String/Buffer Ops** | ~400 | **~13%** | `Buffer::write_string_utf8` (90), `encoding::utf8::encode` (85), `StringBuilder::write_char` (78), `Json::stringify` (72) |
| **HTTP Send** | ~350 | **~11%** | `Sender::write` (101+50), `Sender::send_headers` (56), `Sender::send_response` (51) |
| **Hash/Map** | ~200 | **~6%** | `Hasher::combine_string` (49), `Hash::hash` (43), `String::hash_combine` (31) |
| **String::to_lower** | 33 | **~1%** | Header key normalization |

### Finding 1: RC Overhead is Dominant (~15%)

The largest single cost is reference counting for short-lived HTTP objects. Every request creates and destroys multiple `Map`, `String`, `Bytes`, and `Array` objects for headers, JSON serialization, and response buffering.

`moonbit_incref_inlined` + `moonbit_decref_inlined` + `moonbit_drop_object` alone account for ~15% of all CPU samples. Combined with `malloc`/`free` from object allocation, memory management is the #1 bottleneck.

**Potential improvement**: RC elision via escape analysis. Most HTTP request-scoped objects don't escape the handler function — they could be stack-allocated or use arena allocation.

### Finding 2: Triple-Copy JSON Response Path (~13%)

The response path for `Context::json(data)` is:

```
Json value
  → Json.stringify() → String (allocation #1)
  → @encoding.encode(UTF8, string) → Bytes (allocation #2)
  → Sender::write(bytes) → send_buf copy (copy #3)
  → socket write
```

Each step allocates and copies. A direct `Json → Bytes` serializer that writes to the send buffer would eliminate 2 of these 3 allocations.

### Finding 3: Many Small Header Writes (~11%)

`Sender::send_headers` writes each header as 4 separate writes:

```moonbit
self..write(k)..write(": ")..write(v).write("\r\n")  // 4 writes per header
```

Each `write` call goes through the `Sender::write_once` method which checks buffer capacity and potentially flushes. For a typical response with 2-3 headers, this is 8-12 write calls instead of 1.

**Potential improvement**: Build the entire header block in a `StringBuilder`, then write once.

### Finding 4: HashMap Overhead for Small Collections (~6%)

Response headers use `Map[String, String]` (HashMap). For typical API responses with 2-3 headers, the hash computation (`Hasher::combine_string`, `String::hash_combine`) is more expensive than a linear scan of an array would be.

This also applies to `merge_headers` in mars, which creates a new Map on every response.

### What I Tested (No Improvement)

1. **send_buf size 1024 → 8192**: No measurable change. Buffer wasn't the bottleneck.
2. **Content-Length mode (skip chunked encoding)**: Added `SendingFixedBody` mode to `Sender` — no improvement. Chunked encoding overhead is negligible compared to RC and string ops.
3. **`String::to_lower` → custom ASCII lowercase**: Only 1% of profile, negligible.

## Suggestions for moonbitlang/async

### Short-term (HTTP layer)

1. **Batch header writes in `send_headers`**: Build headers into a single `Bytes` buffer, write once. Estimated ~5% improvement.

2. **Direct `Json → Bytes` write path**: Add a `Sender::write_json(data: Json)` that serializes directly to `send_buf` without intermediate `String`. Estimated ~5-10% improvement.

### Medium-term (Runtime)

3. **RC elision for request-scoped objects**: Most objects in HTTP handler path (header Map, JSON strings, response bytes) are created and consumed within a single async function. Escape analysis could eliminate incref/decref for these.

4. **Arena allocator for request scope**: An arena that bulk-frees all request-scoped allocations when the handler returns would eliminate per-object free() calls.

### The Big Picture

The current native HTTP stack is functional and correct. The 74% throughput ratio vs Node.js is respectable for a young runtime. The profile shows the bottleneck is **not** in the I/O layer (kqueue/epoll) or event loop — it's in **memory management and string operations** in the application layer above.

The most impactful improvement would be **RC optimization in the MoonBit compiler**, which would benefit all MoonBit programs, not just HTTP servers.

## Reproduction

```bash
# Clone and build
git clone https://github.com/mizchi/sol.mbt
cd sol.mbt
moon build --target native src/bench_native_api --release
moon build --target js src/bench_js_api --release

# Run native server (port 7800)
_build/native/release/build/bench_native_api/bench_native_api.exe &

# Run JS server (port 7801)
node _build/js/release/build/bench_js_api/bench_js_api.js &

# Benchmark
k6 run --env BASE_URL=http://localhost:7800 bench/k6_api.js
k6 run --env BASE_URL=http://localhost:7801 bench/k6_api.js

# Profile (macOS)
sample <native_pid> 2 -file /tmp/profile.txt
```
