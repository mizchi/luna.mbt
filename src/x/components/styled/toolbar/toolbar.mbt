///|
/// Styled Toolbar Component
///
/// A styled toolbar with dark theme, grouped buttons, and separators.
///
/// Class names (BEM):
/// - .toolbar           - Root element (outer container)
/// - .toolbar__inner    - Inner container with border
/// - .toolbar__group    - Button group container
/// - .toolbar__item     - Individual button
/// - .toolbar__separator - Vertical separator between groups
///
/// Data attributes:
/// - [data-selected]    - On selected/active item
/// - [data-pressed]     - On pressed toggle button
/// - [data-disabled]    - On disabled item

///|
/// Slots for the toolbar component
pub(all) struct ToolbarSlots {
  root : String
  inner : String
  group : String
  item : String
  separator : String
}

///|
/// Default BEM class names for toolbar
pub fn toolbar_slots() -> ToolbarSlots {
  {
    root: "toolbar",
    inner: "toolbar__inner",
    group: "toolbar__group",
    item: "toolbar__item",
    separator: "toolbar__separator",
  }
}

///|
/// Toolbar item configuration
pub(all) struct ToolbarItemConfig {
  id : String
  label : String
  pressed : Bool
  disabled : Bool
}

///|
/// Create a toolbar item config
pub fn toolbar_item_config(
  id : String,
  label : String,
  pressed? : Bool = false,
  disabled? : Bool = false,
) -> ToolbarItemConfig {
  { id, label, pressed, disabled }
}

///|
/// Toolbar group configuration (array of items)
pub(all) struct ToolbarGroup(Array[ToolbarItemConfig])

///|
/// Create a styled toolbar with grouped buttons and keyboard navigation.
///
/// Parameters:
/// - id: Base ID for the toolbar
/// - groups: Array of button groups
/// - aria_label: Accessible label
/// - class: Additional CSS class
/// - on_item_click: Called when item is clicked (id)
pub fn toolbar(
  id : String,
  groups : Array[ToolbarGroup],
  aria_label? : String = "Toolbar",
  class? : String,
  on_item_click : (String) -> Unit,
) -> @luna.Node[@js.Any, String] {
  let slots = toolbar_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Collect all enabled item IDs for keyboard navigation
  let all_item_ids : Array[String] = []
  for group in groups {
    for item in group.0 {
      if not(item.disabled) {
        all_item_ids.push(id + "-" + item.id)
      }
    }
  }
  let inner_children : Array[@luna.Node[@js.Any, String]] = []
  let mut item_index = 0
  for gi, group in groups {
    if gi > 0 {
      inner_children.push(
        @luna.h(
          "div",
          [
            ("role", @luna.attr_static("separator")),
            ("aria-orientation", @luna.attr_static("vertical")),
            ("class", @luna.attr_static(slots.separator)),
          ],
          [],
        ),
      )
    }
    let group_items : Array[@luna.Node[@js.Any, String]] = []
    for item in group.0 {
      let button_id = id + "-" + item.id

      // Get headless props
      let props = @headless.use_toolbar_item_nav(
        button_id,
        item.id,
        all_item_ids,
        item_index,
        item.pressed,
        item.disabled,
        on_item_click,
      )

      // Build item attrs from headless + styling
      let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
        ("class", @luna.attr_static(slots.item)),
      ]
      for attr in props.attrs {
        attrs.push(attr)
      }
      if props.is_pressed {
        attrs.push(("data-pressed", @luna.attr_static("")))
      }
      if props.is_disabled {
        attrs.push(("data-disabled", @luna.attr_static("")))
      } else {
        item_index = item_index + 1
      }
      group_items.push(@luna.h("button", attrs, [@luna.text(item.label)]))
    }
    inner_children.push(
      @luna.h(
        "div",
        [
          ("role", @luna.attr_static("group")),
          ("class", @luna.attr_static(slots.group)),
        ],
        group_items,
      ),
    )
  }
  @luna.h(
    "div",
    [
      ("role", @luna.attr_static("toolbar")),
      ("id", @luna.attr_static(id)),
      ("aria-label", @luna.attr_static(aria_label)),
      ("aria-orientation", @luna.attr_static("horizontal")),
      ("class", @luna.attr_static(root_class)),
    ],
    [
      @luna.h(
        "div",
        [("class", @luna.attr_static(slots.inner))],
        inner_children,
      ),
    ],
  )
}

