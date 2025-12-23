// Web Components Island Hydration API
//
// Provides integration with Web Components based islands.
// Uses DOM Parts for efficient partial updates.

// =============================================================================
// WcIsland Context - For Web Components based islands
// =============================================================================

///|
/// Web Components Island context for hydration
/// Provides access to shadow DOM, parts, and framework utilities
pub struct WcIslandContext {
  /// The custom element
  element : @js_dom.Element
  /// Shadow root of the element
  shadow_root : @js.Any
  /// Map of DOM Parts by name (from wcssr)
  parts : @js.Any
  /// Parsed state from data-state attribute
  priv state_json : String
}

// =============================================================================
// FFI Functions for wcssr integration
// =============================================================================

///|
extern "js" fn get_shadow_root(element : @js_dom.Element) -> @js.Any =
  #| (element) => element.shadowRoot

///|
extern "js" fn hydrate_parts_ffi(shadow_root : @js.Any) -> @js.Any =
  #| (root) => {
  #|   if (window.__WCSSR__?.hydratePartsFromElement) {
  #|     return window.__WCSSR__.hydratePartsFromElement(root);
  #|   }
  #|   // Fallback: return empty Map
  #|   return new Map();
  #| }

///|
extern "js" fn set_part_value(
  parts : @js.Any,
  name : String,
  value : String,
) -> Unit =
  #| (parts, name, value) => {
  #|   const part = parts.get(name);
  #|   if (part) part.value = value;
  #| }

///|
extern "js" fn commit_part(parts : @js.Any, name : String) -> Unit =
  #| (parts, name) => {
  #|   const part = parts.get(name);
  #|   if (part) part.commit();
  #| }

///|
extern "js" fn parse_data_state(element : @js_dom.Element) -> String =
  #| (element) => {
  #|   const s = element.dataset.state || '{}';
  #|   try {
  #|     return s
  #|       .replace(/\\u003c/g, '<')
  #|       .replace(/\\u003e/g, '>')
  #|       .replace(/\\u0026/g, '&');
  #|   } catch { return '{}'; }
  #| }

///|
extern "js" fn bind_event_handler(
  shadow_root : @js.Any,
  selector : String,
  event_type : String,
  handler : () -> Unit,
) -> Unit =
  #| (root, selector, eventType, handler) => {
  #|   const el = root.querySelector(selector);
  #|   if (el) el.addEventListener(eventType, () => handler());
  #| }

///|
extern "js" fn bind_on_handlers(
  shadow_root : @js.Any,
  event_type : String,
  callback : (String) -> Unit,
) -> Unit =
  #| (root, eventType, callback) => {
  #|   const attr = `data-on-${eventType}`;
  #|   root.querySelectorAll(`[${attr}]`).forEach(el => {
  #|     const handlerName = el.getAttribute(attr);
  #|     if (handlerName) {
  #|       el.addEventListener(eventType, () => callback(handlerName));
  #|     }
  #|   });
  #| }

///|
extern "js" fn console_log_wc(msg : String) -> Unit =
  #| (msg) => console.log(msg)

///|
/// Check if element has a valid shadow root
extern "js" fn has_shadow_root(element : @js_dom.Element) -> Bool =
  #| (element) => element.shadowRoot != null

///|
/// Get shadow root as Element for hydration
/// Note: ShadowRoot shares many methods with Element (querySelector, childNodes, etc.)
extern "js" fn get_shadow_root_as_element(
  element : @js_dom.Element,
) -> @js_dom.Element =
  #| (element) => element.shadowRoot

// =============================================================================
// WcIslandContext Methods
// =============================================================================

///|
/// Create WcIslandContext from a custom element
pub fn WcIslandContext::new(element : @js_dom.Element) -> WcIslandContext? {
  let shadow_root = get_shadow_root(element)

  // Check if shadow root exists
  if is_null_or_undefined(shadow_root) {
    return None
  }

  // Hydrate DOM Parts from the shadow root
  let parts = hydrate_parts_ffi(shadow_root)

  // Parse state from data-state attribute
  let state_json = parse_data_state(element)
  Some({ element, shadow_root, parts, state_json })
}

