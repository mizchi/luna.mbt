// Sol Routes - Mars registration and request handling
//
// Registers compiled SolRoutes to the Hono/Mars app and handles requests.

// ============================================================================
// Route Registration to Hono
// ============================================================================

///|
fn ensure_mars_to_handler_compat() -> Unit {
  ffi_ensure_mars_to_handler_reschedule_symbol()
}

///|
/// Register Sol routes to Hono app
pub fn register_sol_routes(
  app : App,
  routes : Array[SolRoutes],
  config? : RouterConfig,
) -> Unit {
  ensure_mars_to_handler_compat()
  let compiled = compile_sol_routes(routes)
  let cfg = config.unwrap_or(RouterConfig::default())
  register_compiled_sol_routes(app, compiled, cfg)
}

///|
fn is_isr_with_cache(config : RouterConfig, route_revalidate : Int?) -> Bool {
  match (route_revalidate, config.isr_cache) {
    (Some(_), Some(_)) => true
    _ => false
  }
}

///|
fn should_use_streaming(
  config : RouterConfig,
  is_fragment : Bool,
  route_revalidate : Int?,
) -> Bool {
  config.enable_streaming &&
  !is_fragment &&
  !is_isr_with_cache(config, route_revalidate)
}

///|
fn cache_strategy_to_header_value(strategy : CacheStrategy) -> String {
  match strategy {
    CacheStrategy::AlwaysFetch => "always-fetch"
    CacheStrategy::StaleWhileRevalidate => "stale-while-revalidate"
  }
}

///|
/// Apply CDN cache headers based on CDNCacheStrategy configuration.
/// Sets Cache-Control and X-Sol-CDN-Cache headers for ISR pages.
fn apply_cdn_cache_headers(
  c : @mars.Context,
  strategy : @isr.CDNCacheStrategy?,
  revalidate : Int,
) -> Unit {
  match strategy {
    Some(s) => {
      c.set_header("Cache-Control", s.cache_control(revalidate))
      c.set_header("X-Sol-CDN-Cache", s.header_value())
    }
    None => ()
  }
}

///|
fn apply_layouts_with_assets(
  content : @server_dom.ServerNode,
  props : PageProps,
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  is_fragment : Bool,
) -> (@server_dom.ServerNode, @server_dom.ServerAssets) raise Error {
  // Apply layouts from innermost to outermost
  // For fragments: skip root layout (index 0), apply nested layouts
  // For full pages: apply all layouts
  let mut node = content
  let mut assets = content.declared_assets()
  let end_idx = if is_fragment { 1 } else { 0 }
  let mut i = layouts.length() - 1
  while i >= end_idx {
    let layout_fn = layouts[i]
    node = layout_fn(props, node)
    assets = node.declared_assets().merge(assets)
    i -= 1
  }
  (node, assets)
}

///|
/// Render page and return HTML (helper for ISR)
async fn render_page_to_html(
  c : Ctx,
  props : PageProps,
  handler : async (PageProps) -> @server_dom.ServerNode,
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  is_fragment : Bool,
  title : String,
  page_head : String,
  asset_styles : Array[String],
  asset_scripts : Array[String],
  root_template : String,
  cache_strategy : CacheStrategy,
) -> String raise Error {
  // Call handler and apply layouts
  let content : @server_dom.ServerNode = handler(props)
  if c.is_response_sent() {
    fail("ISR render attempted to send a direct response")
  }
  let (node, assets) = apply_layouts_with_assets(
    content, props, layouts, is_fragment,
  )
  if c.is_response_sent() {
    fail("ISR render attempted to mutate the response")
  }
  if is_fragment {
    let head_assets = render_asset_tags(
      merge_asset_paths(asset_styles, assets.styles),
      merge_asset_paths(asset_scripts, assets.scripts),
    )
    render_server_fragment(node, title, cache_strategy, head_assets)
  } else {
    let head = build_page_head(page_head, asset_styles, asset_scripts, assets)
    render_server_page_html(node, title, head, root_template)
  }
}

