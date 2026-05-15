///| Re-export router and action APIs for convenience.

///|
/// Users can use @sol.route(), @sol.nodes(), @sol.ok() etc. directly.

// Route definition helpers
pub using @router {
  api_get,
  api_post,
  api_put,
  api_delete,
  api_patch,
  raw_get,
  raw_post,
  raw_put,
  raw_delete,
  raw_patch,
  route_ownership_manifest,
  wrap,
  with_mw,
  assets,
  nodes,
  server_nodes,
  with_style,
  with_script,
  with_assets,
}

///|
pub fn route(
  path : String,
  handler : async (@router.PageProps) -> @server_dom.ServerNode,
  title? : String = "",
  meta? : Array[(String, String)] = [],
  revalidate? : Int? = None,
  cache? : @router.CacheStrategy? = None,
  styles? : Array[String] = [],
  scripts? : Array[String] = [],
) -> @router.SolRoutes {
  @router.page(
    path,
    handler,
    title~,
    meta~,
    revalidate~,
    cache~,
    styles~,
    scripts~,
  )
}

// API response helpers

///|
pub using @router {
  ok,
  error_response,
  bad_request,
  unauthorized,
  forbidden,
  not_found_response,
  redirect_to,
  redirect_permanent_to,
}

// Parameter extraction helpers

///|
pub using @router {
  require,
  require_int,
  require_query,
  optional,
  optional_query,
}

// Types

///|
pub using @router {
  type SolRoutes,
  type PageProps,
  type RouterConfig,
  type PageHandler,
  type ApiHandler,
  type RawHandler,
  type ApiResponse,
  type CacheStrategy,
  type RouteOwnershipManifest,
  type RouteManifestEntry,
  type RouteManifestMethod,
  type RouteManifestOwner,
  type RouteManifestMatchKind,
}

// Action types

///|
pub using @action {type ActionRegistry}
