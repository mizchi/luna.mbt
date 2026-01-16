// Web Components Island helpers for server_dom
//
// Provides integration with Web Components based client-side components.
// Uses Declarative Shadow DOM for SSR.
//

///|
/// Create a Web Components island for client-side hydration
///
/// Example:
/// ```moonbit
/// wc_island(
///   "wc-counter",
///   "/static/wc-counter.js",
///   [text("Loading...")],
///   styles=":host { display: block; }",
///   state="{\"count\":0}",
/// )
/// ```
pub fn wc_island(
  name : String,
  url : String,
  children : Array[@luna.Node[Unit]],
  styles? : String,
  state? : String,
  trigger? : @luna.TriggerType,
) -> @luna.Node[Unit] {
  let styles_value = match styles {
    Some(s) => s
    None => ""
  }
  let state_value = match state {
    Some(s) => s
    None => "{}"
  }
  let trigger_value = match trigger {
    Some(t) => t
    None => @core.Load
  }
  @luna.wc_island(
    name,
    url,
    styles_value,
    state_value,
    children,
    trigger=trigger_value,
  )
}