///|
async fn send_non_isr_page_response(
  c : Ctx,
  props : PageProps,
  handler : async (PageProps) -> @server_dom.ServerNode,
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  is_fragment : Bool,
  page_title : String,
  page_head : String,
  asset_styles : Array[String],
  asset_scripts : Array[String],
  root_template : String,
  cache_strategy : CacheStrategy,
  route_revalidate : Int?,
  config : RouterConfig,
) -> Unit {
  let content : @server_dom.ServerNode = handler(props) catch {
    e => {
      log_server_error("Page handler error", e)
      return c.text("Internal Server Error", status=500)
    }
  }
  if c.is_response_sent() {
    return
  }
  let (node, assets) = apply_layouts_with_assets(
    content, props, layouts, is_fragment,
  ) catch {
    e => {
      log_server_error("Layout error", e)
      return c.text("Internal Server Error", status=500)
    }
  }
  if is_fragment {
    let head_assets = render_asset_tags(
      merge_asset_paths(asset_styles, assets.styles),
      merge_asset_paths(asset_scripts, assets.scripts),
    )
    let fragment_html = render_server_fragment(
      node, page_title, cache_strategy, head_assets,
    )
    send_fragment_response(c, fragment_html)
  } else if should_use_streaming(config, is_fragment, route_revalidate) {
    let head = build_page_head(page_head, asset_styles, asset_scripts, assets)
    send_streaming_server_page(
      c,
      node,
      page_title,
      head,
      config.loader_url,
      root_template,
    )
  } else {
    let head = build_page_head(page_head, asset_styles, asset_scripts, assets)
    let html = render_server_page_html(node, page_title, head, root_template)
    c.html(html)
  }
}

///|
async fn handle_compiled_api_route(
  c : Ctx,
  route : CompiledSolRoute,
  middleware_chain : @middleware.Middleware,
) -> Unit {
  // Run middleware chain first
  let halted = @middleware.run_or_500(middleware_chain, c)
  if halted {
    return
  }
  let params = extract_route_params(
    c,
    is_fragment=false,
    param_names=route.param_names,
  )

  let props = PageProps::from_ctx_with_params(c, params)
  match route.api_handler {
    Some(ApiHandler(handler)) => {
      let json : Json = handler(props) catch {
        e => {
          log_server_error("API handler error", e)
          @mars_response.send_internal_error(c)
          return
        }
      }
      if c.is_response_sent() {
        return
      }
      @mars_response.send_json(c, json)
    }
    None => @mars_response.send_json_error(c, "No handler", status=404)
  }
}

///|
async fn handle_compiled_raw_route(
  c : Ctx,
  route : CompiledSolRoute,
  middleware_chain : @middleware.Middleware,
) -> Unit {
  // Run middleware chain first
  let halted = @middleware.run_or_500(middleware_chain, c)
  if halted {
    return
  }
  let params = extract_route_params(
    c,
    is_fragment=false,
    param_names=route.param_names,
  )

  let props = PageProps::from_ctx_with_params(c, params)
  match route.raw_handler {
    Some(RawHandler(handler)) => {
      let response = handler(props) catch {
        e => {
          log_server_error("Raw handler error", e)
          return c.text("Internal Server Error", status=500)
        }
      }
      if c.is_response_sent() {
        return
      }
      ffi_send_web_response(c, response)
    }
    None => c.text("No handler", status=404)
  }
}

///|
fn is_api_route_kind(kind : SolRouteKind) -> Bool {
  match kind {
    SolRouteKind::GetApi => true
    SolRouteKind::PostApi => true
    SolRouteKind::PutApi => true
    SolRouteKind::DeleteApi => true
    SolRouteKind::PatchApi => true
    SolRouteKind::Page => false
    SolRouteKind::RawGet => false
    SolRouteKind::RawPost => false
    SolRouteKind::RawPut => false
    SolRouteKind::RawDelete => false
    SolRouteKind::RawPatch => false
  }
}

///|
fn is_raw_route_kind(kind : SolRouteKind) -> Bool {
  match kind {
    SolRouteKind::RawGet => true
    SolRouteKind::RawPost => true
    SolRouteKind::RawPut => true
    SolRouteKind::RawDelete => true
    SolRouteKind::RawPatch => true
    SolRouteKind::Page => false
    SolRouteKind::GetApi => false
    SolRouteKind::PostApi => false
    SolRouteKind::PutApi => false
    SolRouteKind::DeleteApi => false
    SolRouteKind::PatchApi => false
  }
}

///|
fn register_compiled_api_route(
  app : App,
  kind : SolRouteKind,
  hono_pattern : String,
  route : CompiledSolRoute,
  middleware_chain : @middleware.Middleware,
) -> Unit {
  let handler = async fn(c) {
    handle_compiled_api_route(c, route, middleware_chain)
  }
  match kind {
    SolRouteKind::GetApi => app.get(hono_pattern, handler)
    SolRouteKind::PostApi => app.post(hono_pattern, handler)
    SolRouteKind::PutApi => app.put(hono_pattern, handler)
    SolRouteKind::DeleteApi => app.delete(hono_pattern, handler)
    SolRouteKind::PatchApi => app.patch(hono_pattern, handler)
    SolRouteKind::Page => ()
    SolRouteKind::RawGet => ()
    SolRouteKind::RawPost => ()
    SolRouteKind::RawPut => ()
    SolRouteKind::RawDelete => ()
    SolRouteKind::RawPatch => ()
  }
}

