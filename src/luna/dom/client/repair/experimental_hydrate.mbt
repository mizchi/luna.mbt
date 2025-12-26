// Experimental Hydration - Morphdom-like DOM diffing/patching during hydration
//
// This module provides resilient hydration that can repair mismatches between
// server-rendered HTML and the expected VDOM structure, similar to morphdom.
// Use this as a fallback when regular hydration fails.
//
// NOTE: This is an experimental module. The API may change in future versions.
//

///|
/// Type of repair operation performed
pub enum RepairType {
  /// Text content was different and updated
  TextMismatch
  /// Text node was missing and created
  TextMissing
  /// Element was missing and created
  ElementMissing
  /// Element tag was wrong and replaced
  TagMismatch
  /// Attribute value was wrong and updated
  AttributeMismatch
  /// Dynamic text marker was missing and created
  DynamicTextMarkerMissing
  /// Show markers were missing and created
  ShowMarkerMissing
  /// For markers were missing and created
  ForMarkerMissing
  /// For loop item count was different
  ForItemCountMismatch
  /// Show content was missing when condition was true
  ShowContentMissing
} derive(Eq)

///|
/// Detailed information about a single repair operation
pub struct RepairInfo {
  /// Type of repair performed
  repair_type : RepairType
  /// Human-readable description of the repair
  message : String
  /// Path to the node (e.g., "div > span > #text")
  node_path : String
  /// Expected value (if applicable)
  expected : String
  /// Actual value found (if applicable)
  actual : String
}

///|
/// Create a new RepairInfo
pub fn RepairInfo::new(
  repair_type : RepairType,
  message : String,
  node_path : String,
  expected : String,
  actual : String,
) -> RepairInfo {
  { repair_type, message, node_path, expected, actual }
}

///|
/// Get repair type
pub fn RepairInfo::get_type(self : RepairInfo) -> RepairType {
  self.repair_type
}

///|
/// Get message
pub fn RepairInfo::get_message(self : RepairInfo) -> String {
  self.message
}

///|
/// Get node path
pub fn RepairInfo::get_node_path(self : RepairInfo) -> String {
  self.node_path
}

///|
/// Get expected value
pub fn RepairInfo::get_expected(self : RepairInfo) -> String {
  self.expected
}

///|
/// Get actual value
pub fn RepairInfo::get_actual(self : RepairInfo) -> String {
  self.actual
}

///|
/// Result of experimental hydration with detailed repair info
pub struct ExperimentalHydrationReport {
  /// Whether hydration was clean (no repairs needed)
  clean : Bool
  /// List of detailed repair operations performed
  repairs : Array[RepairInfo]
  /// Total number of repairs
  repair_count : Int
}

///|
/// Create a clean report
pub fn ExperimentalHydrationReport::clean() -> ExperimentalHydrationReport {
  { clean: true, repairs: [], repair_count: 0 }
}

///|
/// Create a report with repairs
pub fn ExperimentalHydrationReport::with_repairs(
  repairs : Array[RepairInfo],
) -> ExperimentalHydrationReport {
  { clean: false, repairs, repair_count: repairs.length() }
}

///|
/// Check if hydration was clean
pub fn ExperimentalHydrationReport::is_clean(
  self : ExperimentalHydrationReport,
) -> Bool {
  self.clean
}

///|
/// Get all repairs
pub fn ExperimentalHydrationReport::get_repairs(
  self : ExperimentalHydrationReport,
) -> Array[RepairInfo] {
  self.repairs
}

///|
/// Get repair count
pub fn ExperimentalHydrationReport::get_repair_count(
  self : ExperimentalHydrationReport,
) -> Int {
  self.repair_count
}

///|
/// Get repairs filtered by type
pub fn ExperimentalHydrationReport::get_repairs_by_type(
  self : ExperimentalHydrationReport,
  repair_type : RepairType,
) -> Array[RepairInfo] {
  self.repairs.filter(repair => repair.repair_type == repair_type)
}

///|
/// Check if report has any repair of given type
pub fn ExperimentalHydrationReport::has_repair_type(
  self : ExperimentalHydrationReport,
  repair_type : RepairType,
) -> Bool {
  self.repairs.iter().any(repair => repair.repair_type == repair_type)
}

// =============================================================================
// RepairType constructors for external access (blackbox tests)
// =============================================================================

///|
pub fn repair_type_text_mismatch() -> RepairType {
  TextMismatch
}

///|
pub fn repair_type_text_missing() -> RepairType {
  TextMissing
}

///|
pub fn repair_type_element_missing() -> RepairType {
  ElementMissing
}

///|
pub fn repair_type_tag_mismatch() -> RepairType {
  TagMismatch
}

///|
pub fn repair_type_attribute_mismatch() -> RepairType {
  AttributeMismatch
}

