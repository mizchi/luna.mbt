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

// =============================================================================
// Server Node - Supports both sync and async server components
// =============================================================================

///|
/// Server component result type
/// Supports both synchronous and asynchronous server components:
/// - Sync: returns Node[Unit] directly
/// - Async: returns async function that resolves to Node[Unit]
pub enum ServerNode {
  Sync(@luna.Node[Unit])
  Async(async () -> @luna.Node[Unit])
}

///|
/// Create a synchronous ServerNode from a Node
pub fn ServerNode::sync(node : @luna.Node[Unit]) -> ServerNode {
  Sync(node)
}

///|
/// Create an asynchronous ServerNode from an async function
pub fn ServerNode::async_(render : async () -> @luna.Node[Unit]) -> ServerNode {
  Async(render)
}

///|
/// Resolve ServerNode to Node (awaits if async)
pub async fn ServerNode::resolve(self : ServerNode) -> @luna.Node[Unit] {
  match self {
    Sync(node) => node
    Async(render) => render()
  }
}

///|
/// Check if ServerNode is async
pub fn ServerNode::is_async(self : ServerNode) -> Bool {
  match self {
    Async(_) => true
    Sync(_) => false
  }
}