///|
/// Create a styled toolbar with reactive pressed states and keyboard navigation.
///
/// Keyboard:
/// - ArrowRight: Move focus to next item
/// - ArrowLeft: Move focus to previous item
/// - Home: Move focus to first item
/// - End: Move focus to last item
pub fn toolbar_reactive(
  id : String,
  groups : Array[ToolbarGroup],
  pressed_states : @resource.Signal[Map[String, Bool]],
  aria_label? : String = "Toolbar",
  class? : String,
  on_item_click : (String) -> Unit,
) -> @luna.Node[@js.Any, String] {
  let slots = toolbar_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Collect all enabled item IDs for keyboard navigation
  let all_item_ids : Array[String] = []
  for group in groups {
    for item in group.0 {
      if not(item.disabled) {
        all_item_ids.push(id + "-" + item.id)
      }
    }
  }
  let inner_children : Array[@luna.Node[@js.Any, String]] = []
  let mut item_index = 0
  for gi, group in groups {
    if gi > 0 {
      inner_children.push(
        @luna.h(
          "div",
          [
            ("role", @luna.attr_static("separator")),
            ("aria-orientation", @luna.attr_static("vertical")),
            ("class", @luna.attr_static(slots.separator)),
          ],
          [],
        ),
      )
    }
    let group_items : Array[@luna.Node[@js.Any, String]] = []
    for item in group.0 {
      let item_id = item.id
      let button_id = id + "-" + item_id
      let current_index = item_index

      // Get headless props
      let props = @headless.use_toolbar_item_reactive(
        button_id,
        item_id,
        all_item_ids,
        current_index,
        pressed_states,
        item.disabled,
        on_item_click,
      )

      // Build item attrs from headless + styling
      let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
        (
          "class",
          @luna.attr_dynamic(fn() {
            if pressed_states.get().get(item_id).unwrap_or(false) {
              slots.item + " " + slots.item + "--pressed"
            } else {
              slots.item
            }
          }),
        ),
      ]
      for attr in props.attrs {
        attrs.push(attr)
      }
      if item.disabled {
        attrs.push(("data-disabled", @luna.attr_static("")))
      } else {
        item_index = item_index + 1
      }
      group_items.push(@luna.h("button", attrs, [@luna.text(item.label)]))
    }
    inner_children.push(
      @luna.h(
        "div",
        [
          ("role", @luna.attr_static("group")),
          ("class", @luna.attr_static(slots.group)),
        ],
        group_items,
      ),
    )
  }
  @luna.h(
    "div",
    [
      ("role", @luna.attr_static("toolbar")),
      ("id", @luna.attr_static(id)),
      ("aria-label", @luna.attr_static(aria_label)),
      ("aria-orientation", @luna.attr_static("horizontal")),
      ("class", @luna.attr_static(root_class)),
    ],
    [
      @luna.h(
        "div",
        [("class", @luna.attr_static(slots.inner))],
        inner_children,
      ),
    ],
  )
}

///|
/// Get the CSS for the styled toolbar.
pub fn toolbar_css() -> String {
  let css =
    #|/* Toolbar - Default Theme */
    #|.toolbar {
    #|  display: inline-flex;
    #|}
    #|
    #|.toolbar__inner {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  padding: 0.25rem;
    #|  border-radius: 0.5rem;
    #|  border: 1px solid var(--border);
    #|  background: var(--muted);
    #|}
    #|
    #|.toolbar__group {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.125rem;
    #|}
    #|
    #|.toolbar__item {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.5rem 0.75rem;
    #|  border: none;
    #|  border-radius: 0.375rem;
    #|  background: transparent;
    #|  color: var(--foreground);
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  cursor: pointer;
    #|  transition: background-color 0.15s, color 0.15s;
    #|}
    #|
    #|.toolbar__item:hover {
    #|  background: var(--border);
    #|}
    #|
    #|.toolbar__item:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: 2px;
    #|}
    #|
    #|.toolbar__item--pressed {
    #|  background: var(--accent);
    #|  color: var(--accent-foreground);
    #|}
    #|
    #|.toolbar__item--pressed:hover {
    #|  background: var(--accent);
    #|  opacity: 0.9;
    #|}
    #|
    #|.toolbar__item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.toolbar__separator {
    #|  width: 1px;
    #|  height: 1.25rem;
    #|  margin: 0 0.25rem;
    #|  background: var(--border);
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .toolbar__item {
    #|    transition: none;
    #|  }
    #|}
  css
}
