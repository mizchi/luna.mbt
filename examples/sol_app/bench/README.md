# Sol App Benchmarks

Benchmark scripts using k6.

## Setup

```bash
# Install k6 (macOS)
brew install k6
```

## Usage

Run with the server already started:

```bash
# Terminal 1: Start the server
npm run dev
# or
npm run serve  # after production build

# Terminal 2: Run benchmarks
npm run bench          # Full benchmark (smoke + load + stress)
npm run bench:quick    # Quick test (10 seconds)
npm run bench:static   # Static routes only
npm run bench:dynamic  # Dynamic routes only
npm run bench:api      # API endpoints only
```

## Benchmark Scripts

| Script | Target Routes | VUs | Duration |
|--------|--------------|-----|----------|
| `static-routes.js` | `/`, `/about`, `/form`, `/admin` | 10 | 30s |
| `dynamic-routes.js` | `/docs/[...slug]`, `/blog/[[...path]]` | 10 | 30s |
| `api-routes.js` | `/api/health`, `/api/middleware-test` | 10 | 30s |
| `all.js` | All routes | 5→50 | smoke + load + stress |

## Custom Execution

```bash
# Specify VUs and duration
k6 run --vus 20 --duration 60s bench/static-routes.js

# Specify a different host
k6 run -e BASE_URL=http://localhost:8080 bench/all.js

# JSON output
k6 run --out json=results.json bench/all.js
```

## Results

Benchmark results are saved in JSON format under `bench/results/`.
