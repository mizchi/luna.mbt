# Routing Specification

This document serves as the single source of truth for the `sol` routing specification.

## 1. API Selection

`sol` has two registration API families with different purposes.

| API | Input | Primary Purpose | Layout Handling |
|---|---|---|---|
| `@router.register_routes` / `@router.register_server_routes` | `@luna/core/routes.Routes` | Lightweight assignment for file-based routing | Path prefix grouping only (no layout composition) |
| `@router.register_sol_routes` | `@router.SolRoutes` | Handles `ServerNode` SSR with layout composition | Applies `SolRoutes::Layout` |

## 2. Layout Semantics

- `register_routes` / `register_server_routes`
  - The `layout` in `Layout(segment, children, layout)` is not applied
  - Only URL prefix assignment by `segment` is performed
- `register_sol_routes`
  - Layout functions from `SolRoutes::Layout` are applied from inner to outer

## 3. Dynamic `source_path` Query Format

When retaining dynamic parameters in the SSG internal representation `source_path`, the format is as follows:

- Format: `path/to/template.md?key=value&key2=value2...`
- Values are URL-encoded before embedding
- The primary parameter corresponding to the dynamic segment is always included
- If `staticParams` has additional keys, they are appended as query parameters

Examples:

- `docs/_...slug_/index.md?slug=guide%2Fintro&lang=ja`
- `posts/_id_.md?id=a%2Bb%3Dc%26d&preview=true`

During restoration (`page_generator`), the query is URL-decoded and restored to a `Map[String, String]`.

## 4. Scope

- This `source_path` convention is an internal representation for SSG
- This convention is not required for runtime routing (`Context::param`)