///|
pub fn repair_type_dynamic_text_marker_missing() -> RepairType {
  DynamicTextMarkerMissing
}

///|
pub fn repair_type_show_marker_missing() -> RepairType {
  ShowMarkerMissing
}

///|
pub fn repair_type_for_marker_missing() -> RepairType {
  ForMarkerMissing
}

///|
pub fn repair_type_for_item_count_mismatch() -> RepairType {
  ForItemCountMismatch
}

///|
pub fn repair_type_show_content_missing() -> RepairType {
  ShowContentMissing
}

///|
/// Result of experimental hydration (legacy, kept for compatibility)
pub enum ExperimentalHydrationResult {
  /// Hydration succeeded without any repairs
  Clean
  /// Hydration succeeded but required repairs (list of repairs made)
  Repaired(Array[String])
  /// Hydration failed completely (reserved for future use)
  Failed(String)
}

///|
/// Context for experimental hydration
priv struct ExperimentalHydrationContext {
  mut current_id : Int
  repairs : Array[String]
  repair_infos : Array[RepairInfo]
  logger : StringBuilder?
  path_stack : Array[String]
  /// Cache: sol:hk -> Element mapping for O(1) lookup
  hk_cache : @hashmap.HashMap[Int, @js_dom.Element]
}

///|
/// Get current node path from stack
fn get_current_path(ctx : ExperimentalHydrationContext) -> String {
  if ctx.path_stack.is_empty() {
    "root"
  } else {
    ctx.path_stack.iter().join(" > ")
  }
}

///|
/// Log a repair action with detailed info
fn log_repair_detailed(
  ctx : ExperimentalHydrationContext,
  repair_type : RepairType,
  msg : String,
  expected : String,
  actual : String,
) -> Unit {
  let node_path = get_current_path(ctx)
  let info = RepairInfo::new(repair_type, msg, node_path, expected, actual)
  ctx.repair_infos.push(info)
  ctx.repairs.push(msg)
  let full_msg = "[ExperimentalHydrate] " + msg
  match ctx.logger {
    Some(sb) => {
      sb.write_string(full_msg)
      sb.write_string("\n")
    }
    None => {
      let global = @global.global_this()
      let console = global["console"]
      console._call("log", [@js.any(full_msg)]) |> ignore
    }
  }
}

// =============================================================================
// Heuristics Configuration
// =============================================================================

///|
/// Threshold for node count difference ratio to trigger full re-render
/// If DOM has less than this ratio of expected nodes, fallback to full render
let min_node_ratio : Double = 0.3

///|
/// Maximum node count for experimental hydration
/// Above this, always use full render (O(n²) becomes too expensive)
/// Benchmark results show experimental_hydrate is ~4-12x slower than full render,
/// so we use a conservative threshold.
let max_hydration_nodes : Int = 50

// =============================================================================
// Heuristics Helper Functions
// =============================================================================

///|
/// Count total nodes in a VNode tree
fn count_vnode_nodes(node : @luna.Node[@js.Any]) -> Int {
  match node {
    @luna.Text(_) => 1
    @luna.DynamicText(_) => 1
    @luna.RawHtml(_) => 1
    @luna.Fragment(children) => {
      let mut count = 0
      for child in children {
        count = count + count_vnode_nodes(child)
      }
      count
    }
    @luna.Element(elem) => {
      let mut count = 1
      for child in elem.children {
        count = count + count_vnode_nodes(child)
      }
      count
    }
    @luna.Show(child=child_fn, ..) => 1 + count_vnode_nodes(child_fn())
    @luna.For(render=render_fn) => {
      let items = render_fn()
      let mut count = 1
      for item in items {
        count = count + count_vnode_nodes(item)
      }
      count
    }
    @luna.Component(render=render_fn) => 1 + count_vnode_nodes(render_fn())
    @luna.Island(island) => {
      let mut count = 1
      for child in island.children {
        count = count + count_vnode_nodes(child)
      }
      count
    }
    @luna.WcIsland(wc_island) => {
      let mut count = 1
      for child in wc_island.children {
        count = count + count_vnode_nodes(child)
      }
      count
    }
    @luna.InternalRef(iref) => {
      let mut count = 1
      for child in iref.children {
        count = count + count_vnode_nodes(child)
      }
      count
    }
    @luna.Async(async_node) => 1 + count_vnode_nodes((async_node.fallback)())
    @luna.ErrorBoundary(boundary) =>
      try 1 + count_vnode_nodes((boundary.children)()) catch {
        _ => 1 // Count just the boundary if children fail
      }
    @luna.Switch(switch_node) => {
      // Count the matching case or fallback
      for case_ in switch_node.cases {
        if (case_.when)() {
          return 1 + count_vnode_nodes((case_.render)())
        }
      }
      match switch_node.fallback {
        Some(fallback_fn) => 1 + count_vnode_nodes(fallback_fn())
        None => 1
      }
    }
  }
}

