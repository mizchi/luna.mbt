// JS API - Generic wrappers using Any type for JavaScript consumption
//

///|
/// Opaque type for JS interop - represents any JS value
#external
pub type Any

// Signal operations with Any

///|
/// Create a signal with any value
pub fn create_signal(initial : Any) -> @signal.Signal[Any] {
  @signal.signal(initial)
}

///|
/// Get signal value
pub fn get(sig : @signal.Signal[Any]) -> Any {
  sig.get()
}

///|
/// Set signal value
pub fn set(sig : @signal.Signal[Any], value : Any) -> Unit {
  sig.set(value)
}

///|
/// Update signal with function
pub fn update(sig : @signal.Signal[Any], f : (Any) -> Any) -> Unit {
  sig.update(f)
}

///|
/// Peek signal value without tracking
pub fn peek(sig : @signal.Signal[Any]) -> Any {
  sig.peek()
}

///|
/// Subscribe to signal changes
pub fn subscribe(
  sig : @signal.Signal[Any],
  callback : (Any) -> Unit,
) -> () -> Unit {
  @signal.on(sig, callback)
}

///|
/// Map signal to derived value
pub fn map(sig : @signal.Signal[Any], f : (Any) -> Any) -> () -> Any {
  sig.map(f)
}

///|
/// Create a memo (computed value)
pub fn create_memo(compute : () -> Any) -> () -> Any {
  @signal.memo(compute)
}

///|
/// Combine two signals
pub fn combine(
  a : @signal.Signal[Any],
  b : @signal.Signal[Any],
  f : (Any, Any) -> Any,
) -> () -> Any {
  @signal.combine2(a, b, f)
}

///|
/// Create an effect (deferred execution via microtask, like Solid.js createEffect)
pub fn effect(fn_ : () -> Unit) -> () -> Unit {
  @signal.effect(fn_)
}

///|
/// Create a render effect (immediate execution, like Solid.js createRenderEffect)
pub fn render_effect(fn_ : () -> Unit) -> () -> Unit {
  @signal.render_effect(fn_)
}

///|
/// Start batch updates
pub fn batch_start() -> Unit {
  @signal.batch_start()
}

///|
/// End batch updates
pub fn batch_end() -> Unit {
  @signal.batch_end()
}

///|
/// Run function without tracking dependencies
pub fn run_untracked(f : () -> Any) -> Any {
  @signal.untracked(f)
}

///|
/// Run a function in a batch - all signal updates are batched
pub fn batch(f : () -> Any) -> Any {
  @signal.batch(f)
}

///|
/// Register a cleanup function inside an effect
pub fn on_cleanup(cleanup : () -> Unit) -> Unit {
  @signal.on_cleanup(cleanup)
}

// ============================================================================
// Owner-based scope management (Solid.js style)
// ============================================================================

///|
/// Opaque Owner type for JS
pub struct JsOwner(@signal.Owner)

///|
/// Create a new reactive root scope
/// The function receives a dispose callback
pub fn create_root(f : (() -> Unit) -> Any) -> Any {
  @signal.create_root(f)
}

///|
/// Get the current owner (if any)
pub fn get_owner() -> JsOwner? {
  match @signal.get_owner() {
    Some(owner) => Some(JsOwner(owner))
    None => None
  }
}

///|
/// Run a function with a specific owner as current
pub fn run_with_owner(owner : JsOwner, f : () -> Any) -> Any {
  @signal.run_with_owner(owner.0, f)
}

///|
/// Check if currently inside an owner scope
pub fn has_owner() -> Bool {
  @signal.has_owner()
}

///|
/// Queue a microtask (runs after current synchronous execution)
extern "js" fn queue_microtask(f : () -> Unit) -> Unit =
  #| (f) => queueMicrotask(f)

///|
/// Run a function once (Solid.js style onMount)
/// The callback is deferred via microtask to run after DOM is created and refs are bound.
/// onCleanup registered inside will run when the owner is disposed (component unmounts).
pub fn on_mount(fn_ : () -> Unit) -> Unit {
  // Capture current owner for later use
  let captured_owner = @signal.get_owner()

  // Queue microtask to run after current synchronous execution.
  // This ensures refs are bound before onMount runs.
  queue_microtask(fn() {
    match captured_owner {
      Some(owner) => {
        // Run with owner context so cleanup registration works
        @signal.run_with_owner(owner, fn() {
          // Run untracked (no dependency tracking)
          @signal.untracked(fn() {
            // Set up cleanup tracking
            let mount_cleanups : Array[() -> Unit] = []
            @signal.run_with_cleanup_tracking(mount_cleanups, fn_)
            // Transfer cleanups to owner so they run on unmount
            for cleanup in mount_cleanups {
              owner.cleanups.push(cleanup)
            }
          })
        })
      }
      None =>
        // No owner - just run untracked
        @signal.untracked(fn_)
    }
  })
}

// ============================================================================
// DOM utilities (type-erased wrappers for JS)
// ============================================================================

