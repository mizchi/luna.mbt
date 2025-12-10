///| Experimental Hydration - Morphdom-like DOM diffing/patching during hydration
///|
///| This module provides resilient hydration that can repair mismatches between
///| server-rendered HTML and the expected VDOM structure, similar to morphdom.
///| Use this as a fallback when regular hydration fails.
///|
///| NOTE: This is an experimental module. The API may change in future versions.

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
}

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
  let result : Array[RepairInfo] = []
  for repair in self.repairs {
    if repair_type_eq(repair.repair_type, repair_type) {
      result.push(repair)
    }
  }
  result
}

///|
/// Check if report has any repair of given type
pub fn ExperimentalHydrationReport::has_repair_type(
  self : ExperimentalHydrationReport,
  repair_type : RepairType,
) -> Bool {
  for repair in self.repairs {
    if repair_type_eq(repair.repair_type, repair_type) {
      return true
    }
  }
  false
}

///|
/// Helper to compare RepairType
fn repair_type_eq(a : RepairType, b : RepairType) -> Bool {
  match (a, b) {
    (TextMismatch, TextMismatch) => true
    (TextMissing, TextMissing) => true
    (ElementMissing, ElementMissing) => true
    (TagMismatch, TagMismatch) => true
    (AttributeMismatch, AttributeMismatch) => true
    (DynamicTextMarkerMissing, DynamicTextMarkerMissing) => true
    (ShowMarkerMissing, ShowMarkerMissing) => true
    (ForMarkerMissing, ForMarkerMissing) => true
    (ForItemCountMismatch, ForItemCountMismatch) => true
    (ShowContentMissing, ShowContentMissing) => true
    _ => false
  }
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
  /// Hydration failed completely
  Failed(String)
}

///|
/// Context for experimental hydration
priv struct ExperimentalHydrationContext {
  container : @js_dom.Element
  mut current_id : Int
  repairs : Array[String]
  repair_infos : Array[RepairInfo]
  logger : StringBuilder?
  path_stack : Array[String]
}

///|
/// Get current node path from stack
fn get_current_path(ctx : ExperimentalHydrationContext) -> String {
  if ctx.path_stack.is_empty() {
    "root"
  } else {
    ctx.path_stack.iter().fold(init="", fn(acc, part) {
      if acc == "" { part } else { acc + " > " + part }
    })
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
      console._call("log", [@core.any(full_msg)]) |> ignore
    }
  }
}

// =============================================================================
// Helper functions (local copies from hydrate.mbt for package isolation)
// =============================================================================

///|
/// Helper to get text content with default
fn get_text_content(node : @js_dom.Node) -> String {
  let data : @core.Any = node.as_any()._get("data")
  data.cast()
}

///|
/// Find element with data-hk="id" attribute within container
fn find_element_by_hk(
  container : @js_dom.Element,
  id : Int,
) -> @js_dom.Element? {
  let selector = "[data-hk=\"" + id.to_string() + "\"]"
  container.querySelector(selector)
}

