// Router registration from route trees

///|
/// Register routes from Routes definition to Hono app
/// Uses a resolver function to map component IDs to render functions
pub fn[E] register_routes(
  app : App,
  routes : Array[@routes.Routes],
  page_resolver : (String, Ctx, RouteParams) -> @luna.Node[E, String]?,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  config? : RouterConfig,
  title_prefix? : String = "",
  default_title? : String = "App",
  default_head? : String = "",
  loader_url? : String = "/__sol__/loader.js",
  wc_loader_url? : String = "/__sol__/wc-loader.js",
) -> Unit {
  ensure_mars_to_handler_compat()
  let resolved = resolve_router_config(
    config,
    title_prefix~,
    default_title~,
    default_head~,
    loader_url~,
    wc_loader_url~,
  )

  // Loader URLs are currently reserved for client-loader integration.
  let _ = (resolved.loader_url, resolved.wc_loader_url)
  let register_page = fn(
    full_path : String,
    component : String,
    title : String,
  ) {
    let param_names = extract_route_param_names(full_path)
    app.get(full_path, async fn(c) {
      let is_fragment = has_fragment_header(c)
      let params = extract_route_params(c, is_fragment~, param_names~)
      match page_resolver(component, c, params) {
        Some(node) => {
          let page_title = format_title(
            title,
            title_prefix=resolved.title_prefix,
            default_title=resolved.default_title,
          )
          if is_fragment {
            let fragment_html = render_fragment_response(
              node, page_title, false,
            )
            send_fragment_response(c, fragment_html)
          } else {
            let html = render_page_html(
              node,
              page_title,
              resolved.default_head,
              false,
              resolved.root_template,
              enable_preload=resolved.enable_preload,
              preload_libs=resolved.preload_libs,
              chunk_manifest=resolved.chunk_manifest,
            )
            c.html(html)
          }
        }
        None => c.text("Page not found: " + component, status=404)
      }
    })
  }
  let register_get = fn(full_path : String, handler : String) {
    register_api_get_route(app, full_path, handler, api_resolver)
  }
  let register_post = fn(full_path : String, handler : String) {
    register_api_post_route(app, full_path, handler, api_resolver)
  }
  register_route_tree(routes, "", register_page, register_get, register_post)
}

///|
fn register_route_tree(
  routes : Array[@routes.Routes],
  prefix : String,
  register_page : (String, String, String) -> Unit,
  register_get : (String, String) -> Unit,
  register_post : (String, String) -> Unit,
) -> Unit {
  for route in routes {
    match route {
      @routes.Page(path~, component~, title~, meta~) => {
        let _ = meta
        let full_path = prefix + path
        register_page(full_path, component, title)
      }
      @routes.Layout(segment~, children~, layout~) => {
        // `@routes.Layout` is treated as path grouping in this adapter.
        // Actual layout composition is handled by `sol_routes` (ServerNode).
        let _ = layout
        register_route_tree(
          children,
          prefix + segment,
          register_page,
          register_get,
          register_post,
        )
      }
      @routes.Get(path~, handler~) => register_get(prefix + path, handler)
      @routes.Post(path~, handler~) => register_post(prefix + path, handler)
    }
  }
}

///|
fn register_api_get_route(
  app : App,
  full_path : String,
  handler : String,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
) -> Unit {
  let param_names = extract_route_param_names(full_path)
  app.get(full_path, async fn(c) {
    let params = extract_route_params(c, is_fragment=false, param_names~)
    match api_resolver(handler, c, params) {
      Some(json) => @mars_response.send_json_any(c, json)
      None => @mars_response.send_json_error(c, "Handler not found", status=404)
    }
  })
}

///|
fn register_api_post_route(
  app : App,
  full_path : String,
  handler : String,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
) -> Unit {
  let param_names = extract_route_param_names(full_path)
  app.post(full_path, async fn(c) {
    let params = extract_route_params(c, is_fragment=false, param_names~)
    match api_resolver(handler, c, params) {
      Some(json) => @mars_response.send_json_any(c, json)
      None => @mars_response.send_json_error(c, "Handler not found", status=404)
    }
  })
}