///|
/// List rendering with reference-based DOM reuse (Solid-style)
/// Type-erased wrapper for @element.for_each
pub fn for_each(
  items : () -> Array[Any],
  render_item : (Any, Int) -> @element.DomNode,
) -> @element.DomNode {
  @element.for_each(items, render_item)
}

// ============================================================================
// Re-export from @element for JS API
// ============================================================================

///|
pub fn text(content : String) -> @element.DomNode {
  @element.text(content)
}

///|
pub fn text_dyn(get_content : () -> String) -> @element.DomNode {
  @element.text_dyn(get_content)
}

///|
pub fn render_to(root : @js_dom.Element, node : @element.DomNode) -> Unit {
  @element.render_to(root, node)
}

///|
pub fn mount_to(root : @js_dom.Element, node : @element.DomNode) -> Unit {
  @element.mount_to(root, node)
}

///|
pub fn show(
  cond : () -> Bool,
  render : () -> @element.DomNode,
) -> @element.DomNode {
  @element.show(cond, render)
}

///|
pub fn jsx(
  tag : String,
  attrs : Array[(String, @element.AttrValue)],
  children : Array[@element.DomNode],
) -> @element.DomNode {
  @element.jsx(tag, attrs, children)
}

///|
pub fn jsxs(
  tag : String,
  attrs : Array[(String, @element.AttrValue)],
  children : Array[@element.DomNode],
) -> @element.DomNode {
  @element.jsxs(tag, attrs, children)
}

///|
pub fn fragment(children : Array[@element.DomNode]) -> @element.DomNode {
  @element.fragment(children)
}

///|
pub fn create_element(
  tag : String,
  attrs : Array[(String, @element.AttrValue)],
  children : Array[@element.DomNode],
) -> @element.DomNode {
  @element.create_element(tag, attrs, children)
}

///|
/// Create an element with namespace (for SVG, MathML, etc.)
pub fn create_element_ns(
  ns : String,
  tag : String,
  attrs : Array[(String, @element.AttrValue)],
  children : Array[@element.DomNode],
) -> @element.DomNode {
  @element.create_element_ns(ns, tag, attrs, children)
}

///|
/// SVG namespace constant
pub fn svg_ns() -> String {
  @element.svg_ns
}

///|
/// MathML namespace constant
pub fn mathml_ns() -> String {
  @element.mathml_ns
}

///|
pub fn events() -> @element.HandlerMap {
  @element.events()
}

// ============================================================================
// Timer utilities
// ============================================================================

///|
/// Debounce signal updates using setTimeout
/// Returns a new signal that only updates after `delay_ms` milliseconds
/// of no changes to the source signal
pub fn debounced(
  sig : @signal.Signal[Any],
  delay_ms : Int,
) -> @signal.Signal[Any] {
  @dom.debounced(sig, delay_ms)
}

// ============================================================================
// Routes Definition
// ============================================================================

///|
/// Create a page route (simple version for JS)
pub fn route_page(path : String, component : String) -> @routes.Routes {
  @routes.Routes::Page(path~, component~, title="", meta=[])
}

///|
/// Create a page route with title
pub fn route_page_titled(
  path : String,
  component : String,
  title : String,
) -> @routes.Routes {
  @routes.Routes::Page(path~, component~, title~, meta=[])
}

///|
/// Create a page route with full options
pub fn route_page_full(
  path : String,
  component : String,
  title : String,
  meta : Array[(String, String)],
) -> @routes.Routes {
  @routes.Routes::Page(path~, component~, title~, meta~)
}

///|

// ============================================================================
// Client Router
// ============================================================================

///|
/// BrowserRouter for SPA navigation
pub struct BrowserRouter(@browser_router.BrowserRouter)

///|
/// Create a BrowserRouter from routes definition
pub fn create_router(
  routes : Array[@routes.Routes],
  base? : String = "",
) -> BrowserRouter {
  @browser_router.BrowserRouter::new(routes, base~)
}

///|
/// Navigate to a path (adds to history)
pub fn router_navigate(router : BrowserRouter, path : String) -> Unit {
  router.0.navigate(path)
}

///|
/// Replace current path (does not add to history)
pub fn router_replace(router : BrowserRouter, path : String) -> Unit {
  router.0.replace(path)
}

///|
/// Get current path
pub fn router_get_path(router : BrowserRouter) -> String {
  router.0.get_path()
}

///|
/// Get current match result
pub fn router_get_match(router : BrowserRouter) -> @routes.RoutesMatch? {
  router.0.get_match()
}

///|
/// Get base path
pub fn router_get_base(router : BrowserRouter) -> String {
  router.0.get_base()
}

// ============================================================================
// Context API (Solid.js style)
// ============================================================================

///|
/// Context wrapper for JS
pub struct JsContext(@signal.Context[Any])

///|
/// Create a new context with a default value
pub fn create_context(default_value : Any) -> JsContext {
  JsContext(@signal.create_context(default_value))
}