///|
/// Count total nodes in DOM subtree
fn count_dom_nodes(node : @js_dom.Node) -> Int {
  let mut count = 1
  let children = node.childNodes()
  for i in 0..<children.length() {
    count = count + count_dom_nodes(children[i])
  }
  count
}

///|
/// Check if heuristics suggest fallback to full render
fn should_fallback_to_full_render(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
) -> Bool {
  let vnode_count = count_vnode_nodes(node)

  // If expected VNode tree is too large, always fallback
  if vnode_count > max_hydration_nodes {
    return true
  }
  let dom_count = count_dom_nodes(container.as_node())

  // If DOM has very few nodes compared to expected, fallback
  // (likely completely mismatched structure)
  if dom_count == 0 {
    return true
  }
  let ratio = dom_count.to_double() / vnode_count.to_double()
  if ratio < min_node_ratio {
    return true
  }
  false
}

// =============================================================================
// Helper functions (local copies from hydrate.mbt for package isolation)
// =============================================================================

///|
/// Helper to get text content with default
fn get_text_content(node : @js_dom.Node) -> String {
  let data : @js.Any = node.as_any()._get("data")
  data.cast()
}

///|
/// Build hk_cache by scanning all elements with sol:hk attribute once
/// Uses recursive traversal since CSS selectors with colons have compatibility issues
fn build_hk_cache(
  container : @js_dom.Element,
) -> @hashmap.HashMap[Int, @js_dom.Element] {
  let cache : @hashmap.HashMap[Int, @js_dom.Element] = @hashmap.new()
  build_hk_cache_recursive(container.as_node(), cache)
  cache
}

///|
/// Recursively collect elements with sol:hk attribute into cache
fn build_hk_cache_recursive(
  node : @js_dom.Node,
  cache : @hashmap.HashMap[Int, @js_dom.Element],
) -> Unit {
  // Check if this node is an element
  if node.nodeType() == 1 {
    let elem : @js_dom.Element = node.as_any().cast()
    match elem.getAttribute("sol:hk") {
      Some(id_str) => {
        // Parse integer manually (simple positive int parser)
        let mut id = 0
        let mut valid = true
        for c in id_str {
          if c >= '0' && c <= '9' {
            id = id * 10 + (c.to_int() - '0'.to_int())
          } else {
            valid = false
            break
          }
        }
        if valid && not(id_str.is_empty()) {
          cache.set(id, elem)
        }
      }
      None => ()
    }
  }
  // Recursively process children
  let children = node.childNodes()
  for child in children {
    build_hk_cache_recursive(child, cache)
  }
}

///|
/// Find element with sol:hk="id" attribute using cache (O(1))
fn find_element_by_hk_cached(
  ctx : ExperimentalHydrationContext,
  id : Int,
) -> @js_dom.Element? {
  ctx.hk_cache.get(id)
}

///|
/// Find first child element with matching tag name
fn find_child_element_by_tag(
  parent : @js_dom.Node,
  tag : String,
) -> @js_dom.Element? {
  let children = parent.childNodes()
  let upper_tag = tag.to_upper()
  for child in children {
    if child.nodeType() == 1 { // Element node
      let elem : @js_dom.Element = child.as_any().cast()
      if elem.tagName() == upper_tag {
        return Some(elem)
      }
    }
  }
  None
}

///|
/// Extract event name from handler name (onClick -> click)
fn extract_event_name(name : String) -> String {
  if name.length() >= 2 {
    // Check if starts with "on"
    if name.code_unit_at(0) == "o".code_unit_at(0) &&
      name.code_unit_at(1) == "n".code_unit_at(0) {
      // Convert rest to lowercase
      let mut result = ""
      let iter = name.iter()
      let mut skip_count = 0
      for char in iter {
        if skip_count < 2 {
          skip_count = skip_count + 1
          continue
        }
        let lower_char = if char >= 'A' && char <= 'Z' {
          (char.to_int() + 32).unsafe_to_char()
        } else {
          char
        }
        result = result + lower_char.to_string()
      }
      result
    } else {
      name
    }
  } else {
    name
  }
}

