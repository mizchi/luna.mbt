// server_dom - Server-side DOM for SSR
//
// This module provides a DOM API for server-side rendering.
// - No event handlers (E = Unit)
// - Document structure elements (html, head, body)
// - Island integration for client components
//

///|
/// Render result with HTML and preload URLs
pub struct RenderResult {
  html : String
  preload_urls : Array[String]
}

///|
/// CSS and JavaScript assets declared by server components.
pub struct ServerAssets {
  styles : Array[String]
  scripts : Array[String]
}

///|
/// Create an empty ServerAssets value.
pub fn ServerAssets::empty() -> ServerAssets {
  { styles: [], scripts: [] }
}

///|
/// Create ServerAssets from style and script paths.
pub fn ServerAssets::new(
  styles? : Array[String] = [],
  scripts? : Array[String] = [],
) -> ServerAssets {
  { styles, scripts }
}

///|
fn push_unique_path(paths : Array[String], path : String) -> Unit {
  if !paths.contains(path) {
    paths.push(path)
  }
}

///|
/// Merge assets preserving first-seen order.
pub fn ServerAssets::merge(
  self : ServerAssets,
  other : ServerAssets,
) -> ServerAssets {
  let styles = self.styles.copy()
  let scripts = self.scripts.copy()
  for style in other.styles {
    push_unique_path(styles, style)
  }
  for script in other.scripts {
    push_unique_path(scripts, script)
  }
  { styles, scripts }
}

// =============================================================================
// Server Node - Supports both sync and async server components
// =============================================================================

///|
/// Server component result type
/// Supports both synchronous and asynchronous server components:
/// - Sync: returns Node[Unit] directly
/// - Async: returns async function that resolves to Node[Unit]
pub enum ServerNode {
  Sync(@luna.Node[Unit, String])
  Async(async () -> @luna.Node[Unit, String])
  Group(Array[ServerNode])
  WithAssets(
    styles~ : Array[String],
    scripts~ : Array[String],
    child~ : ServerNode
  )
}

///|
/// Create a synchronous ServerNode from a Node
pub fn ServerNode::sync(node : @luna.Node[Unit, String]) -> ServerNode {
  Sync(node)
}

///|
/// Create an asynchronous ServerNode from an async function
pub fn ServerNode::async_(
  render : async () -> @luna.Node[Unit, String],
) -> ServerNode {
  Async(render)
}

///|
/// Create a ServerNode group from multiple server components.
pub fn ServerNode::group(children : Array[ServerNode]) -> ServerNode {
  Group(children)
}

///|
/// Attach CSS and JavaScript assets to a ServerNode.
pub fn ServerNode::with_assets(
  self : ServerNode,
  styles? : Array[String] = [],
  scripts? : Array[String] = [],
) -> ServerNode {
  WithAssets(styles~, scripts~, child=self)
}

///|
/// Attach a stylesheet asset to a ServerNode.
pub fn ServerNode::with_style(self : ServerNode, style : String) -> ServerNode {
  self.with_assets(styles=[style])
}

///|
/// Attach a client script asset to a ServerNode.
pub fn ServerNode::with_script(
  self : ServerNode,
  script : String,
) -> ServerNode {
  self.with_assets(scripts=[script])
}

///|
/// Resolve ServerNode to Node (awaits if async)
pub async fn ServerNode::resolve(self : ServerNode) -> @luna.Node[Unit, String] {
  match self {
    Sync(node) => node
    Async(render) => render()
    Group(children) => {
      let nodes : Array[@luna.Node[Unit, String]] = []
      for child in children {
        nodes.push(child.resolve())
      }
      @luna.fragment(nodes)
    }
    WithAssets(child~, ..) => child.resolve()
  }
}

///|
/// Check if ServerNode is async
pub fn ServerNode::is_async(self : ServerNode) -> Bool {
  match self {
    Async(_) => true
    Group(children) => {
      for child in children {
        if child.is_async() {
          return true
        }
      }
      false
    }
    WithAssets(child~, ..) => child.is_async()
    Sync(_) => false
  }
}

///|
/// Collect assets declared by this ServerNode without resolving async content.
pub fn ServerNode::declared_assets(self : ServerNode) -> ServerAssets {
  match self {
    Sync(_) | Async(_) => ServerAssets::empty()
    Group(children) => {
      let mut assets = ServerAssets::empty()
      for child in children {
        assets = assets.merge(child.declared_assets())
      }
      assets
    }
    WithAssets(styles~, scripts~, child~) =>
      ServerAssets::new(styles~, scripts~).merge(child.declared_assets())
  }
}
