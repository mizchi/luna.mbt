///| Re-export router and action APIs for convenience.

///|
/// Users can use @sol.route(), @sol.nodes(), @sol.ok() etc. directly.

// Route definition helpers
pub using @router {
  page as route,
  api_get,
  api_post,
  api_put,
  api_delete,
  api_patch,
  wrap,
  with_mw,
  assets,
  nodes,
  server_nodes,
  with_style,
  with_script,
  with_assets,
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
  type ApiResponse,
  type CacheStrategy,
}

// Action types

///|
pub using @action {type ActionRegistry}