///|
/// Apply VAttr to DOM element
fn apply_vattr(
  elem : @js_dom.Element,
  name : String,
  value : @luna.Attr[@js.Any],
) -> Unit {
  match value {
    @luna.VStatic(s) =>
      if s != "__remove__" {
        if name == "class" || name == "className" {
          elem.setClassName(s)
        } else if name == "value" {
          elem.as_any()._set("value", @js.any(s)) |> ignore
        } else if s == "" {
          elem.setAttribute(name, "")
        } else {
          elem.setAttribute(name, s)
        }
      }
    @luna.VDynamic(getter) => {
      let _ = @signal.effect(fn() {
        let new_value = getter()
        if new_value == "__remove__" {
          elem.removeAttribute(name)
        } else if name == "class" || name == "className" {
          elem.setClassName(new_value)
        } else if name == "value" {
          elem.as_any()._set("value", @js.any(new_value)) |> ignore
        } else {
          elem.setAttribute(name, new_value)
        }
      })

    }
    @luna.VHandler(handler) => {
      let event_name = extract_event_name(name)
      let callback = handler.get_callback()
      // Wrap callback to ignore event argument
      let wrapper : (@js.Any) -> Unit = fn(event) { callback(event) }
      elem
      .as_event_target()
      .addEventListener(event_name, @js.any(wrapper).cast())
    }
    @luna.VAction(_) =>
      // VAction without dispatcher - skip in experimental hydrate
      ()
  }
}

///|
/// Experimental hydration that repairs DOM mismatches instead of failing.
/// This is useful when server HTML may differ slightly from expected VDOM
/// (e.g., due to caching, different render paths, or user modifications).
///
/// Unlike regular hydrate, this function will:
/// - Patch missing elements by creating them
/// - Remove extra elements that don't match VDOM
/// - Update attributes to match expected values
/// - Repair text content differences
pub fn experimental_hydrate(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
  logger? : StringBuilder,
) -> ExperimentalHydrationResult {
  // Build hk_cache once for O(1) lookups
  let hk_cache = build_hk_cache(container)
  let ctx : ExperimentalHydrationContext = {
    current_id: 0,
    repairs: [],
    repair_infos: [],
    logger,
    path_stack: [],
    hk_cache,
  }

  // Perform hydration with repair capability
  experimental_hydrate_node(container.as_node(), node, ctx)

  // Return result based on repairs made
  if ctx.repairs.is_empty() {
    Clean
  } else {
    Repaired(ctx.repairs)
  }
}

///|
/// Smart hydration result type
pub enum SmartHydrateResult {
  /// Hydration succeeded (either clean or repaired)
  Hydrated(ExperimentalHydrationResult)
  /// Fell back to full render due to heuristics
  FellBackToFullRender(String)
}

///|
/// Smart hydration that uses heuristics to decide between repair and full re-render.
/// This is the recommended entry point for production use.
///
/// Heuristics applied:
/// - If VNode tree has more than 100 nodes, always use full render
/// - If DOM has less than 30% of expected nodes, use full render
///
/// Returns SmartHydrateResult indicating the strategy used.
pub fn smart_hydrate(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
  logger? : StringBuilder,
) -> SmartHydrateResult {
  // Check heuristics first
  if should_fallback_to_full_render(container, node) {
    let vnode_count = count_vnode_nodes(node)
    let dom_count = count_dom_nodes(container.as_node())
    let reason = if vnode_count > max_hydration_nodes {
      "VNode tree too large (" +
      vnode_count.to_string() +
      " > " +
      max_hydration_nodes.to_string() +
      ")"
    } else {
      "DOM/VNode ratio too low (" +
      dom_count.to_string() +
      "/" +
      vnode_count.to_string() +
      ")"
    }

    // Log fallback
    let log_msg = "[SmartHydrate] Falling back to full render: " + reason
    match logger {
      Some(sb) => {
        sb.write_string(log_msg)
        sb.write_string("\n")
      }
      None => {
        let global = @global.global_this()
        let console = global["console"]
        console._call("log", [@js.any(log_msg)]) |> ignore
      }
    }

    // Clear and full render
    container.as_node().setTextContent("")
    let dom_node = @client.render_vnode_to_dom(node)
    container.as_node().appendChild(dom_node) |> ignore
    FellBackToFullRender(reason)
  } else {
    // Use experimental hydration
    let result = experimental_hydrate(container, node, logger?)
    Hydrated(result)
  }
}

///|
/// Experimental hydration with detailed report.
/// Returns a detailed report including repair types, node paths, and expected/actual values.
pub fn experimental_hydrate_with_report(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
  logger? : StringBuilder,
) -> ExperimentalHydrationReport {
  let hk_cache = build_hk_cache(container)
  let ctx : ExperimentalHydrationContext = {
    current_id: 0,
    repairs: [],
    repair_infos: [],
    logger,
    path_stack: [],
    hk_cache,
  }

  // Perform hydration with repair capability
  experimental_hydrate_node(container.as_node(), node, ctx)

  // Return detailed report
  if ctx.repair_infos.is_empty() {
    ExperimentalHydrationReport::clean()
  } else {
    ExperimentalHydrationReport::with_repairs(ctx.repair_infos)
  }
}

