///| server_dom - Server-side DOM for SSR

///|

///| This module provides a DOM API for server-side rendering.

///| - No event handlers (E = Unit)

///| - Document structure elements (html, head, body)

///| - Island integration for client components

///|
/// Render result with HTML and preload URLs
pub struct RenderResult {
  html : String
  preload_urls : Array[String]
}