///|
fn register_compiled_raw_route(
  app : App,
  kind : SolRouteKind,
  hono_pattern : String,
  route : CompiledSolRoute,
  middleware_chain : @middleware.Middleware,
) -> Unit {
  let handler = async fn(c) {
    handle_compiled_raw_route(c, route, middleware_chain)
  }
  match kind {
    SolRouteKind::RawGet => app.get(hono_pattern, handler)
    SolRouteKind::RawPost => app.post(hono_pattern, handler)
    SolRouteKind::RawPut => app.put(hono_pattern, handler)
    SolRouteKind::RawDelete => app.delete(hono_pattern, handler)
    SolRouteKind::RawPatch => app.patch(hono_pattern, handler)
    SolRouteKind::Page => ()
    SolRouteKind::GetApi => ()
    SolRouteKind::PostApi => ()
    SolRouteKind::PutApi => ()
    SolRouteKind::DeleteApi => ()
    SolRouteKind::PatchApi => ()
  }
}

///|
/// Handle an ISR-enabled page request. Called when revalidate and isr_cache
/// are both present and the request is not a fragment.
async fn handle_isr_page_request(
  c : Ctx,
  props : PageProps,
  handler : async (PageProps) -> @server_dom.ServerNode,
  layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  page_title : String,
  page_head : String,
  asset_styles : Array[String],
  asset_scripts : Array[String],
  root_template : String,
  cache_strategy : CacheStrategy,
  route_revalidate : Int?,
  revalidate : Int,
  cache : @isr.MemoryCache,
  config : RouterConfig,
) -> Unit {
  if !props.params.query.is_empty() {
    c.set_header("Cache-Control", "private, no-store")
    c.set_header("X-Sol-ISR-Status", "BYPASS")
    return send_non_isr_page_response(
      c, props, handler, layouts, false, page_title, page_head, asset_styles, asset_scripts,
      root_template, cache_strategy, route_revalidate, config,
    )
  }
  // Apply CDN cache headers if strategy is configured
  apply_cdn_cache_headers(c, config.cache_strategy, revalidate)
  // ISR enabled - check cache
  let cache_key = @isr.cache_key(props.params.path, props.params.query)
  let entry = @isr.ISRCache::get(cache, cache_key)
  let now = @isr.now_ms()
  let status = @isr.check_status(entry, now)
  // Set X-Sol-ISR-Status header for diagnostics
  let isr_status_str = match status {
    @isr.Fresh => "HIT"
    @isr.Stale => "STALE"
    @isr.Miss => "MISS"
  }
  c.set_header("X-Sol-ISR-Status", isr_status_str)
  // ISR render props: mark as ISR to warn against ctx header access
  let isr_props = { ..props, is_isr_render: true }
  match status {
    @isr.Fresh =>
      // Return cached HTML directly
      match entry {
        Some(e) => c.html(e.html)
        None => c.text("Cache error", status=500)
      }
    @isr.Stale =>
      // Return cached HTML and schedule background revalidation
      match entry {
        Some(e) => {
          // Deduplicate in-flight revalidations for same cache key
          if !isr_in_flight.val.contains(cache_key) {
            isr_in_flight.val.add(cache_key)
            @isr.ISRCache::schedule_revalidation(cache, async fn() {
              let html = render_page_to_html(
                c, isr_props, handler, layouts, false, page_title, page_head, asset_styles,
                asset_scripts, root_template, cache_strategy,
              ) catch {
                _ => {
                  isr_in_flight.val.remove(cache_key)
                  return
                }
              }
              let new_entry = @isr.CacheEntry::new(
                html,
                @isr.now_ms(),
                revalidate,
              )
              @isr.ISRCache::put(cache, cache_key, new_entry)
              isr_in_flight.val.remove(cache_key)
            })
          }
          c.html(e.html)
        }
        None => c.text("Cache error", status=500)
      }
    @isr.Miss => {
      // Render, cache, and return
      let html = render_page_to_html(
        c, isr_props, handler, layouts, false, page_title, page_head, asset_styles,
        asset_scripts, root_template, cache_strategy,
      ) catch {
        e => {
          log_server_error("ISR revalidation error", e)
          return c.text("Internal Server Error", status=500)
        }
      }
      let new_entry = @isr.CacheEntry::new(html, now, revalidate)
      @isr.ISRCache::put(cache, cache_key, new_entry)
      c.html(html)
    }
  }
}

