// Island Hydration API
//
// Provides a minimal API for component hydration.
// Components only need to provide render() and dispatch() functions.
// All FFI/boilerplate is handled by the framework.

// =============================================================================
// Island Context - Passed to component's hydrate function
// =============================================================================

///|
/// Island context for hydration
/// Provides access to element, state, and framework utilities
pub struct IslandContext {
  /// The DOM element to hydrate
  element : @js_dom.Element
  /// Component ID
  id : String
  /// Parsed state from luna:state attribute
  priv state_json : String
}

///|
/// Create island context from hydration call
pub fn IslandContext::new(
  element : @js_dom.Element,
  id : String,
  state_json : String,
) -> IslandContext {
  { element, id, state_json }
}

///|
/// Get the DOM element
pub fn IslandContext::get_element(self : IslandContext) -> @js_dom.Element {
  self.element
}

///|
/// Get the component ID
pub fn IslandContext::get_id(self : IslandContext) -> String {
  self.id
}

///|
/// Get the raw state JSON string
pub fn IslandContext::get_state_json(self : IslandContext) -> String {
  self.state_json
}

// =============================================================================
// Generic Hydration Entry Point
// =============================================================================

///|
extern "js" fn parse_int_from_state(json_str : String, key : String) -> Int =
  #| (json, key) => { try { return JSON.parse(json)[key] ?? 0; } catch { return 0; } }

///|
extern "js" fn stringify_state(state : @js.Any) -> String =
  #| (state) => JSON.stringify(state)

///|
extern "js" fn console_log_island(msg : String) -> Unit =
  #| (msg) => console.log(msg)

///|
/// Create a signal from island state with a specific key
pub fn IslandContext::signal_int(
  self : IslandContext,
  key : String,
  default_value : Int,
) -> @signal.Signal[Int] {
  let value = if self.state_json == "" {
    default_value
  } else {
    parse_int_from_state(self.state_json, key)
  }
  @signal.signal(value)
}

///|
/// Bind action handlers from DOM and set up reactive updates
pub fn IslandContext::bind_actions(
  self : IslandContext,
  dispatch : (String) -> Unit,
) -> Unit {
  @client.bind_actions_from_dom(self.element, dispatch)
}

///|
/// Set up reactive effect to update display
pub fn IslandContext::on_update(
  self : IslandContext,
  selector : String,
  update_fn : () -> String,
) -> Unit {
  let elem = self.element
  let _ = @signal.effect(fn() {
    let text = update_fn()
    update_element_text(elem, selector, text)
  })

}

///|
extern "js" fn update_element_text(
  container : @js_dom.Element,
  selector : String,
  text : String,
) -> Unit =
  #| (container, selector, text) => {
  #|   const el = container.querySelector(selector);
  #|   if (el) el.textContent = text;
  #| }

// =============================================================================
// High-Level Hydration Helper
// =============================================================================

///|
/// Generic hydration function for simple counter-like components
/// Takes the ln-loader hydrate signature and component-specific logic
///
/// Usage in component:
/// ```moonbit
/// pub fn hydrate(element : @js.Any, state : @js.Any, id : String) -> Unit {
///   @dom.hydrate_island(element, state, id, fn(ctx) {
///     let count = ctx.signal_int("count", 0)
///     ctx.bind_actions(fn(action) {
///       match action {
///         "increment" => count.set(count.get() + 1)
///         "decrement" => count.set(count.get() - 1)
///         _ => ()
///       }
///     })
///     ctx.on_update(".count-display", fn() { "Count: " + count.get().to_string() })
///   })
/// }
/// ```
pub fn hydrate_island(
  element : @js.Any,
  state : @js.Any,
  id : String,
  setup : (IslandContext) -> Unit,
) -> Unit {
  console_log_island("[" + id + "] hydrating...")

  // Cast element to DOM Element
  let elem : @js_dom.Element = element.cast()

  // Convert state to JSON string
  let state_json = stringify_state(state)

  // Create context
  let ctx = IslandContext::new(elem, id, state_json)

  // Run component setup
  setup(ctx)
  console_log_island("[" + id + "] hydration complete")
}
