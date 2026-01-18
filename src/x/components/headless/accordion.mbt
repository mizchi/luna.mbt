///|
/// Headless Accordion Component
///
/// Provides accessibility (ARIA) and behavior without DOM structure or styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/accordion/

///|
/// Accordion header props
pub(all) struct AccordionHeaderProps {
  attrs : Array[(String, @luna.Attr[@js.Any])]
  toggle : () -> Unit
  is_expanded : Bool
}

///|
/// Create headless accordion header.
pub fn use_accordion_header(
  id : String,
  controls : String,
  expanded : @resource.Signal[Bool],
  index : Int,
  on_expand : (Int) -> Unit,
) -> AccordionHeaderProps {
  let is_expanded = expanded.get()
  let aria_attrs = @aria.accordion_header_aria(id, is_expanded, controls)
  let attrs : Array[(String, @luna.Attr[@js.Any])] = aria_attrs.map(fn(pair) {
    (pair.0, @luna.attr_static(pair.1))
  })

  // Update aria-expanded dynamically
  attrs.push(
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
  )
  let toggle = fn() { on_expand(index) }
  attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))))
  attrs.push(
    (
      "keydown",
      @luna.attr_handler(
        @luna.handler(fn(evt) {
          let key = get_event_key(evt)
          if @aria.is_toggle_key(key) {
            prevent_default(evt)
            toggle()
          }
        }),
      ),
    ),
  )
  { attrs, toggle, is_expanded }
}

///|
/// Accordion header attrs only (static version).
pub fn[E] accordion_header_attrs(
  id : String,
  controls : String,
  expanded : Bool,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = @aria.accordion_header_aria(id, expanded, controls)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Accordion panel attrs.
pub fn[E] accordion_panel_attrs(
  id : String,
  labelledby : String,
  hidden : Bool,
  use_region : Bool,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = @aria.accordion_panel_aria(
    id, labelledby, hidden, use_region,
  )
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

// Helper: Focus an accordion header by ID

///|
fn focus_accordion_header(header_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(header_id)])
  let _ = el._call("focus", [])

}

///|
/// Create keyboard handler for accordion navigation.
///
/// Keyboard:
/// - ArrowDown: Move focus to next header (no wrap)
/// - ArrowUp: Move focus to previous header (no wrap)
/// - Home: Move focus to first header
/// - End: Move focus to last header
pub fn make_accordion_keydown_handler(
  header_ids : Array[String],
  index : Int,
  count : Int,
  _expanded : @resource.Signal[Int],
  toggle : () -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(evt) {
    let key = evt._get("key").to_string()
    match key {
      " " | "Enter" => {
        let _ = evt._call("preventDefault", [])
        toggle()
      }
      "ArrowDown" => {
        let _ = evt._call("preventDefault", [])
        // Move to next header (no wrap)
        if index < count - 1 {
          focus_accordion_header(header_ids[index + 1])
        }
      }
      "ArrowUp" => {
        let _ = evt._call("preventDefault", [])
        // Move to previous header (no wrap)
        if index > 0 {
          focus_accordion_header(header_ids[index - 1])
        }
      }
      "Home" => {
        let _ = evt._call("preventDefault", [])
        focus_accordion_header(header_ids[0])
      }
      "End" => {
        let _ = evt._call("preventDefault", [])
        focus_accordion_header(header_ids[count - 1])
      }
      _ => ()
    }
  })
}

///|
/// Generate accordion header and panel IDs.
pub fn generate_accordion_ids(
  items_count : Int,
  prefix : String,
) -> (Array[String], Array[String]) {
  let header_ids : Array[String] = []
  let panel_ids : Array[String] = []
  for i = 0; i < items_count; i = i + 1 {
    header_ids.push(prefix + "-header-" + i.to_string())
    panel_ids.push(prefix + "-panel-" + i.to_string())
  }
  (header_ids, panel_ids)
}

///|
/// Props for accordion header with full APG keyboard navigation.
pub(all) struct AccordionHeaderNavProps {
  attrs : Array[(String, @luna.Attr[@js.Any])]
  is_expanded : Bool
}

///|
/// Create accordion header props with navigation.
pub fn use_accordion_header_nav(
  header_id : String,
  panel_id : String,
  header_ids : Array[String],
  index : Int,
  expanded : @resource.Signal[Int],
) -> AccordionHeaderNavProps {
  let count = header_ids.length()
  let is_expanded = expanded.get() == index
  let toggle = fn() {
    if expanded.get() == index {
      expanded.set(-1)
    } else {
      expanded.set(index)
    }
  }
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(header_id)),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() {
        if expanded.get() == index {
          "true"
        } else {
          "false"
        }
      }),
    ),
    ("aria-controls", @luna.attr_static(panel_id)),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))),
    (
      "keydown",
      @luna.attr_handler(
        make_accordion_keydown_handler(
          header_ids, index, count, expanded, toggle,
        ),
      ),
    ),
  ]
  { attrs, is_expanded }
}

///|
/// Props for accordion panel.
pub(all) struct AccordionPanelNavProps {
  attrs : Array[(String, @luna.Attr[@js.Any])]
  is_expanded : Bool
}

///|
/// Create accordion panel props.
pub fn use_accordion_panel_nav(
  panel_id : String,
  header_id : String,
  index : Int,
  expanded : @resource.Signal[Int],
) -> AccordionPanelNavProps {
  let is_expanded = expanded.get() == index
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("id", @luna.attr_static(panel_id)),
    ("aria-labelledby", @luna.attr_static(header_id)),
    ("role", @luna.attr_static("region")),
    (
      "aria-hidden",
      @luna.attr_dynamic(fn() {
        if expanded.get() == index {
          "false"
        } else {
          "true"
        }
      }),
    ),
  ]
  { attrs, is_expanded }
}
