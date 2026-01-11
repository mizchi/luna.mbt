///|
/// APG Menu Button Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
///
/// A menu button is a button that opens a menu. It is often styled
/// as a typical push button with a downward pointing arrow.
///
/// Keyboard Interaction:
/// - Enter/Space: Open menu, move focus to first item
/// - Down Arrow: Open menu, move focus to first item
/// - Up Arrow: Open menu, move focus to last item
/// - Escape: Close menu, return focus to button
///
/// Menu Navigation:
/// - Down Arrow: Move to next item (wrap to first)
/// - Up Arrow: Move to previous item (wrap to last)
/// - Home: Move to first item
/// - End: Move to last item
/// - Enter/Space: Activate item, close menu
/// - Escape: Close menu
/// - Character: Move to item starting with that character
///
/// ARIA:
/// - Button: aria-haspopup="menu", aria-expanded, aria-controls
/// - Menu: role="menu", aria-labelledby
/// - Menu items: role="menuitem", tabindex

///|
/// Menu item data
pub(all) struct MenuItem {
  id : String
  label : String
  disabled : Bool
}

///|
/// Create a menu item
pub fn menu_item(id : String, label : String, disabled? : Bool) -> MenuItem {
  let is_disabled = match disabled {
    Some(d) => d
    None => false
  }
  { id, label, disabled: is_disabled }
}

///|
/// Create a menu button trigger with ID.
/// Uses existing menu_button from button.mbt internally.
///
/// Parameters:
/// - id: Button ID
/// - expanded: Whether menu is open
/// - menu_id: ID of the menu element
/// - aria_label: Accessible label
/// - on_click: Click handler
/// - on_keydown: Keydown handler
/// - children: Button content
pub fn[E] menu_trigger(
  id : String,
  expanded : Bool,
  menu_id : String,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(id)),
    ("aria-haspopup", @luna.attr_static("menu")),
    (
      "aria-expanded",
      @luna.attr_static(if expanded { "true" } else { "false" }),
    ),
    ("aria-controls", @luna.attr_static(menu_id)),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match on_click {
    Some(handler) => attrs.push(("click", @luna.attr_handler(handler)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a dynamic menu trigger with signal-based state.
pub fn[E] menu_trigger_dyn(
  id : String,
  expanded : @signal.Signal[Bool],
  menu_id : String,
  aria_label? : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(id)),
    ("aria-haspopup", @luna.attr_static("menu")),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(menu_id)),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match on_click {
    Some(handler) => attrs.push(("click", @luna.attr_handler(handler)))
    None => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a menu container.
///
/// Parameters:
/// - id: Menu ID (referenced by button's aria-controls)
/// - labelled_by: ID of the button that labels this menu
/// - visible: Whether menu is visible
/// - children: Menu items
pub fn[E] menu(
  id : String,
  labelled_by : String,
  visible : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("menu")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelled_by)),
  ]
  if not(visible) {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("ul", attrs, children)
}

///|
/// Create a dynamic menu with signal-based visibility.
pub fn[E] menu_dyn(
  id : String,
  labelled_by : String,
  visible : @signal.Signal[Bool],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("menu")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelled_by)),
  ]
  @luna.show(fn() { visible.get() }, fn() { @luna.h("ul", attrs, children) })
}

///|
/// Create a menu item element.
///
/// Parameters:
/// - id: Item ID
/// - selected: Whether this item has focus (tabindex=0)
/// - disabled: Whether item is disabled
/// - on_click: Click handler
/// - on_keydown: Keydown handler
/// - children: Item content
pub fn[E] menuitem(
  id? : String,
  selected : Bool,
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
    ("role", @luna.attr_static("menuitem")),
    (
      "tabindex",
      @luna.attr_static(if selected { "0" } else { "-1" }),
    ),
  ]
  match id {
    Some(i) => attrs.push(("id", @luna.attr_static(i)))
    None => ()
  }
  if is_disabled {
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
  @luna.h("li", attrs, children)
}

///|
/// Create a dynamic menu item with signal-based selection.
pub fn[E] menuitem_dyn(
  id? : String,
  selected_index : @signal.Signal[Int],
  index : Int,
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
    ("role", @luna.attr_static("menuitem")),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if selected_index.get() == index {
          "0"
        } else {
          "-1"
        }
      }),
    ),
  ]
  match id {
    Some(i) => attrs.push(("id", @luna.attr_static(i)))
    None => ()
  }
  if is_disabled {
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
  @luna.h("li", attrs, children)
}

