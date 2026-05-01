// Astra: Mars middleware for static site generation.
//
// The public surface lives in submodules:
//   * `mizchi/astra/middleware` — `create`, `Middleware`, `handler`,
//     `list_urls` (the mountable middleware value)
//   * `mizchi/astra/tree` — document-tree builder
//   * `mizchi/astra/render` — page generators (used by the build pipeline)
//
// This file holds shared SSG types (SsgConfig, DocumentTree, PageMeta, ...)
// in the sibling `*.mbt` files. No top-level re-exports today: type aliases
// across the astra ↔ astra/middleware boundary would form an import cycle
// because the middleware package already depends on `mizchi/astra` for the
// shared types.