///|
/// Internal: Hydrate a single node with repair capability
fn experimental_hydrate_node(
  parent : @js_dom.Node,
  node : @luna.Node[@js.Any],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  match node {
    @luna.Text(content) => experimental_hydrate_text(parent, content, ctx)
    @luna.RawHtml(_) => () // Raw HTML doesn't need hydration
    @luna.DynamicText(getter) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_dynamic_text(parent, id, getter, ctx)
    }
    @luna.Fragment(children) =>
      for child in children {
        experimental_hydrate_node(parent, child, ctx)
      }
    @luna.Element(elem) => experimental_hydrate_element(parent, elem, ctx)
    @luna.Show(condition=cond, child=child_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_show(parent, id, cond, child_fn, ctx)
    }
    @luna.For(render=render_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_for(parent, id, render_fn, ctx)
    }
    @luna.Component(render=render_fn) =>
      experimental_hydrate_node(parent, render_fn(), ctx)
    @luna.Island(island) =>
      // Island hydration is handled by the loader, just hydrate children
      for child in island.children {
        experimental_hydrate_node(parent, child, ctx)
      }
    @luna.WcIsland(wc_island) =>
      // WcIsland hydration is handled by wcssr client runtime, just hydrate children
      for child in wc_island.children {
        experimental_hydrate_node(parent, child, ctx)
      }
    @luna.InternalRef(iref) =>
      // InternalRef hydration is handled by the loader, just hydrate children
      for child in iref.children {
        experimental_hydrate_node(parent, child, ctx)
      }
    @luna.Async(async_node) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_node(parent, (async_node.fallback)(), ctx)
    }
    @luna.ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      experimental_hydrate_node(parent, (boundary.children)(), ctx) catch {
        err => {
          let reset = fn() { () }
          experimental_hydrate_node(
            parent,
            (boundary.fallback)(err, reset),
            ctx,
          ) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    @luna.Switch(switch_node) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      // Find first matching case and hydrate it
      for case_ in switch_node.cases {
        if (case_.when)() {
          experimental_hydrate_node(parent, (case_.render)(), ctx)
          return
        }
      }
      // No case matched, hydrate fallback if present
      match switch_node.fallback {
        Some(fallback_fn) =>
          experimental_hydrate_node(parent, fallback_fn(), ctx)
        None => ()
      }
    }
  }
}

///|
/// Hydrate static text, repairing if content differs
fn experimental_hydrate_text(
  parent : @js_dom.Node,
  expected : String,
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push("#text")
  // Find first text node child
  let children = parent.childNodes()
  for child in children {
    if child.nodeType() == 3 { // Text node
      let actual = get_text_content(child)
      if actual != expected {
        log_repair_detailed(
          ctx,
          TextMismatch,
          "Text content mismatch: expected '" +
          expected +
          "', got '" +
          actual +
          "'",
          expected,
          actual,
        )
        child.setTextContent(expected)
      }
      let _ = ctx.path_stack.pop()
      return
    }
  }
  // No text node found, create one
  log_repair_detailed(
    ctx,
    TextMissing,
    "Missing text node, creating: '" + expected + "'",
    expected,
    "",
  )
  let doc = @js_dom.document()
  let text_node = doc.createTextNode(expected)
  parent.appendChild(text_node.as_node()) |> ignore
  let _ = ctx.path_stack.pop()

}

///|
/// Hydrate dynamic text with markers
fn experimental_hydrate_dynamic_text(
  parent : @js_dom.Node,
  id : Int,
  getter : () -> String,
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push("#dynamic-text:" + id.to_string())
  let marker_start = "t:" + id.to_string()
  let children = parent.childNodes()

  // Look for existing marker
  for child in children {
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        // Found marker, check/create text node
        match child.nextSibling() {
          Some(text_node) =>
            if text_node.nodeType() == 3 {
              // Set up effect
              let _ = @signal.effect(fn() {
                let new_text = getter()
                text_node.setTextContent(new_text)
              })
              let _ = ctx.path_stack.pop()
              return
            }
          None => ()
        }
        // Text node missing after marker, create it
        log_repair_detailed(
          ctx,
          TextMissing,
          "Missing text node after marker t:" + id.to_string(),
          "text node",
          "none",
        )
        let doc = @js_dom.document()
        let new_text = doc.createTextNode(getter())
        match child.nextSibling() {
          Some(sibling) =>
            parent.insertBefore(new_text.as_node(), Some(sibling)) |> ignore
          None => parent.appendChild(new_text.as_node()) |> ignore
        }
        let text_ref = new_text.as_node()
        let _ = @signal.effect(fn() { text_ref.setTextContent(getter()) })
        let _ = ctx.path_stack.pop()
        return
      }
    }
  }

  // No marker found, create marker and text node
  log_repair_detailed(
    ctx,
    DynamicTextMarkerMissing,
    "Missing dynamic text marker t:" + id.to_string(),
    "<!--t:" + id.to_string() + "-->",
    "",
  )
  let doc = @js_dom.document()
  let start_comment = doc.createComment(marker_start)
  let text_node = doc.createTextNode(getter())
  let end_comment = doc.createComment("/t")
  parent.appendChild(start_comment) |> ignore
  parent.appendChild(text_node.as_node()) |> ignore
  parent.appendChild(end_comment) |> ignore
  let text_ref = text_node.as_node()
  let _ = @signal.effect(fn() { text_ref.setTextContent(getter()) })
  let _ = ctx.path_stack.pop()

}