///|
extern "js" fn is_null_or_undefined(value : @js.Any) -> Bool =
  #| (v) => v == null || v === undefined

///|
/// Get the DOM element
pub fn WcIslandContext::get_element(self : WcIslandContext) -> @js_dom.Element {
  self.element
}

///|
/// Get the shadow root
pub fn WcIslandContext::get_shadow_root(self : WcIslandContext) -> @js.Any {
  self.shadow_root
}

///|
/// Get the raw state JSON string
pub fn WcIslandContext::get_state_json(self : WcIslandContext) -> String {
  self.state_json
}

///|
/// Create a signal from state with a specific key
pub fn WcIslandContext::signal_int(
  self : WcIslandContext,
  key : String,
  default_value : Int,
) -> @signal.Signal[Int] {
  let value = if self.state_json == "" || self.state_json == "{}" {
    default_value
  } else {
    parse_int_from_state(self.state_json, key)
  }
  @signal.signal(value)
}

///|
/// Bind a Signal to a DOM Part by name
/// When the signal changes, the part is automatically updated
pub fn[T : Show] WcIslandContext::bind_signal(
  self : WcIslandContext,
  part_name : String,
  signal : @signal.Signal[T],
) -> Unit {
  let parts = self.parts
  let _ = @signal.effect(fn() {
    let value = signal.get().to_string()
    set_part_value(parts, part_name, value)
    commit_part(parts, part_name)
  })

}

///|
/// Bind event handlers using data-on-* attributes
pub fn WcIslandContext::bind_actions(
  self : WcIslandContext,
  dispatch : (String) -> Unit,
) -> Unit {
  // Bind common event types
  bind_on_handlers(self.shadow_root, "click", dispatch)
  bind_on_handlers(self.shadow_root, "input", dispatch)
  bind_on_handlers(self.shadow_root, "change", dispatch)
}

///|
/// Bind a specific event handler by selector
pub fn WcIslandContext::on(
  self : WcIslandContext,
  selector : String,
  event_type : String,
  handler : () -> Unit,
) -> Unit {
  bind_event_handler(self.shadow_root, selector, event_type, handler)
}

// =============================================================================
// High-Level Hydration Helper
// =============================================================================

///|
/// Hydrate a Web Components island
///
/// Usage in component:
/// ```moonbit
/// pub fn hydrate(element : @js.Any) -> Unit {
///   @dom.hydrate_wc_island(element, fn(ctx) {
///     let count = ctx.signal_int("count", 0)
///
///     // Bind signal to DOM Part
///     ctx.bind_signal("count", count)
///
///     // Bind action handlers
///     ctx.bind_actions(fn(action) {
///       match action {
///         "increment" => count.set(count.get() + 1)
///         "decrement" => count.set(count.get() - 1)
///         _ => ()
///       }
///     })
///   })
/// }
/// ```
pub fn hydrate_wc_island(
  element : @js.Any,
  setup : (WcIslandContext) -> Unit,
) -> Unit {
  // Cast element to DOM Element
  let elem : @js_dom.Element = element.cast()
  let name = elem.tagName()
  console_log_wc("[" + name + "] hydrating...")

  // Create context
  match WcIslandContext::new(elem) {
    Some(ctx) => {
      // Run component setup
      setup(ctx)
      console_log_wc("[" + name + "] hydration complete")
    }
    None =>
      console_log_wc("[" + name + "] no shadow root found, skipping hydration")
  }
}

// =============================================================================
// Unified Hydration API - Auto-detects WC vs Luna mode
// =============================================================================

///|
/// Check if an element is a Web Component (has shadow root)
pub fn is_wc_element(element : @js_dom.Element) -> Bool {
  has_shadow_root(element)
}

///|
/// Get shadow root as Element for use with hydration functions
/// Returns None if element has no shadow root
pub fn get_shadow_root_for_hydrate(
  element : @js_dom.Element,
) -> @js_dom.Element? {
  if has_shadow_root(element) {
    Some(get_shadow_root_as_element(element))
  } else {
    None
  }
}

