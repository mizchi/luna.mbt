///|
/// APG Accordion Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/accordion/
///
/// An accordion is a vertically stacked set of interactive headings
/// that each contain a title and can reveal or hide associated content.
///
/// Keyboard Interaction:
/// - Enter/Space: Expand/collapse the focused panel
/// - Tab: Move to next focusable element
/// - Down Arrow (optional): Move to next header
/// - Up Arrow (optional): Move to previous header
/// - Home (optional): Move to first header
/// - End (optional): Move to last header
///
/// ARIA:
/// - Heading with button inside (aria-expanded, aria-controls)
/// - Panel with role="region" and aria-labelledby (optional)

///|
/// Accordion item data
pub(all) struct AccordionItem[E] {
  id : String // Unique item ID
  heading : String // Header text
  level : Int // Heading level (1-6)
  content : Array[@luna.Node[E]] // Panel content
}

///|
/// Create an accordion item
pub fn[E] accordion_item(
  id : String,
  heading : String,
  level? : Int,
  content : Array[@luna.Node[E]],
) -> AccordionItem[E] {
  { id, heading, level: level.unwrap_or(3), content }
}

///|
/// Create an accordion header button.
///
/// Parameters:
/// - id: Button ID
/// - expanded: Whether the panel is expanded
/// - controls: ID of the controlled panel
/// - level: Heading level (1-6)
/// - on_click: Click handler to toggle
/// - on_keydown: Keydown handler (for arrow key navigation)
/// - children: Header content
pub fn[E] accordion_header(
  id : String,
  expanded : Bool,
  controls : String,
  level? : Int,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let heading_tag = "h" + level.unwrap_or(3).to_string()
  let button_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(id)),
    (
      "aria-expanded",
      @luna.attr_static(if expanded { "true" } else { "false" }),
    ),
    ("aria-controls", @luna.attr_static(controls)),
  ]
  if on_click is Some(handler) {
    button_attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    button_attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  let button = @luna.h("button", button_attrs, children)
  @luna.h(heading_tag, [], [button])
}

///|
/// Create a dynamic accordion header with signal-based expanded state.
pub fn[E] accordion_header_dyn(
  id : String,
  expanded : @resource.Signal[Bool],
  controls : String,
  level? : Int,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let heading_tag = "h" + level.unwrap_or(3).to_string()
  let button_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(id)),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(controls)),
  ]
  if on_click is Some(handler) {
    button_attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    button_attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  let button = @luna.h("button", button_attrs, children)
  @luna.h(heading_tag, [], [button])
}

///|
/// Create a dynamic accordion header with computed expanded state (accepts getter function).
/// Useful for derived accordion states.
pub fn[E] accordion_header_computed(
  id : String,
  expanded : () -> Bool,
  controls : String,
  level? : Int,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let heading_tag = "h" + level.unwrap_or(3).to_string()
  let button_attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(id)),
    ("aria-expanded", @luna.attr_dynamic(fn() { bool_to_aria(expanded()) })),
    ("aria-controls", @luna.attr_static(controls)),
  ]
  if on_click is Some(handler) {
    button_attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    button_attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  let button = @luna.h("button", button_attrs, children)
  @luna.h(heading_tag, [], [button])
}

///|
/// Create an accordion panel.
///
/// Parameters:
/// - id: Panel ID (referenced by header's aria-controls)
/// - labelledby: ID of the header button
/// - hidden: Whether the panel is hidden
/// - use_region: Whether to use role="region" (recommended for <= 6 panels)
/// - children: Panel content
pub fn[E] accordion_panel(
  id : String,
  labelledby : String,
  hidden : Bool,
  use_region? : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelledby)),
  ]
  if use_region is Some(true) {
    attrs.push(("role", @luna.attr_static("region")))
  }
  if hidden {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic accordion panel with signal-based visibility.
pub fn[E] accordion_panel_dyn(
  id : String,
  labelledby : String,
  visible : @resource.Signal[Bool],
  use_region? : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelledby)),
  ]
  if use_region is Some(true) {
    attrs.push(("role", @luna.attr_static("region")))
  }
  @luna.show(fn() { visible.get() }, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create a accordion panel with computed visibility (accepts getter function).
pub fn[E] accordion_panel_computed(
  id : String,
  labelledby : String,
  visible : () -> Bool,
  use_region? : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelledby)),
  ]
  if use_region is Some(true) {
    attrs.push(("role", @luna.attr_static("region")))
  }
  @luna.show(visible, fn() { @luna.h("div", attrs, children) })
}

