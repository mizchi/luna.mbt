///| Web Components Island helpers for server_dom

///|

///| Provides integration with Web Components based client-side components.

///| Uses Declarative Shadow DOM for SSR.

///|
/// Create a Web Components island for client-side hydration
///
/// Example:
/// ```moonbit
/// wc_island(
///   name="wc-counter",
///   url="/static/wc-counter.js",
///   styles=":host { display: block; }",
///   state="{\"count\":0}",
///   children=[text("Loading...")],
/// )
/// ```
pub fn wc_island(
  name : String,
  url : String,
  styles? : String,
  state? : String,
  trigger? : @luna.TriggerType,
  children~ : Array[@luna.Node[Unit]],
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
    None => @luna.Load
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

///|
/// Create a Web Components island with load trigger (hydrates immediately)
/// @deprecated Use `wc_island(name, url, styles~, state~, trigger=@luna.Load, children~)` instead
#deprecated("Use wc_island() with trigger parameter instead")
pub fn wc_island_load(
  name : String,
  url : String,
  styles : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  wc_island(name, url, styles~, state~, trigger=@luna.Load, children~)
}

///|
/// Create a Web Components island with idle trigger (hydrates when browser is idle)
/// @deprecated Use `wc_island(name, url, styles~, state~, trigger=@luna.Idle, children~)` instead
#deprecated("Use wc_island() with trigger parameter instead")
pub fn wc_island_idle(
  name : String,
  url : String,
  styles : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  wc_island(name, url, styles~, state~, trigger=@luna.Idle, children~)
}

///|
/// Create a Web Components island with visible trigger (hydrates when visible)
/// @deprecated Use `wc_island(name, url, styles~, state~, trigger=@luna.Visible, children~)` instead
#deprecated("Use wc_island() with trigger parameter instead")
pub fn wc_island_visible(
  name : String,
  url : String,
  styles : String,
  state : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  wc_island(name, url, styles~, state~, trigger=@luna.Visible, children~)
}

///|
/// Create a Web Components island with media trigger
/// @deprecated Use `wc_island(name, url, styles~, state~, trigger=@luna.Media(query), children~)` instead
#deprecated("Use wc_island() with trigger parameter instead")
pub fn wc_island_media(
  name : String,
  url : String,
  styles : String,
  state : String,
  media_query : String,
  children~ : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  wc_island(
    name,
    url,
    styles~,
    state~,
    trigger=@luna.Media(media_query),
    children~,
  )
}