///|
/// Provide a context value for the duration of a function
pub fn provide(ctx : JsContext, value : Any, f : () -> Any) -> Any {
  @signal.provide(ctx.0, value, f)
}

///|
/// Use a context value - returns the current provided value or default
pub fn use_context(ctx : JsContext) -> Any {
  @signal.use_context(ctx.0)
}

// ============================================================================
// Resource API (Async state management)
// ============================================================================

///|
/// Resource wrapper for JS
pub struct JsResource(@signal.Resource[Any])

///|
/// AsyncState wrapper for JS
pub struct JsAsyncState(@signal.AsyncState[Any])

///|
/// Create a Resource from a Promise-style fetcher
/// The fetcher receives (resolve, reject) callbacks
pub fn create_resource(
  fetcher : ((Any) -> Unit, (String) -> Unit) -> Unit,
) -> JsResource {
  JsResource(@signal.resource(fetcher))
}

///|
/// Create a deferred Resource (starts pending, resolve/reject manually)
pub fn create_deferred() -> (JsResource, (Any) -> Unit, (String) -> Unit) {
  let (res, resolve, reject) = @signal.deferred()
  (JsResource(res), resolve, reject)
}

///|
/// Get current async state (reactive)
pub fn resource_get(res : JsResource) -> JsAsyncState {
  res.0.get()
}

///|
/// Peek current state without tracking
pub fn resource_peek(res : JsResource) -> JsAsyncState {
  res.0.peek()
}

///|
/// Trigger refetch
pub fn resource_refetch(res : JsResource) -> Unit {
  res.0.refetch()
}

///|
/// Check if currently pending
pub fn resource_is_pending(res : JsResource) -> Bool {
  res.0.is_pending()
}

///|
/// Check if successfully loaded
pub fn resource_is_success(res : JsResource) -> Bool {
  res.0.is_success()
}

///|
/// Check if failed
pub fn resource_is_failure(res : JsResource) -> Bool {
  res.0.is_failure()
}

///|
/// Get value if success, undefined otherwise
pub fn resource_value(res : JsResource) -> Any {
  match res.0.value() {
    Some(v) => v
    None => undefined()
  }
}

///|
/// Get error if failure, undefined otherwise
pub fn resource_error(res : JsResource) -> String {
  match res.0.error() {
    Some(e) => e
    None => ""
  }
}

///|
/// JS undefined value
extern "js" fn undefined() -> Any =
  #| () => undefined

// AsyncState helpers

///|
/// Check if state is pending
pub fn state_is_pending(state : JsAsyncState) -> Bool {
  state.0.is_pending()
}

///|
/// Check if state is success
pub fn state_is_success(state : JsAsyncState) -> Bool {
  state.0.is_success()
}

///|
/// Check if state is failure
pub fn state_is_failure(state : JsAsyncState) -> Bool {
  state.0.is_failure()
}

///|
/// Get value from state if success
pub fn state_value(state : JsAsyncState) -> Any {
  match state.0.value() {
    Some(v) => v
    None => undefined()
  }
}

///|
/// Get error from state if failure
pub fn state_error(state : JsAsyncState) -> String {
  match state.0.error() {
    Some(e) => e
    None => ""
  }
}

// ============================================================================
// Portal API (SolidJS-style Portal)
// ============================================================================

///|
/// Convert element DomNode to portal DomNode
fn to_portal_node(n : @element.DomNode) -> @portal.DomNode {
  @portal.DomNode::Raw(n.to_dom())
}

///|
/// Convert portal DomNode to element DomNode (as Raw)
fn from_portal_node(n : @portal.DomNode) -> @element.DomNode {
  @element.dom_node(n.to_dom())
}

///|
/// Create a portal that renders children into document.body
/// Returns a placeholder node at the original location
pub fn portal_to_body(children : Array[@element.DomNode]) -> @element.DomNode {
  let portal_children = children.map(to_portal_node)
  from_portal_node(@portal.portal_to_body(portal_children))
}

///|
/// Create a portal that renders children into a specific selector
pub fn portal_to_selector(
  selector : String,
  children : Array[@element.DomNode],
) -> @element.DomNode {
  let portal_children = children.map(to_portal_node)
  from_portal_node(@portal.portal_to_selector(selector, portal_children))
}

///|
/// Create a portal with Shadow DOM encapsulation
pub fn portal_with_shadow(
  children : Array[@element.DomNode],
) -> @element.DomNode {
  let portal_children = children.map(to_portal_node)
  from_portal_node(@portal.portal_with_shadow(portal_children))
}

///|
/// Create a portal to a specific element with Shadow DOM
pub fn portal_to_element_with_shadow(
  mount : @js_dom.Element,
  children : Array[@element.DomNode],
) -> @element.DomNode {
  let portal_children = children.map(to_portal_node)
  from_portal_node(@portal.portal_to_with_shadow(mount, portal_children))
}