///|
fn register_compiled_sol_routes(
  app : App,
  routes : Array[CompiledSolRoute],
  config : RouterConfig,
) -> Unit {
  // Register server island defer endpoint if registry is configured
  match config.server_islands {
    Some(registry) =>
      if !registry.is_empty() {
        register_defer_endpoint(app, registry)
      }
    None => ()
  }
  for route in routes {
    // Convert catch-all pattern to Hono wildcard pattern
    let hono_pattern = convert_to_hono_pattern(route.pattern, route.catch_all)
    let middleware_chain = @middleware.pipeline(route.middlewares)
    match route.kind {
      SolRouteKind::Page =>
        app.get(hono_pattern, async fn(c) {
          // Run middleware chain first
          let halted = @middleware.run_or_500(middleware_chain, c)
          if halted {
            return
          }
          let is_fragment = has_fragment_header(c)
          let params = extract_route_params(
            c,
            is_fragment~,
            param_names=route.param_names,
          )
          // Add catch-all parameter if present

          let props = PageProps::from_ctx_with_params(c, params)
          let page_title = format_title(
            route.title,
            title_prefix=config.title_prefix,
            default_title=config.default_title,
          )
          let page_head = config.default_head + route.rendered_meta
          let asset_styles = merge_asset_paths(config.styles, route.styles)
          let asset_scripts = merge_asset_paths(
            config.client_scripts,
            route.scripts,
          )
          c.set_header(
            "X-Sol-Cache-Strategy",
            cache_strategy_to_header_value(route.cache_strategy),
          )
          match route.page_handler {
            Some(PageHandler(handler)) =>
              // Check if ISR is enabled for this route (only for full page requests)
              match (route.revalidate, config.isr_cache, is_fragment) {
                (Some(revalidate), Some(cache), false) =>
                  handle_isr_page_request(
                    c,
                    props,
                    handler,
                    route.layouts,
                    page_title,
                    page_head,
                    asset_styles,
                    asset_scripts,
                    config.root_template,
                    route.cache_strategy,
                    route.revalidate,
                    revalidate,
                    cache,
                    config,
                  )
                _ =>
                  send_non_isr_page_response(
                    c,
                    props,
                    handler,
                    route.layouts,
                    is_fragment,
                    page_title,
                    page_head,
                    asset_styles,
                    asset_scripts,
                    config.root_template,
                    route.cache_strategy,
                    route.revalidate,
                    config,
                  )
              }
            None => c.text("No handler for route", status=404)
          }
        })
      kind =>
        if is_api_route_kind(kind) {
          register_compiled_api_route(
            app, kind, hono_pattern, route, middleware_chain,
          )
        } else if is_raw_route_kind(kind) {
          register_compiled_raw_route(
            app, kind, hono_pattern, route, middleware_chain,
          )
        }
    }
  }
}

///|
/// Render ServerNode to fragment HTML (for CSR navigation)
async fn render_server_fragment(
  node : @server_dom.ServerNode,
  title : String,
  cache_strategy : CacheStrategy,
  head_assets : String,
) -> String {
  // Resolve the ServerNode to get the actual Node
  let resolved_node = node.resolve()
  let body_html = @render.render_to_string(resolved_node).html

  // Wrap in templates like fragment.mbt does
  let buf = StringBuilder::new()
  buf.write_string("<template data-sol-outlet=\"main\">")
  buf.write_string(body_html)
  buf.write_string("</template>")
  buf.write_string("<template data-sol-title>")
  buf.write_string(@page_shell.escape_html_text(title))
  buf.write_string("</template>")
  buf.write_string("<template data-sol-cache-strategy>")
  buf.write_string(cache_strategy_to_header_value(cache_strategy))
  buf.write_string("</template>")
  if !head_assets.is_empty() {
    buf.write_string("<template data-sol-head-assets>")
    buf.write_string(head_assets)
    buf.write_string("</template>")
  }
  buf.to_string()
}

///|
/// Render ServerNode to full page HTML
async fn render_server_page_html(
  node : @server_dom.ServerNode,
  title : String,
  head : String,
  template : String,
) -> String {
  // Resolve the ServerNode to get the actual Node
  let resolved_node = node.resolve()
  let body_html = @render.render_to_string(resolved_node).html
  // Add HMR script in dev mode
  let full_head = @hot_reload.with_dev_head_script(head)
  @page_shell.render_template(template, title, full_head, "", body_html)
}
