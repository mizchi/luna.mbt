# Routing Specification

This document serves as the single source of truth for the `sol` routing specification.

## 1. API Selection

`sol` has two registration API families with different purposes.

| API | Input | Primary Purpose | Layout Handling |
|---|---|---|---|
| `@router.register_routes` / `@router.register_server_routes` | `@luna/core/routes.Routes` | Lightweight assignment for file-based routing | Path prefix grouping only (no layout composition) |
| `@router.register_sol_routes` | `@router.SolRoutes` | Handles `ServerNode` SSR with layout composition | Applies `SolRoutes::Layout` |

`SolRoutes` supports three response families:

- `page(...)` / `SolRoutes::Page` for HTML, fragments, layouts, and ISR.
- `api_get(...)`, `api_post(...)`, `api_put(...)`, `api_delete(...)`,
  and `api_patch(...)` for JSON API responses.
- `raw_get(...)`, `raw_post(...)`, `raw_put(...)`, `raw_delete(...)`,
  and `raw_patch(...)` for a raw Web `Response`.

## 2. Layout Semantics

- `register_routes` / `register_server_routes`
  - The `layout` in `Layout(segment, children, layout)` is not applied
  - Only URL prefix assignment by `segment` is performed
- `register_sol_routes`
  - Layout functions from `SolRoutes::Layout` are applied from inner to outer

## 3. Route Ownership Manifest

When Sol is embedded in a host Worker, the host entrypoint can consume a
structured ownership manifest instead of duplicating string prefixes.

```moonbit
let manifest = @router.route_ownership_manifest([
  @router.page("/", home),
  @router.api_post("/api/items", create_item),
  @router.raw_get("/media/:id", serve_media),
])
```

The manifest contains Sol page routes, Sol JSON API routes, raw `Response`
routes, local static assets, and reserved Sol paths. Matching supports exact
paths, prefix paths, and parameterized paths such as `/posts/:id`,
`/docs/[id]`, `/docs/[...slug]`, and `/docs/[[...slug]]`.

Reserved entries include `/_sol/*`, `/__sol__/*`, `/_luna/*`, and
`/static/*`. A host Worker should treat these as Sol-owned unless it is
intentionally replacing that framework surface.

## 4. Raw `Response` Routes

Raw routes are the official escape hatch for non-HTML and non-JSON responses.
The handler receives normal `PageProps`, so route params and middleware still
apply. Middleware response headers are merged into the returned Web `Response`
without overwriting headers that the raw response already set.

```moonbit
async fn serve_media(props : @router.PageProps) -> @web_http.Response {
  let id = props.get_param("id").unwrap_or("missing")
  @web_http.Response::new(
    body="media:" + id,
    status=206,
    headers=@sol.json_obj([("Content-Range", @js.any("bytes 0-3/4"))]),
  )
}

@router.raw_get("/media/:id", serve_media)
```

Use raw routes for binary objects, `Range` / `206 Partial Content`, redirects
with custom headers, Server-Sent Events, streaming bodies, and pass-through
responses from service bindings or upstream services. Cloudflare-specific
objects should stay in the host Worker or a platform adapter; the core Sol
contract is only the Web `Response`.

## 5. 404/500 Ownership

Error handling follows the layer that owns the route:

- Sol page routes own HTML responses, layout composition, fragment responses,
  and page/layout `500` handling.
- Sol API routes own JSON responses and JSON `404` / `500` handling for
  Sol-declared API handlers.
- Raw routes own the exact returned `Response`; if the raw handler raises,
  Sol returns a plain text `500`. Middleware headers are added only when the
  raw `Response` has not already set the same header.
- Host Worker routes own platform-specific fallback responses, auth callbacks,
  media endpoints, service binding proxies, and any path that the manifest
  does not match.

In mixed Worker apps, check the host routes first when the host intentionally
owns a path, then delegate Sol-owned paths to the Sol handler, and finally
return the host fallback `404`. Route groups and layouts define composition
boundaries for Sol pages, but they are not general-purpose error boundary
components.

## 6. Dynamic `source_path` Query Format

When retaining dynamic parameters in the SSG internal representation `source_path`, the format is as follows:

- Format: `path/to/template.md?key=value&key2=value2...`
- Values are URL-encoded before embedding
- The primary parameter corresponding to the dynamic segment is always included
- If `staticParams` has additional keys, they are appended as query parameters

Examples:

- `docs/_...slug_/index.md?slug=guide%2Fintro&lang=ja`
- `posts/_id_.md?id=a%2Bb%3Dc%26d&preview=true`

During restoration (`page_generator`), the query is URL-decoded and restored to a `Map[String, String]`.

## 7. Scope

- This `source_path` convention is an internal representation for SSG
- This convention is not required for runtime routing (`Context::param`)
