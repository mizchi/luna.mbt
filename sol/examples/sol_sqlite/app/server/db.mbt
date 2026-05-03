///| SQLite Database Bindings using node:sqlite (Node.js 22+)

// =============================================================================
// Database FFI - JavaScript bindings for node:sqlite
// =============================================================================

// Note: DatabaseSync is pre-loaded via --import ./scripts/preload-sqlite.js
// and available on globalThis.DatabaseSync

///| Get all blog posts from the database
extern "js" fn db_get_all_posts() -> @core.Any =
  #| () => {
  #|   const db = new globalThis.DatabaseSync('blog.db');
  #|   try {
  #|     const rows = db.prepare('SELECT * FROM posts ORDER BY created_at DESC').all();
  #|     return rows;
  #|   } finally {
  #|     db.close();
  #|   }
  #| }

///| Get a single blog post by slug
extern "js" fn db_get_post_by_slug(slug : String) -> @core.Any =
  #| (slug) => {
  #|   const db = new globalThis.DatabaseSync('blog.db');
  #|   try {
  #|     const row = db.prepare('SELECT * FROM posts WHERE slug = ?').get(slug);
  #|     return row || null;
  #|   } finally {
  #|     db.close();
  #|   }
  #| }

///| Increment view count for a post
extern "js" fn db_increment_views(slug : String) -> Unit =
  #| (slug) => {
  #|   const db = new globalThis.DatabaseSync('blog.db');
  #|   try {
  #|     db.prepare('UPDATE posts SET views = views + 1, updated_at = CURRENT_TIMESTAMP WHERE slug = ?').run(slug);
  #|   } finally {
  #|     db.close();
  #|   }
  #| }

///| Get aggregate statistics
extern "js" fn db_get_stats() -> @core.Any =
  #| () => {
  #|   const db = new globalThis.DatabaseSync('blog.db');
  #|   try {
  #|     const stats = db.prepare(`
  #|       SELECT
  #|         COUNT(*) as total_posts,
  #|         SUM(views) as total_views,
  #|         AVG(views) as avg_views,
  #|         MAX(views) as max_views,
  #|         MIN(views) as min_views
  #|       FROM posts
  #|     `).get();
  #|     return stats;
  #|   } finally {
  #|     db.close();
  #|   }
  #| }

///| Get current timestamp
extern "js" fn get_timestamp() -> String =
  #| () => new Date().toISOString()

// =============================================================================
// Data Access Helpers
// =============================================================================

///| Extract string field from JS object
extern "js" fn get_str(obj : @core.Any, field : String) -> String =
  #| (obj, field) => obj && obj[field] != null ? String(obj[field]) : ""

///| Extract int field from JS object
extern "js" fn get_int(obj : @core.Any, field : String) -> Int =
  #| (obj, field) => obj && obj[field] != null ? Number(obj[field]) : 0

///| Check if JS value is null/undefined
extern "js" fn is_null(obj : @core.Any) -> Bool =
  #| (obj) => obj == null

///| Get array length
extern "js" fn array_len(arr : @core.Any) -> Int =
  #| (arr) => Array.isArray(arr) ? arr.length : 0

///| Get array element
extern "js" fn array_get(arr : @core.Any, idx : Int) -> @core.Any =
  #| (arr, idx) => arr[idx]