///|
/// Find first child element with matching tag name
fn find_child_element_by_tag(
  parent : @js_dom.Node,
  tag : String,
) -> @js_dom.Element? {
  let children = parent.childNodes()
  let upper_tag = tag.to_upper()
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
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
fn apply_vattr(elem : @js_dom.Element, name : String, value : @ui.Attr) -> Unit {
  match value {
    @ui.VStatic(s) =>
      if s != "__remove__" {
        if name == "class" || name == "className" {
          elem.setClassName(s)
        } else if name == "value" {
          elem.as_any()._set("value", @core.any(s)) |> ignore
        } else if s == "" {
          elem.setAttribute(name, "")
        } else {
          elem.setAttribute(name, s)
        }
      }
    @ui.VDynamic(getter) => {
      let _ = @ui.effect(fn() {
        let new_value = getter()
        if new_value == "__remove__" {
          elem.removeAttribute(name)
        } else if name == "class" || name == "className" {
          elem.setClassName(new_value)
        } else if name == "value" {
          elem.as_any()._set("value", @core.any(new_value)) |> ignore
        } else {
          elem.setAttribute(name, new_value)
        }
      })
    }
    @ui.VHandler(handler) => {
      let event_name = extract_event_name(name)
      let handler_any : @core.Any = @core.any(handler)
      elem.as_event_target().addEventListener(event_name, handler_any.cast())
    }
    @ui.VStyle(styles) => {
      let style_prop : @core.Any = elem.as_any()._get("style")
      for style in styles {
        let (prop, val) = style
        style_prop._set(prop, @core.any(val)) |> ignore
      }
    }
    @ui.VDynamicStyle(getter) => {
      let _ = @ui.effect(fn() {
        let styles = getter()
        let style_prop : @core.Any = elem.as_any()._get("style")
        for style in styles {
          let (prop, val) = style
          style_prop._set(prop, @core.any(val)) |> ignore
        }
      })
    }
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
  node : @ui.Node,
  logger? : StringBuilder,
) -> ExperimentalHydrationResult {
  let ctx : ExperimentalHydrationContext = {
    container,
    current_id: 0,
    repairs: [],
    repair_infos: [],
    logger,
    path_stack: [],
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
/// Experimental hydration with detailed report.
/// Returns a detailed report including repair types, node paths, and expected/actual values.
pub fn experimental_hydrate_with_report(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> ExperimentalHydrationReport {
  let ctx : ExperimentalHydrationContext = {
    container,
    current_id: 0,
    repairs: [],
    repair_infos: [],
    logger,
    path_stack: [],
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
  node : @ui.Node,
  ctx : ExperimentalHydrationContext,
) -> Unit {
  match node {
    @ui.Text(content) => experimental_hydrate_text(parent, content, ctx)
    @ui.DynamicText(getter) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_dynamic_text(parent, id, getter, ctx)
    }
    @ui.Fragment(children) =>
      for i = 0; i < children.length(); i = i + 1 {
        experimental_hydrate_node(parent, children[i], ctx)
      }
    @ui.Element(elem) => experimental_hydrate_element(parent, elem, ctx)
    @ui.Show(condition=cond, child=child_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_show(parent, id, cond, child_fn, ctx)
    }
    @ui.For(render=render_fn) => {
      let id = ctx.current_id
      ctx.current_id = id + 1
      experimental_hydrate_for(parent, id, render_fn, ctx)
    }
    @ui.Component(render=render_fn) =>
      experimental_hydrate_node(parent, render_fn(), ctx)
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
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
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
  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
    if child.nodeType() == 8 { // Comment node
      let comment_text = get_text_content(child)
      if comment_text == marker_start {
        // Found marker, check/create text node
        match child.nextSibling() {
          Some(text_node) =>
            if text_node.nodeType() == 3 {
              // Set up effect
              let _ = @ui.effect(fn() {
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
        let _ = @ui.effect(fn() { text_ref.setTextContent(getter()) })
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
  let _ = @ui.effect(fn() { text_ref.setTextContent(getter()) })
  let _ = ctx.path_stack.pop()
}

///|
/// Hydrate an element, repairing structure if needed
fn experimental_hydrate_element(
  parent : @js_dom.Node,
  elem : @ui.VElement,
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push(elem.tag)
  let needs_hydration = @ui.has_dynamic_content(elem.attrs)

  let dom_elem : @js_dom.Element = if needs_hydration {
    let id = ctx.current_id
    ctx.current_id = id + 1

    // Try to find by data-hk
    match find_element_by_hk(ctx.container, id) {
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
            Some(p) => {
              p.replaceChild(new_elem.as_node(), found_elem.as_node()) |> ignore
            }
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
          "<" + elem.tag + " data-hk=\"" + id.to_string() + "\">",
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
  for i = 0; i < elem.children.length(); i = i + 1 {
    experimental_hydrate_node(dom_elem.as_node(), elem.children[i], ctx)
  }
  let _ = ctx.path_stack.pop()
}

///|
/// Create a DOM element from VElement
fn create_element_from_velem(elem : @ui.VElement, hk_id : Int) -> @js_dom.Element {
  let doc = @js_dom.document()
  let dom_elem = doc.createElement(elem.tag)

  // Add hydration key if needed
  if hk_id >= 0 {
    dom_elem.setAttribute("data-hk", hk_id.to_string())
  }

  // Apply attributes
  for i = 0; i < elem.attrs.length(); i = i + 1 {
    let (name, value) = elem.attrs[i]
    apply_vattr(dom_elem, name, value)
  }

  // Recursively create children
  for i = 0; i < elem.children.length(); i = i + 1 {
    let child_dom = @dom.render_vnode_to_dom(elem.children[i])
    dom_elem.as_node().appendChild(child_dom) |> ignore
  }

  dom_elem
}

///|
/// Repair element attributes to match expected VDOM
fn repair_attributes(
  elem : @js_dom.Element,
  attrs : Array[(String, @ui.Attr)],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  for i = 0; i < attrs.length(); i = i + 1 {
    let (name, value) = attrs[i]
    match value {
      @ui.VStatic(expected) => {
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
            elem.as_any()._set("value", @core.any(expected)) |> ignore
          } else {
            elem.setAttribute(name, expected)
          }
        }
      }
      @ui.VDynamic(getter) => {
        // Set up effect for dynamic attribute
        let _ = @ui.effect(fn() {
          let new_value = getter()
          if new_value == "__remove__" {
            elem.removeAttribute(name)
          } else if name == "class" || name == "className" {
            elem.setClassName(new_value)
          } else if name == "value" {
            elem.as_any()._set("value", @core.any(new_value)) |> ignore
          } else {
            elem.setAttribute(name, new_value)
          }
        })
      }
      @ui.VHandler(handler) => {
        // Attach event handler
        let event_name = extract_event_name(name)
        let handler_any : @core.Any = @core.any(handler)
        elem.as_event_target().addEventListener(event_name, handler_any.cast())
      }
      @ui.VStyle(styles) => {
        let style_prop : @core.Any = elem.as_any()._get("style")
        for j = 0; j < styles.length(); j = j + 1 {
          let (prop, val) = styles[j]
          style_prop._set(prop, @core.any(val)) |> ignore
        }
      }
      @ui.VDynamicStyle(getter) => {
        let _ = @ui.effect(fn() {
          let styles = getter()
          let style_prop : @core.Any = elem.as_any()._get("style")
          for j = 0; j < styles.length(); j = j + 1 {
            let (prop, val) = styles[j]
            style_prop._set(prop, @core.any(val)) |> ignore
          }
        })
      }
    }
  }
}

///|
/// Hydrate Show node with repair
fn experimental_hydrate_show(
  parent : @js_dom.Node,
  id : Int,
  cond : () -> Bool,
  child_fn : () -> @ui.Node,
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push("#show:" + id.to_string())
  let marker_start = "s:" + id.to_string()

  // Find or create markers
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None

  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
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
    let child_node = @dom.render_vnode_to_dom(child_fn())
    parent.insertBefore(child_node, Some(end)) |> ignore
    current_nodes.push(child_node)
  } else if cond() {
    // Hydrate existing content
    experimental_hydrate_node(parent, child_fn(), ctx)
  }

  // Set up effect for updates
  let _ = @ui.effect(fn() {
    let should_show = cond()
    if should_show && current_nodes.is_empty() {
      let child_node = @dom.render_vnode_to_dom(child_fn())
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
  render_fn : () -> Array[@ui.Node],
  ctx : ExperimentalHydrationContext,
) -> Unit {
  ctx.path_stack.push("#for:" + id.to_string())
  let marker_start = "f:" + id.to_string()

  // Find or create markers
  let children = parent.childNodes()
  let mut start_marker : @js_dom.Node? = None
  let mut end_marker : @js_dom.Node? = None

  for i = 0; i < children.length(); i = i + 1 {
    let child = children[i]
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
        @ui.Text(content) => current_node.setTextContent(content)
        @ui.DynamicText(getter) => {
          current_node.setTextContent(getter())
          let node_ref = current_node
          let _ = @ui.effect(fn() { node_ref.setTextContent(getter()) })
        }
        _ => {
          // Replace text node with element
          let new_node = @dom.render_vnode_to_dom(items[i])
          parent.replaceChild(new_node, current_node) |> ignore
          current_nodes[i] = new_node
        }
      }
    } else if current_node.nodeType() == 1 { // Element node
      experimental_hydrate_node(current_node, items[i], ctx)
    } else {
      // For other node types, just replace
      let new_node = @dom.render_vnode_to_dom(items[i])
      parent.replaceChild(new_node, current_node) |> ignore
      current_nodes[i] = new_node
    }
  }

  // Add missing items
  for i = min_count; i < item_count; i = i + 1 {
    let new_node = @dom.render_vnode_to_dom(items[i])
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
  let _ = @ui.effect(fn() {
    let new_items = render_fn()

    // Simple reconciliation: clear and re-render
    for node in current_nodes {
      parent.removeChild(node) |> ignore
    }
    current_nodes.clear()
    for item in new_items {
      let new_node = @dom.render_vnode_to_dom(item)
      parent.insertBefore(new_node, Some(end)) |> ignore
      current_nodes.push(new_node)
    }
  })
  let _ = ctx.path_stack.pop()
}

///|
/// Convenience function: Try regular hydration first, fall back to experimental
pub fn hydrate_with_fallback(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> @dom.HydrationResult {
  // First try regular hydration
  let result = @dom.hydrate(
    container,
    node,
    recover_on_mismatch=false,
    warn_on_mismatch=false,
  )

  // Check result using helper method and handle accordingly
  if result.is_success() {
    @dom.hydration_result_success()
  } else if result.is_recovered() {
    @dom.hydration_result_recovered(result.get_message())
  } else {
    // Mismatch - fall back to experimental hydration
    let msg = result.get_message()
    match logger {
      Some(sb) => {
        sb.write_string(
          "[Hydration] Regular hydration failed: " + msg + "\n",
        )
        sb.write_string("[Hydration] Falling back to experimental hydration\n")
      }
      None => {
        let global = @global.global_this()
        let console = global["console"]
        console._call("warn", [
          @core.any("[Hydration] Regular hydration failed: " + msg),
        ])
        |> ignore
        console._call("warn", [
          @core.any("[Hydration] Falling back to experimental hydration"),
        ])
        |> ignore
      }
    }

    // Clear and re-render with experimental hydration
    container.as_node().setTextContent("")
    let dom_node = @dom.render_vnode_to_dom(node)
    container.as_node().appendChild(dom_node) |> ignore

    let exp_result = experimental_hydrate(container, node, logger?=logger)
    match exp_result {
      Clean => @dom.hydration_result_recovered("Experimental hydration succeeded cleanly")
      Repaired(repairs) =>
        @dom.hydration_result_recovered(
          "Experimental hydration repaired " +
          repairs.length().to_string() +
          " issues",
        )
      Failed(err) => @dom.hydration_result_mismatch("Experimental hydration failed: " + err)
    }
  }
}
