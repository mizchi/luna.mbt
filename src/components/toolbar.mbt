///|
/// APG Toolbar Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/
///
/// A toolbar is a container for grouping a set of controls.
///
/// Keyboard Interaction:
/// - Left/Right Arrow (horizontal): Move between items
/// - Up/Down Arrow (vertical): Move between items
/// - Home: Move to first item
/// - End: Move to last item
/// - Tab: Move focus out of toolbar
/// - Enter/Space: Activate button or toggle state
///
/// ARIA:
/// - role="toolbar" on container
/// - aria-orientation (horizontal or vertical)
/// - aria-label or aria-labelledby
/// - Items use roving tabindex

///|
/// Toolbar orientation
pub(all) enum ToolbarOrientation {
  Horizontal
  Vertical
}

///|
/// Create a toolbar container.
///
/// Parameters:
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - orientation: Toolbar orientation (default: horizontal)
/// - children: Toolbar items
pub fn[E] toolbar(
  aria_label? : String,
  aria_labelledby? : String,
  orientation? : ToolbarOrientation,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let orient = match orientation {
    Some(Vertical) => "vertical"
    _ => "horizontal"
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("toolbar")),
    ("aria-orientation", @luna.attr_static(orient)),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a toolbar item (button).
///
/// Parameters:
/// - selected: Whether this item has tabindex=0 (roving tabindex)
/// - pressed: For toggle buttons, the pressed state
/// - disabled: Whether the item is disabled
/// - on_click: Click handler
/// - on_keydown: Keydown handler
/// - children: Button content
pub fn[E] toolbar_item(
  selected : Bool,
  pressed? : Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let is_disabled = match disabled {
    Some(d) => d
    None => false
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("tabindex", @luna.attr_static(if selected { "0" } else { "-1" })),
  ]
  match pressed {
    Some(p) =>
      attrs.push((
        "aria-pressed",
        @luna.attr_static(if p { "true" } else { "false" }),
      ))
    None => ()
  }
  if is_disabled {
    attrs.push(("disabled", @luna.attr_static("")))
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  match on_click {
    Some(handler) =>
      if not(is_disabled) {
        attrs.push(("click", @luna.attr_handler(handler)))
      }
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a dynamic toolbar item with signal-based selection.
pub fn[E] toolbar_item_dyn(
  focused_index : @signal.Signal[Int],
  index : Int,
  pressed? : Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let is_disabled = match disabled {
    Some(d) => d
    None => false
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if focused_index.get() == index {
          "0"
        } else {
          "-1"
        }
      }),
    ),
  ]
  match pressed {
    Some(p) =>
      attrs.push((
        "aria-pressed",
        @luna.attr_static(if p { "true" } else { "false" }),
      ))
    None => ()
  }
  if is_disabled {
    attrs.push(("disabled", @luna.attr_static("")))
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  match on_click {
    Some(handler) =>
      if not(is_disabled) {
        attrs.push(("click", @luna.attr_handler(handler)))
      }
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a toolbar separator.
/// Separators are purely visual and don't receive focus.
pub fn[E] toolbar_separator(
  orientation? : ToolbarOrientation,
) -> @luna.Node[E] {
  // Separator orientation is perpendicular to toolbar orientation
  let orient = match orientation {
    Some(Vertical) => "horizontal"
    _ => "vertical"
  }
  @luna.h(
    "div",
    [
      ("role", @luna.attr_static("separator")),
      ("aria-orientation", @luna.attr_static(orient)),
      ("class", @luna.attr_static("toolbar-separator")),
    ],
    [],
  )
}

///|
/// Create a toolbar keyboard handler.
/// Handles arrow navigation, Home/End.
///
/// Parameters:
/// - current_index: Function returning current focused index
/// - item_count: Total number of focusable items
/// - on_change: Called with new index when focus changes
/// - orientation: Toolbar orientation
/// - focus_item: Function to focus item at index
pub fn make_toolbar_handler(
  current_index : () -> Int,
  item_count : Int,
  on_change : (Int) -> Unit,
  orientation : ToolbarOrientation,
  focus_item : (Int) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  let is_horizontal = match orientation {
    Horizontal => true
    Vertical => false
  }
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let curr = current_index()
    let next_opt : Int? = if is_horizontal {
      match key {
        "ArrowRight" =>
          if curr < item_count - 1 {
            Some(curr + 1)
          } else {
            None
          }
        "ArrowLeft" =>
          if curr > 0 {
            Some(curr - 1)
          } else {
            None
          }
        "Home" => Some(0)
        "End" => Some(item_count - 1)
        _ => None
      }
    } else {
      match key {
        "ArrowDown" =>
          if curr < item_count - 1 {
            Some(curr + 1)
          } else {
            None
          }
        "ArrowUp" =>
          if curr > 0 {
            Some(curr - 1)
          } else {
            None
          }
        "Home" => Some(0)
        "End" => Some(item_count - 1)
        _ => None
      }
    }
    match next_opt {
      Some(next) =>
        if next != curr {
          let _ = e._call("preventDefault", [])
          on_change(next)
          focus_item(next)
        }
      None => ()
    }
  })
}

///|
/// Toolbar item definition
pub(all) struct ToolbarItemDef {
  id : String
  label : String
  toggle : Bool
  disabled : Bool
}

///|
/// Create a toolbar item definition
pub fn toolbar_item_def(
  id : String,
  label : String,
  toggle? : Bool,
  disabled? : Bool,
) -> ToolbarItemDef {
  let is_toggle = match toggle {
    Some(t) => t
    None => false
  }
  let is_disabled = match disabled {
    Some(d) => d
    None => false
  }
  { id, label, toggle: is_toggle, disabled: is_disabled }
}

///|
/// Create an interactive toolbar with keyboard navigation.
///
/// Parameters:
/// - id: Base ID for the toolbar
/// - items: Array of toolbar item definitions
/// - pressed_states: Signal containing map of item ID to pressed state
/// - orientation: Toolbar orientation (default: horizontal)
/// - aria_label: Accessible label
/// - on_item_click: Called when an item is clicked (id, is_toggle)
pub fn toolbar_interactive(
  id : String,
  items : Array[ToolbarItemDef],
  pressed_states : @signal.Signal[Map[String, Bool]],
  orientation? : ToolbarOrientation,
  aria_label? : String,
  on_item_click : (String, Bool) -> Unit,
) -> @luna.Node[@js.Any] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let focused_index = @signal.signal(0)
  let item_count = items.length()
  // Focus helper
  let focus_item = fn(idx : Int) {
    let item_id = id + "-item-" + idx.to_string()
    let doc = @js.global_this()._get("document")
    let el = doc._call("getElementById", [@js.any(item_id)])
    let _ = el._call("focus", [])
  }
  // Keyboard handler
  let keydown_handler = make_toolbar_handler(
    fn() { focused_index.get() },
    item_count,
    fn(idx) { focused_index.set(idx) },
    orient,
    focus_item,
  )
  // Build toolbar items
  let toolbar_items : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let idx = i
    let item_id = id + "-item-" + i.to_string()
    let is_pressed : Bool? = if item.toggle {
      Some(pressed_states.get().get(item.id).unwrap_or(false))
    } else {
      None
    }
    let attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("type", @luna.attr_static("button")),
      ("id", @luna.attr_static(item_id)),
      (
        "tabindex",
        @luna.attr_dynamic(fn() {
          if focused_index.get() == idx {
            "0"
          } else {
            "-1"
          }
        }),
      ),
      ("keydown", @luna.attr_handler(keydown_handler)),
    ]
    match is_pressed {
      Some(_) =>
        attrs.push((
          "aria-pressed",
          @luna.attr_dynamic(fn() {
            if pressed_states.get().get(item.id).unwrap_or(false) {
              "true"
            } else {
              "false"
            }
          }),
        ))
      None => ()
    }
    if item.disabled {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("aria-disabled", @luna.attr_static("true")))
    } else {
      attrs.push((
        "click",
        @luna.attr_handler(@luna.handler(fn(_) {
          on_item_click(item.id, item.toggle)
        })),
      ))
    }
    toolbar_items.push(@luna.h("button", attrs, [@luna.text(item.label)]))
  }
  // Build toolbar container
  let orient_str = match orient {
    Horizontal => "horizontal"
    Vertical => "vertical"
  }
  let container_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("toolbar")),
    ("id", @luna.attr_static(id)),
    ("aria-orientation", @luna.attr_static(orient_str)),
  ]
  match aria_label {
    Some(label) => container_attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("div", container_attrs, toolbar_items)
}
