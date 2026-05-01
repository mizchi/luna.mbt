# Sol SQLite ISR Demo

Demonstrates ISR (Incremental Static Regeneration) with SQLite database using Node.js 22's built-in `node:sqlite` module.

## Requirements

- Node.js 22.5.0 or later (for `node:sqlite` support)

## Setup

```bash
# Install dependencies
npm install

# Initialize SQLite database
npm run init-db

# Start development server
npm run dev
```

Open http://localhost:3000 to view the demo.

## ISR Demo Pages

| Page | TTL | Description |
|------|-----|-------------|
| `/` | None | Home page (static) |
| `/blog` | 60s | Blog index (warm tier) |
| `/blog/:slug` | 120s | Individual posts (warm tier) |
| `/stats` | 10s | Statistics (near real-time) |

Note: Sol uses `:slug` (Express/Hono style) for dynamic route parameters.

## How ISR Works

1. **First Request**: Page is rendered from SQLite data and cached
2. **Within TTL**: Cached page served instantly (no DB query)
3. **After TTL**: Stale page served + background regeneration triggered
4. **Next Request**: Fresh page with updated database data

## Project Structure

```
app/
├── server/
│   ├── routes.mbt   # Route definitions with ISR revalidate options
│   ├── db.mbt       # SQLite database bindings (node:sqlite FFI)
│   └── _using.mbt   # Element imports
├── client/
│   └── lib.mbt      # Client islands (empty for this demo)
└── __gen__/         # Generated files
scripts/
└── init-db.js       # Database initialization script
```

## Database Schema

```sql
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  author TEXT NOT NULL,
  views INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```