///|
/// Unified hydration function that auto-detects WC vs Luna mode
///
/// For Web Components (has shadowRoot):
///   - Hydrates into existing shadow DOM (attaches handlers to existing elements)
///
/// For Luna Islands (no shadowRoot):
///   - Renders new DOM into element (clears and creates new content)
///
/// When is_rerender is true, always uses render mode (full re-render)
///
/// Usage:
/// ```moonbit
/// pub fn hydrate_counter(element : @js.Any, state : @js.Any, _id : String) -> Unit {
///   let jsdom_el : @js_dom.Element = element.cast()
///   let props : CounterProps = ... // parse state
///   let node = counter(props)
///   @wc.hydrate_auto(jsdom_el, node)
/// }
/// ```
pub fn hydrate_auto(
  element : @js_dom.Element,
  node : @luna.Node[@js.Any],
  is_rerender? : Bool = false,
) -> Unit {
  if has_shadow_root(element) {
    // WC mode - hydrate into shadow root
    let shadow_root = get_shadow_root_as_element(element)
    if is_rerender {
      console_log_wc(
        "[" + element.tagName() + "] WC mode - re-rendering shadow DOM",
      )
      // Re-render: clear and create new content
      let js_node = @client.render_vnode_to_dom(node)
      shadow_root.as_node().setTextContent("")
      shadow_root.as_node().appendChild(js_node) |> ignore
    } else {
      console_log_wc(
        "[" + element.tagName() + "] WC mode - hydrating shadow DOM",
      )
      // Use Luna's hydrate function on shadow root
      @client.hydrate(shadow_root, node) |> ignore
    }
  } else {
    // Luna mode - render new DOM (always re-renders for DomNode)
    let el = @element.DomElement::from_jsdom(element)
    let js_node = @client.render_vnode_to_dom(node)
    let dom_node = @element.dom_node(js_node)
    @element.render(el, dom_node)
  }
}

///|
/// Unified rendering for DomNode-based components
/// Note: This performs client-side rendering, not true hydration.
/// DomNode already contains Signal-bound DOM nodes, so we cannot reuse SSR HTML.
///
/// For WC mode: Replaces shadow root content (preserves SSR styles, smooth transition)
/// For Luna mode: Renders into element (clears and mounts)
/// When is_rerender is true, forces full re-render (same behavior since DomNode always renders)
pub fn hydrate_auto_dom(
  element : @js_dom.Element,
  node : @element.DomNode,
  is_rerender? : Bool = false,
) -> Unit {
  let _ = is_rerender // DomNode always renders (not true hydration)
  if has_shadow_root(element) {
    // WC mode - replace shadow root content while preserving styles
    let shadow_root = get_shadow_root_as_element(element)
    console_log_wc(
      "[" + element.tagName() + "] WC mode - replacing shadow DOM content",
    )

    // Prepare new content first (before clearing)
    let new_content = node.to_jsdom()

    // Create a document fragment for atomic replacement
    let doc = @js_dom.document()
    let fragment = doc.createDocumentFragment()

    // Preserve existing <style> elements from SSR
    let styles = extract_style_elements(shadow_root)
    for style in styles {
      fragment.as_node().appendChild(style) |> ignore
    }

    // Add new content to fragment
    fragment.as_node().appendChild(new_content) |> ignore

    // Clear and replace in one operation (minimizes flash)
    shadow_root.as_node().setTextContent("")
    shadow_root.as_node().appendChild(fragment.as_node()) |> ignore
  } else {
    // Luna mode - render new DOM
    let el = @element.DomElement::from_jsdom(element)
    @element.render(el, node)
  }
}

///|
/// Extract all <style> elements from a container
extern "js" fn extract_style_elements(
  container : @js_dom.Element,
) -> Array[@js_dom.Node] =
  #| (container) => {
  #|   const styles = [];
  #|   container.querySelectorAll('style').forEach(s => {
  #|     styles.push(s.cloneNode(true));
  #|   });
  #|   return styles;
  #| }
