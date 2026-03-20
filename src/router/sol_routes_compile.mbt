// Sol Routes - Compilation logic
//
// Compiles SolRoutes DSL into optimized CompiledSolRoute format.

///|
fn push_api_route(
  result : Array[CompiledSolRoute],
  prefix : String,
  path : String,
  handler : ApiHandler,
  kind : SolRouteKind,
  inherited_middlewares : Array[@middleware.Middleware],
) -> Unit {
  let full_path = normalize_path(prefix + path)
  let param_names = extract_param_names(full_path)
  let catch_all = extract_catch_all(full_path)
  result.push({
    pattern: full_path,
    param_names,
    page_handler: None,
    api_handler: Some(handler),
    layouts: [],
    middlewares: inherited_middlewares.copy(),
    kind,
    title: "",
    meta: [],
    catch_all,
    revalidate: None,
    cache_strategy: CacheStrategy::AlwaysFetch,
    rendered_meta: "",
  })
}

///|
fn render_meta_tags(meta : Array[(String, String)]) -> String {
  if meta.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  for pair in meta {
    let key = @page_shell.escape_html_text(pair.0)
    let value = @page_shell.escape_html_text(pair.1)
    buf.write_string("<meta name=\"")
    buf.write_string(key)
    buf.write_string("\" content=\"")
    buf.write_string(value)
    buf.write_string("\">")
  }
  buf.to_string()
}

///|
/// Compile SolRoutes to optimized format
pub fn compile_sol_routes(
  routes : Array[SolRoutes],
  base? : String = "",
) -> Array[CompiledSolRoute] {
  let result : Array[CompiledSolRoute] = []
  compile_sol_routes_inner(routes, base, [], [], result)
  result
}

///|
fn compile_sol_routes_inner(
  routes : Array[SolRoutes],
  prefix : String,
  inherited_layouts : Array[
    (PageProps, @server_dom.ServerNode) -> @server_dom.ServerNode raise Error,
  ],
  inherited_middlewares : Array[@middleware.Middleware],
  result : Array[CompiledSolRoute],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, handler~, title~, meta~, revalidate~, cache~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          page_handler: Some(handler),
          api_handler: None,
          layouts: inherited_layouts.copy(),
          middlewares: inherited_middlewares.copy(),
          kind: SolRouteKind::Page,
          title,
          meta,
          catch_all,
          revalidate,
          cache_strategy: cache.unwrap_or(CacheStrategy::AlwaysFetch),
          rendered_meta: render_meta_tags(meta),
        })
      }
      Layout(segment~, layout~, children~) => {
        let new_prefix = normalize_path(prefix + segment)
        let new_layouts = inherited_layouts.copy()
        new_layouts.push(layout)
        compile_sol_routes_inner(
          children, new_prefix, new_layouts, inherited_middlewares, result,
        )
      }
      Get(path~, handler~) =>
        push_api_route(result, prefix, path, handler, GetApi, inherited_middlewares)
      Post(path~, handler~) =>
        push_api_route(result, prefix, path, handler, PostApi, inherited_middlewares)
      Put(path~, handler~) =>
        push_api_route(result, prefix, path, handler, PutApi, inherited_middlewares)
      Delete(path~, handler~) =>
        push_api_route(result, prefix, path, handler, DeleteApi, inherited_middlewares)
      Patch(path~, handler~) =>
        push_api_route(result, prefix, path, handler, PatchApi, inherited_middlewares)
      WithMiddleware(middleware~, children~) => {
        let new_middlewares = inherited_middlewares + middleware
        compile_sol_routes_inner(
          children, prefix, inherited_layouts, new_middlewares, result,
        )
      }
    }
  }
}