///|
/// Hydrate an element, repairing structure if needed
fn experimental_hydrate_element(
  parent : @js_dom.Node,
  elem : @luna.VElement[@js.Any],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push(elem.tag)
  let needs_hydration = @luna.has_dynamic_content(elem.attrs)
  let dom_elem : @js_dom.Element = if needs_hydration {
    let id = ctx.current_id
    ctx.current_id = id + 1

    // Try to find by sol:hk using cached lookup (O(1))
    match find_element_by_hk_cached(ctx, id) {
      Some(found_elem) => {
        // Verify tag
        let dom_tag = found_elem.tagName().to_lower()
        if dom_tag != elem.tag {
          log_repair_detailed(
            ctx,
            TagMismatch,
            "Tag mismatch at hk=" +
            id.to_string() +
            ": expected <" +
            elem.tag +
            ">, got <" +
            dom_tag +
            ">, replacing",
            elem.tag,
            dom_tag,
          )
          // Replace element
          let new_elem = create_element_from_velem(elem, id)
          match found_elem.as_node().parentNode() {
            Some(p) =>
              p.replaceChild(new_elem.as_node(), found_elem.as_node()) |> ignore
            None => ()
          }
          new_elem
        } else {
          // Repair attributes
          repair_attributes(found_elem, elem.attrs, ctx)
          found_elem
        }
      }
      None => {
        // Element missing, create it
        log_repair_detailed(
          ctx,
          ElementMissing,
          "Missing element <" +
          elem.tag +
          "> with hk=" +
          id.to_string() +
          ", creating",
          "<" + elem.tag + " sol:hk=\"" + id.to_string() + "\">",
          "",
        )
        let new_elem = create_element_from_velem(elem, id)
        parent.appendChild(new_elem.as_node()) |> ignore
        new_elem
      }
    }
  } else {
    // Static element, find by tag
    match find_child_element_by_tag(parent, elem.tag) {
      Some(found_elem) => {
        repair_attributes(found_elem, elem.attrs, ctx)
        found_elem
      }
      None => {
        log_repair_detailed(
          ctx,
          ElementMissing,
          "Missing static element <" + elem.tag + ">, creating",
          "<" + elem.tag + ">",
          "",
        )
        let new_elem = create_element_from_velem(elem, -1)
        parent.appendChild(new_elem.as_node()) |> ignore
        new_elem
      }
    }
  }

  // Hydrate children
  for child in elem.children {
    experimental_hydrate_node(dom_elem.as_node(), child, ctx)
  }
  let _ = ctx.path_stack.pop()

}

///|
/// Create a DOM element from VElement
fn create_element_from_velem(
  elem : @luna.VElement[@js.Any],
  hk_id : Int,
) -> @js_dom.Element {
  let doc = @js_dom.document()
  let dom_elem = doc.createElement(elem.tag)

  // Add hydration key if needed
  if hk_id >= 0 {
    dom_elem.setAttribute("sol:hk", hk_id.to_string())
  }

  // Apply attributes
  for attr in elem.attrs {
    let (name, value) = attr
    apply_vattr(dom_elem, name, value)
  }

  // Recursively create children
  for child in elem.children {
    let child_dom = @client.render_vnode_to_dom(child)
    dom_elem.as_node().appendChild(child_dom) |> ignore
  }
  dom_elem
}

///|
/// Repair element attributes to match expected VDOM
fn repair_attributes(
  elem : @js_dom.Element,
  attrs : Array[(String, @luna.Attr[@js.Any])],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      @luna.VStatic(expected) => {
        // Check if attribute matches
        let actual = elem.getAttribute(name).unwrap_or("")
        if actual != expected && expected != "__remove__" {
          log_repair_detailed(
            ctx,
            AttributeMismatch,
            "Attribute mismatch on <" +
            elem.tagName().to_lower() +
            "> " +
            name +
            ": expected '" +
            expected +
            "', got '" +
            actual +
            "'",
            expected,
            actual,
          )
          if name == "class" || name == "className" {
            elem.setClassName(expected)
          } else if name == "value" {
            elem.as_any()._set("value", @js.any(expected)) |> ignore
          } else {
            elem.setAttribute(name, expected)
          }
        }
      }
      @luna.VDynamic(getter) => {
        // Set up effect for dynamic attribute
        let _ = @signal.effect(fn() {
          let new_value = getter()
          if new_value == "__remove__" {
            elem.removeAttribute(name)
          } else if name == "class" || name == "className" {
            elem.setClassName(new_value)
          } else if name == "value" {
            elem.as_any()._set("value", @js.any(new_value)) |> ignore
          } else {
            elem.setAttribute(name, new_value)
          }
        })

      }
      @luna.VHandler(handler) => {
        // Attach event handler
        let event_name = extract_event_name(name)
        let callback = handler.get_callback()
        // Wrap callback to ignore event argument
        let wrapper : (@js.Any) -> Unit = fn(event) { callback(event) }
        elem
        .as_event_target()
        .addEventListener(event_name, @js.any(wrapper).cast())
      }
      @luna.VAction(_) =>
        // VAction without dispatcher - skip in repair
        ()
    }
  }
}