///|
/// Create a menu button keyboard handler for the trigger button.
/// Handles Enter, Space, ArrowDown, ArrowUp to open menu.
pub fn make_menu_button_handler(
  is_open : () -> Bool,
  open_menu : () -> Unit,
  close_menu : () -> Unit,
  focus_first : () -> Unit,
  focus_last : () -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    match key {
      "Enter" | " " | "ArrowDown" => {
        let _ = e._call("preventDefault", [])
        if not(is_open()) {
          open_menu()
          focus_first()
        }
      }
      "ArrowUp" => {
        let _ = e._call("preventDefault", [])
        if not(is_open()) {
          open_menu()
          focus_last()
        }
      }
      "Escape" =>
        if is_open() {
          close_menu()
        }
      _ => ()
    }
  })
}

///|
/// Create a menu keyboard handler for menu items.
/// Handles arrow navigation, Enter/Space activation, Escape to close.
pub fn make_menu_nav_handler(
  current_index : () -> Int,
  item_count : Int,
  on_select : (Int) -> Unit,
  close_menu : () -> Unit,
  on_activate : (Int) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let curr = current_index()
    match key {
      "ArrowDown" => {
        let _ = e._call("preventDefault", [])
        let next = if curr >= item_count - 1 { 0 } else { curr + 1 }
        on_select(next)
      }
      "ArrowUp" => {
        let _ = e._call("preventDefault", [])
        let next = if curr <= 0 { item_count - 1 } else { curr - 1 }
        on_select(next)
      }
      "Home" => {
        let _ = e._call("preventDefault", [])
        on_select(0)
      }
      "End" => {
        let _ = e._call("preventDefault", [])
        on_select(item_count - 1)
      }
      "Enter" | " " => {
        let _ = e._call("preventDefault", [])
        on_activate(curr)
        close_menu()
      }
      "Escape" => {
        let _ = e._call("preventDefault", [])
        close_menu()
      }
      _ => ()
    }
  })
}

///|
/// Create a complete interactive menu button with keyboard support.
///
/// Parameters:
/// - id: Base ID for the component
/// - items: Menu items
/// - on_select: Called when an item is selected
/// - button_content: Content for the trigger button
pub fn menu_button_interactive(
  id : String,
  items : Array[MenuItem],
  on_select : (String) -> Unit,
  button_content : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let open = @signal.signal(false)
  let focused_index = @signal.signal(0)
  let button_id = id + "-button"
  let menu_id = id + "-menu"
  let item_count = items.length()
  // Focus management helper
  let focus_item = fn(idx : Int) {
    focused_index.set(idx)
    let doc = @js.global_this()._get("document")
    let item_id = id + "-item-" + idx.to_string()
    let el = doc._call("getElementById", [@js.any(item_id)])
    let _ = el._call("focus", [])
  }
  let focus_button = fn() {
    let doc = @js.global_this()._get("document")
    let el = doc._call("getElementById", [@js.any(button_id)])
    let _ = el._call("focus", [])
  }
  let close_and_focus_button = fn() {
    open.set(false)
    focus_button()
  }
  // Button keydown handler
  let button_keydown = make_menu_button_handler(
    fn() { open.get() },
    fn() { open.set(true) },
    close_and_focus_button,
    fn() { focus_item(0) },
    fn() { focus_item(item_count - 1) },
  )
  // Menu keydown handler
  let menu_keydown = make_menu_nav_handler(
    fn() { focused_index.get() },
    item_count,
    focus_item,
    close_and_focus_button,
    fn(idx) {
      let item = items[idx]
      if not(item.disabled) {
        on_select(item.id)
      }
    },
  )
  // Build menu items
  let menu_items : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let idx = i
    let item_id = id + "-item-" + i.to_string()
    menu_items.push(
      menuitem_dyn(
        id=item_id,
        focused_index,
        idx,
        disabled=item.disabled,
        on_click=@luna.handler(fn(_) {
          if not(item.disabled) {
            on_select(item.id)
            close_and_focus_button()
          }
        }),
        on_keydown=menu_keydown,
        [@luna.text(item.label)],
      ),
    )
  }
  @luna.h(
    "div",
    [("class", @luna.attr_static("menu-button-container"))],
    [
      menu_trigger_dyn(
        button_id,
        open,
        menu_id,
        on_click=@luna.handler(fn(_) { open.set(not(open.get())) }),
        on_keydown=button_keydown,
        button_content,
      ),
      menu_dyn(menu_id, button_id, open, menu_items),
    ],
  )
}
