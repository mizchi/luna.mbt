// Server Islands - Deferred server-side rendering
//
// Server Islands allow components to be rendered lazily on the server.
// The initial response contains a fallback placeholder, and the client
// fetches the actual rendered HTML from a dedicated endpoint.

// ============================================================================
// Server Island Types
// ============================================================================

///|
/// Definition of a server island component
pub(all) struct ServerIslandDef {
  /// Unique identifier for the island
  id : String
  /// Async render function that takes JSON props and returns ServerNode
  render : async (Json) -> @server_dom.ServerNode
  /// Optional revalidation interval in seconds for Cache-Control
  revalidate : Int?
}

///|
/// Registry of server island components
pub(all) struct ServerIslandRegistry {
  /// Map of island ID to its definition
  islands : Map[String, ServerIslandDef]
}

///|
/// Create an empty server island registry
pub fn ServerIslandRegistry::new() -> ServerIslandRegistry {
  { islands: {} }
}

///|
/// Register a server island component
pub fn ServerIslandRegistry::register(
  self : ServerIslandRegistry,
  def : ServerIslandDef,
) -> Unit {
  self.islands[def.id] = def
}

///|
/// Get a server island definition by ID
pub fn ServerIslandRegistry::get(
  self : ServerIslandRegistry,
  id : String,
) -> ServerIslandDef? {
  self.islands.get(id)
}

///|
/// Check if the registry has any islands registered
pub fn ServerIslandRegistry::is_empty(self : ServerIslandRegistry) -> Bool {
  self.islands.is_empty()
}

// ============================================================================
// Defer Endpoint Registration
// ============================================================================

///|
/// Register the `/_sol/defer/:id` endpoint for server islands.
/// Called from `register_compiled_sol_routes` when a registry is provided.
fn register_defer_endpoint(
  app : App,
  registry : ServerIslandRegistry,
) -> Unit {
  app.get(
    "/_sol/defer/:id",
    @mars.handler(async fn(c) {
      let id = c.param("id").unwrap_or("")
      match registry.get(id) {
        None => c.text("Server island not found: \{id}", status=404)
        Some(def) => {
          // Parse props from query parameter
          let props_str = c.query("props").unwrap_or("{}")
          let props : Json = @json.parse(props_str) catch {
            _ => ().to_json()
          }
          // Render the island
          let node : @server_dom.ServerNode = (def.render)(props)
          // Resolve async node and render to HTML
          let resolved = node.resolve()
          let html = @render.render_to_string(resolved).html
          // Set cache headers if revalidate is configured
          match def.revalidate {
            Some(seconds) =>
              c.set_header(
                "Cache-Control",
                "s-maxage=\{seconds}, stale-while-revalidate",
              )
            None => ()
          }
          c.set_header("Content-Type", "text/html; charset=utf-8")
          c.text(html)
        }
      }
    }),
  )
}