///|
/// Build a complete accordion from items.
/// Only one panel can be expanded at a time (single-select mode).
///
/// Parameters:
/// - items: Array of AccordionItem
/// - expanded_index: Index of currently expanded item (-1 for all collapsed)
/// - use_regions: Whether to add role="region" to panels
pub fn[E] accordion(
  items : Array[AccordionItem[E]],
  expanded_index : Int,
  use_regions? : Bool,
) -> @luna.Node[E] {
  let use_reg = use_regions.unwrap_or(items.length() <= 6)
  let children : Array[@luna.Node[E]] = []
  for i, item in items {
    let is_expanded = i == expanded_index
    let header_id = "accordion-header-" + item.id
    let panel_id = "accordion-panel-" + item.id
    children.push(
      accordion_header(header_id, is_expanded, panel_id, level=item.level, [
        @luna.text(item.heading),
      ]),
    )
    children.push(
      accordion_panel(
        panel_id,
        header_id,
        not(is_expanded),
        use_region=use_reg,
        item.content,
      ),
    )
  }
  @luna.h("div", [("data-accordion", @luna.attr_static(""))], children)
}

///|
/// Build a multi-select accordion where multiple panels can be open.
///
/// Parameters:
/// - items: Array of AccordionItem
/// - expanded_ids: Array of expanded item IDs
/// - use_regions: Whether to add role="region" to panels
pub fn[E] accordion_multi(
  items : Array[AccordionItem[E]],
  expanded_ids : Array[String],
  use_regions? : Bool,
) -> @luna.Node[E] {
  let use_reg = use_regions.unwrap_or(items.length() <= 6)
  let children : Array[@luna.Node[E]] = []
  for item in items {
    let is_expanded = expanded_ids.contains(item.id)
    let header_id = "accordion-header-" + item.id
    let panel_id = "accordion-panel-" + item.id
    children.push(
      accordion_header(header_id, is_expanded, panel_id, level=item.level, [
        @luna.text(item.heading),
      ]),
    )
    children.push(
      accordion_panel(
        panel_id,
        header_id,
        not(is_expanded),
        use_region=use_reg,
        item.content,
      ),
    )
  }
  @luna.h("div", [("data-accordion", @luna.attr_static("multi"))], children)
}

///|
/// Build a dynamic accordion with signal-based expanded index.
/// This is the recommended way to create accordions with reactive state.
///
/// Parameters:
/// - items: Array of AccordionItem
/// - expanded_index: Signal containing the currently expanded item index (-1 for all collapsed)
/// - use_regions: Whether to add role="region" to panels
pub fn[E] accordion_dyn(
  items : Array[AccordionItem[E]],
  expanded_index : @resource.Signal[Int],
  use_regions? : Bool,
) -> @luna.Node[E] {
  let use_reg = use_regions.unwrap_or(items.length() <= 6)
  let children : Array[@luna.Node[E]] = []
  for i, item in items {
    let index = i // capture index
    let header_id = "accordion-header-" + item.id
    let panel_id = "accordion-panel-" + item.id
    children.push(
      accordion_header_computed(
        header_id,
        fn() { expanded_index.get() == index },
        panel_id,
        level=item.level,
        on_click=@luna.handler(fn(_) {
          if expanded_index.get() == index {
            expanded_index.set(-1)
          } else {
            expanded_index.set(index)
          }
        }),
        [@luna.text(item.heading)],
      ),
    )
    children.push(
      accordion_panel_computed(
        panel_id,
        header_id,
        fn() { expanded_index.get() == index },
        use_region=use_reg,
        item.content,
      ),
    )
  }
  @luna.h("div", [("data-accordion", @luna.attr_static(""))], children)
}