///|
/// Async page resolver type - returns ServerNode for async server components
pub type AsyncPageResolver = (String, Ctx, RouteParams) -> @server_dom.ServerNode?

///|
/// Register routes with async server component support
/// Uses ServerNode which supports both sync and async server components
pub fn register_server_routes(
  app : App,
  routes : Array[@routes.Routes],
  page_resolver : AsyncPageResolver,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
  config? : RouterConfig,
  title_prefix? : String = "",
  default_title? : String = "App",
  default_head? : String = "",
  loader_url? : String = "/__sol__/loader.js",
  wc_loader_url? : String = "/__sol__/wc-loader.js",
) -> Unit {
  ensure_mars_to_handler_compat()
  let resolved = resolve_router_config(
    config,
    title_prefix~,
    default_title~,
    default_head~,
    loader_url~,
    wc_loader_url~,
  )
  let converted = legacy_routes_to_sol_routes(
    routes, page_resolver, api_resolver,
  )
  // Loader URLs are currently reserved for client-loader integration.
  let _ = (resolved.loader_url, resolved.wc_loader_url)
  register_sol_routes(app, converted, config=resolved)
}

///|
fn identity_layout(
  _props : PageProps,
  children : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise Error {
  children
}

///|
fn page_not_found_node() -> @server_dom.ServerNode {
  @server_dom.ServerNode::sync(@luna.text(""))
}

///|
fn legacy_page_handler_from_resolver(
  component : String,
  page_resolver : AsyncPageResolver,
) -> async (PageProps) -> @server_dom.ServerNode {
  async fn(props : PageProps) {
    match page_resolver(component, props.ctx, props.params) {
      Some(server_node) => server_node
      None => {
        props.ctx.text("Page not found: " + component, status=404)
        page_not_found_node()
      }
    }
  }
}

///|
fn legacy_api_handler_from_resolver(
  handler : String,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
) -> async (PageProps) -> Json {
  async fn(props : PageProps) {
    match api_resolver(handler, props.ctx, props.params) {
      Some(json) => {
        // Convert legacy @js.Any to Json string and back
        let str = ffi_json_stringify_any(json)
        @json.parse(str) catch { _ => ().to_json() }
      }
      None => {
        @mars_response.send_json_error(
          props.ctx,
          "Handler not found",
          status=404,
        )
        ().to_json()
      }
    }
  }
}

///|
fn legacy_routes_to_sol_routes(
  routes : Array[@routes.Routes],
  page_resolver : AsyncPageResolver,
  api_resolver : (String, Ctx, RouteParams) -> @js.Any?,
) -> Array[SolRoutes] {
  let converted : Array[SolRoutes] = []
  for route in routes {
    match route {
      @routes.Page(path~, component~, title~, meta~) =>
        converted.push(
          SolRoutes::Page(
            path~,
            handler=PageHandler(
              legacy_page_handler_from_resolver(component, page_resolver),
            ),
            title~,
            meta~,
            revalidate=None,
            cache=None,
          ),
        )
      @routes.Layout(segment~, children~, layout~) => {
        let _ = layout
        converted.push(
          SolRoutes::Layout(
            segment~,
            layout=identity_layout,
            children=legacy_routes_to_sol_routes(
              children, page_resolver, api_resolver,
            ),
          ),
        )
      }
      @routes.Get(path~, handler~) =>
        converted.push(
          SolRoutes::Get(
            path~,
            handler=ApiHandler(
              legacy_api_handler_from_resolver(handler, api_resolver),
            ),
          ),
        )
      @routes.Post(path~, handler~) =>
        converted.push(
          SolRoutes::Post(
            path~,
            handler=ApiHandler(
              legacy_api_handler_from_resolver(handler, api_resolver),
            ),
          ),
        )
    }
  }
  converted
}

///|
extern "js" fn ffi_json_stringify_any(data : @js.Any) -> String =
  #| (data) => JSON.stringify(data)