///|
/// Hydrate Show node with repair
fn experimental_hydrate_show(
  parent : @js_dom.Node,
  id : Int,
  cond : () -> Bool,
  child_fn : () -> @luna.Node[@js.Any],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push("#show:" + id.to_string())
  let marker_start = "s:" + id.to_string()

  // Find or create markers
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None
  for child in children {
    if child.nodeType() == 8 {
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        start_marker = Some(child)
      } else if comment_text == "/s" {
        match start_marker {
          Some(_) => {
            end_marker = Some(child)
            break
          }
          None => ()
        }
      }
    }
  }

  // Create markers if missing
  let doc = @js_dom.document()
  let (start, end) = match (start_marker, end_marker) {
    (Some(s), Some(e)) => (s, e)
    _ => {
      log_repair_detailed(
        ctx,
        ShowMarkerMissing,
        "Missing show markers s:" + id.to_string() + ", creating",
        "<!--s:" + id.to_string() + "-->...<!--/s-->",
        "",
      )
      let new_start = doc.createComment(marker_start)
      let new_end = doc.createComment("/s")
      parent.appendChild(new_start) |> ignore
      parent.appendChild(new_end) |> ignore
      (new_start, new_end)
    }
  }

  // Collect current content
  let current_nodes : Array[@js_dom.Node] = []
  let mut sibling = start.nextSibling()
  while true {
    match sibling {
      Some(node) => {
        if node.nodeType() == 8 {
          let text = get_text_content(node)
          if text == "/s" {
            break
          }
        }
        current_nodes.push(node)
        sibling = node.nextSibling()
      }
      None => break
    }
  }

  // Initial render if needed
  if cond() && current_nodes.is_empty() {
    log_repair_detailed(
      ctx,
      ShowContentMissing,
      "Show condition true but content missing, rendering",
      "content",
      "",
    )
    let child_node = @client.render_vnode_to_dom(child_fn())
    parent.insertBefore(child_node, Some(end)) |> ignore
    current_nodes.push(child_node)
  } else if cond() {
    // Hydrate existing content
    experimental_hydrate_node(parent, child_fn(), ctx)
  }

  // Set up effect for updates
  let _ = @signal.effect(fn() {
    let should_show = cond()
    if should_show && current_nodes.is_empty() {
      let child_node = @client.render_vnode_to_dom(child_fn())
      parent.insertBefore(child_node, Some(end)) |> ignore
      current_nodes.push(child_node)
    } else if not(should_show) && not(current_nodes.is_empty()) {
      for node in current_nodes {
        parent.removeChild(node) |> ignore
      }
      current_nodes.clear()
    }
  })
  let _ = ctx.path_stack.pop()

}

