# sol_api - Pure REST API Example

An example of a Pure REST API server built with MoonBit + Sol.

## Features

- **No HTML**: Pure JSON API server
- **REST Pattern**: Read operations for Items resource
- **Middleware**: CORS, Logger, Security Headers
- **Error Handling**: Structured error responses

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/items` | List items |
| GET | `/api/items/:id` | Get single item |
| GET | `/api/stats` | Statistics |
| GET | `/api/error?type=xxx` | Error response test |

## Usage

```bash
# Build
just all

# Start server
just serve

# API test (in a separate terminal)
just test-api
just test-errors
```

## Response Examples

```bash
# Health check
curl http://localhost:7777/api/health
# => {"status":"ok","timestamp":"2024-01-29T12:00:00.000Z"}

# List items
curl http://localhost:7777/api/items
# => {"items":[{"id":1,"name":"Item 1",...}],"total":3}

# Get single item
curl http://localhost:7777/api/items/1
# => {"id":1,"name":"Item 1","description":"First item","created_at":"..."}

# Item not found
curl http://localhost:7777/api/items/99
# => {"error":"not_found","message":"Item not found"}

# Error response
curl "http://localhost:7777/api/error?type=not_found"
# => {"error":"not_found","message":"Resource not found"}
```

## Middleware Stack

1. **CORS**: Allows all origins, supports major HTTP methods
2. **Logger**: Request log output
3. **Security Headers**: X-Content-Type-Options, X-Frame-Options

## vs Other Examples

| Example | Features |
|---------|----------|
| sol_app | Full-stack (Islands, WC, Server Actions) |
| sol_auth | Authentication & Authorization (Better Auth) |
| sol_blog | SSG Blog |
| sol_docs | Documentation Site (SPA) |
| sol_sqlite | ISR + SQLite |
| **sol_api** | **Pure REST API (this example)** |