///|
/// Hydrate For node with repair
fn experimental_hydrate_for(
  parent : @js_dom.Node,
  id : Int,
  render_fn : () -> Array[@luna.Node[@js.Any]],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push("#for:" + id.to_string())
  let marker_start = "f:" + id.to_string()

  // Find or create markers
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None
  for child in children {
    if child.nodeType() == 8 {
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        start_marker = Some(child)
      } else if comment_text == "/f" {
        match start_marker {
          Some(_) => {
            end_marker = Some(child)
            break
          }
          None => ()
        }
      }
    }
  }

  // Create markers if missing
  let doc = @js_dom.document()
  let (start, end) = match (start_marker, end_marker) {
    (Some(s), Some(e)) => (s, e)
    _ => {
      log_repair_detailed(
        ctx,
        ForMarkerMissing,
        "Missing for markers f:" + id.to_string() + ", creating",
        "<!--f:" + id.to_string() + "-->...<!--/f-->",
        "",
      )
      let new_start = doc.createComment(marker_start)
      let new_end = doc.createComment("/f")
      parent.appendChild(new_start) |> ignore
      parent.appendChild(new_end) |> ignore
      (new_start, new_end)
    }
  }

  // Collect current nodes
  let current_nodes : Array[@js_dom.Node] = []
  let mut sibling = start.nextSibling()
  while true {
    match sibling {
      Some(node) => {
        if node.nodeType() == 8 {
          let text = get_text_content(node)
          if text == "/f" {
            break
          }
        }
        current_nodes.push(node)
        sibling = node.nextSibling()
      }
      None => break
    }
  }

  // Initial reconciliation
  let items = render_fn()
  let item_count = items.length()
  let node_count = current_nodes.length()
  if item_count != node_count {
    log_repair_detailed(
      ctx,
      ForItemCountMismatch,
      "For item count mismatch: expected " +
      item_count.to_string() +
      ", got " +
      node_count.to_string() +
      " nodes",
      item_count.to_string(),
      node_count.to_string(),
    )
  }

  // Hydrate what we can, then add/remove as needed
  let min_count = if item_count < node_count { item_count } else { node_count }
  for i = 0; i < min_count; i = i + 1 {
    // For text nodes and simple nodes, we can't hydrate into them as children
    // Instead, we replace them with the new rendered vnode
    let current_node = current_nodes[i]
    if current_node.nodeType() == 3 { // Text node - just update content
      match items[i] {
        @luna.Text(content) => current_node.setTextContent(content)
        @luna.DynamicText(getter) => {
          current_node.setTextContent(getter())
          let node_ref = current_node
          let _ = @signal.effect(fn() { node_ref.setTextContent(getter()) })

        }
        _ => {
          // Replace text node with element
          let new_node = @client.render_vnode_to_dom(items[i])
          parent.replaceChild(new_node, current_node) |> ignore
          current_nodes[i] = new_node
        }
      }
    } else if current_node.nodeType() == 1 { // Element node
      experimental_hydrate_node(current_node, items[i], ctx)
    } else {
      // For other node types, just replace
      let new_node = @client.render_vnode_to_dom(items[i])
      parent.replaceChild(new_node, current_node) |> ignore
      current_nodes[i] = new_node
    }
  }

  // Add missing items
  for i = min_count; i < item_count; i = i + 1 {
    let new_node = @client.render_vnode_to_dom(items[i])
    parent.insertBefore(new_node, Some(end)) |> ignore
    current_nodes.push(new_node)
  }

  // Remove extra nodes
  for i = min_count; i < node_count; i = i + 1 {
    parent.removeChild(current_nodes[i]) |> ignore
  }
  // Trim array to item_count
  while current_nodes.length() > item_count {
    let _ = current_nodes.pop()

  }

  // Set up effect for future updates
  let _ = @signal.effect(fn() {
    let new_items = render_fn()

    // Simple reconciliation: clear and re-render
    for node in current_nodes {
      parent.removeChild(node) |> ignore
    }
    current_nodes.clear()
    for item in new_items {
      let new_node = @client.render_vnode_to_dom(item)
      parent.insertBefore(new_node, Some(end)) |> ignore
      current_nodes.push(new_node)
    }
  })
  let _ = ctx.path_stack.pop()

}

///|
/// Create a failed hydration result
/// Used for constructing Failed variant in error scenarios
pub fn hydration_failed(message : String) -> ExperimentalHydrationResult {
  Failed(message)
}

///|
/// Convenience function: Try regular hydration first, fall back to experimental
pub fn hydrate_with_fallback(
  container : @js_dom.Element,
  node : @luna.Node[@js.Any],
  logger? : StringBuilder,
) -> @client.HydrationResult {
  // First try regular hydration
  let result = @client.hydrate(
    container,
    node,
    recover_on_mismatch=false,
    warn_on_mismatch=false,
  )

  // Check result using helper method and handle accordingly
  if result.is_success() {
    @client.hydration_result_success()
  } else if result.is_recovered() {
    @client.hydration_result_recovered(result.get_message())
  } else {
    // Mismatch - fall back to experimental hydration
    let msg = result.get_message()
    match logger {
      Some(sb) => {
        sb.write_string("[Hydration] Regular hydration failed: " + msg + "\n")
        sb.write_string("[Hydration] Falling back to experimental hydration\n")
      }
      None => {
        let global = @global.global_this()
        let console = global["console"]
        console._call("warn", [
          @js.any("[Hydration] Regular hydration failed: " + msg),
        ])
        |> ignore
        console._call("warn", [
          @js.any("[Hydration] Falling back to experimental hydration"),
        ])
        |> ignore
      }
    }

    // Clear and re-render with experimental hydration
    container.as_node().setTextContent("")
    let dom_node = @client.render_vnode_to_dom(node)
    container.as_node().appendChild(dom_node) |> ignore
    let exp_result = experimental_hydrate(container, node, logger?)
    match exp_result {
      Clean =>
        @client.hydration_result_recovered(
          "Experimental hydration succeeded cleanly",
        )
      Repaired(repairs) =>
        @client.hydration_result_recovered(
          "Experimental hydration repaired " +
          repairs.length().to_string() +
          " issues",
        )
      Failed(err) =>
        @client.hydration_result_mismatch(
          "Experimental hydration failed: " + err,
        )
    }
  }
}
