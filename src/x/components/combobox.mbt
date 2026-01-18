///|
/// APG Combobox Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/combobox/
///
/// A combobox is a composite widget that combines an input (text or search)
/// with a listbox, allowing users to type to filter options or navigate
/// through a list of options.
///
/// Keyboard Interaction:
/// - Down Arrow: Open listbox and move to first/next option
/// - Up Arrow: Open listbox and move to last/previous option
/// - Enter: Select current option, close listbox
/// - Escape: Close listbox, clear selection
/// - Alt+Down Arrow: Open listbox without moving focus
/// - Alt+Up Arrow: Close listbox
///
/// ARIA:
/// - role="combobox" on input container
/// - aria-expanded on combobox
/// - aria-haspopup="listbox"
/// - aria-autocomplete (none, list, both, inline)
/// - aria-activedescendant on combobox (points to selected option)
/// - role="listbox" on popup
/// - role="option" on each option

///|
/// Combobox option data
pub(all) struct ComboboxOption {
  id : String
  label : String
  disabled : Bool
}

///|
/// Create a combobox option
pub fn combobox_option(
  id : String,
  label : String,
  disabled? : Bool,
) -> ComboboxOption {
  { id, label, disabled: disabled.unwrap_or(false) }
}

///|
/// Autocomplete behavior
pub(all) enum AutocompleteType {
  None // No autocomplete
  List // Filter list based on input
  Both // Filter list and complete input text
  Inline // Complete input text only
}

///|
/// Create a combobox input element.
///
/// Parameters:
/// - id: Input ID
/// - listbox_id: ID of the associated listbox
/// - expanded: Whether listbox is visible
/// - value: Current input value
/// - autocomplete: Autocomplete behavior
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - active_descendant: ID of the currently active option
/// - on_input: Input handler
/// - on_keydown: Keydown handler
/// - on_focus: Focus handler
/// - on_blur: Blur handler
pub fn[E] combobox_input(
  id : String,
  listbox_id : String,
  expanded : Bool,
  value : String,
  autocomplete? : AutocompleteType,
  aria_label? : String,
  aria_labelledby? : String,
  active_descendant? : String,
  on_input? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  on_focus? : @luna.EventHandler[E],
  on_blur? : @luna.EventHandler[E],
) -> @luna.Node[E] {
  let ac_str = match autocomplete {
    Some(None) => "none"
    Some(List) => "list"
    Some(Both) => "both"
    Some(Inline) => "inline"
    _ => "list"
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("text")),
    ("id", @luna.attr_static(id)),
    ("role", @luna.attr_static("combobox")),
    ("aria-haspopup", @luna.attr_static("listbox")),
    (
      "aria-expanded",
      @luna.attr_static(if expanded { "true" } else { "false" }),
    ),
    ("aria-controls", @luna.attr_static(listbox_id)),
    ("aria-autocomplete", @luna.attr_static(ac_str)),
    ("value", @luna.attr_static(value)),
    ("autocomplete", @luna.attr_static("off")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(lid) {
    attrs.push(("aria-labelledby", @luna.attr_static(lid)))
  }
  if active_descendant is Some(aid) {
    attrs.push(("aria-activedescendant", @luna.attr_static(aid)))
  }
  if on_input is Some(handler) {
    attrs.push(("input", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  if on_focus is Some(handler) {
    attrs.push(("focus", @luna.attr_handler(handler)))
  }
  if on_blur is Some(handler) {
    attrs.push(("blur", @luna.attr_handler(handler)))
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a dynamic combobox input with signal-based state.
pub fn[E] combobox_input_dyn(
  id : String,
  listbox_id : String,
  expanded : @resource.Signal[Bool],
  value : @resource.Signal[String],
  autocomplete? : AutocompleteType,
  aria_label? : String,
  active_descendant : @resource.Signal[String],
  on_input? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  on_focus? : @luna.EventHandler[E],
  on_blur? : @luna.EventHandler[E],
) -> @luna.Node[E] {
  let ac_str = match autocomplete {
    Some(None) => "none"
    Some(List) => "list"
    Some(Both) => "both"
    Some(Inline) => "inline"
    _ => "list"
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("type", @luna.attr_static("text")),
    ("id", @luna.attr_static(id)),
    ("role", @luna.attr_static("combobox")),
    ("aria-haspopup", @luna.attr_static("listbox")),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(listbox_id)),
    ("aria-autocomplete", @luna.attr_static(ac_str)),
    ("value", @luna.attr_dynamic(fn() { value.get() })),
    ("autocomplete", @luna.attr_static("off")),
    (
      "aria-activedescendant",
      @luna.attr_dynamic(fn() { active_descendant.get() }),
    ),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if on_input is Some(handler) {
    attrs.push(("input", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  if on_focus is Some(handler) {
    attrs.push(("focus", @luna.attr_handler(handler)))
  }
  if on_blur is Some(handler) {
    attrs.push(("blur", @luna.attr_handler(handler)))
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a combobox listbox container.
///
/// Parameters:
/// - id: Listbox ID
/// - labelled_by: ID of the element that labels this listbox
/// - visible: Whether listbox is visible
/// - children: Option elements
pub fn[E] combobox_listbox(
  id : String,
  labelled_by : String,
  visible : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("listbox")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelled_by)),
  ]
  if not(visible) {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("ul", attrs, children)
}

///|
/// Create a dynamic combobox listbox with signal-based visibility.
pub fn[E] combobox_listbox_dyn(
  id : String,
  labelled_by : String,
  visible : @resource.Signal[Bool],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("listbox")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelled_by)),
  ]
  @luna.show(fn() { visible.get() }, fn() { @luna.h("ul", attrs, children) })
}

///|
/// Create a combobox option element.
///
/// Parameters:
/// - id: Option ID
/// - selected: Whether this option is the active descendant
/// - disabled: Whether option is disabled
/// - on_click: Click handler
/// - children: Option content
pub fn[E] combobox_option_el(
  id : String,
  selected : Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let is_disabled = disabled.unwrap_or(false)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("option")),
    ("id", @luna.attr_static(id)),
    (
      "aria-selected",
      @luna.attr_static(if selected { "true" } else { "false" }),
    ),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) && not(is_disabled) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  @luna.h("li", attrs, children)
}

///|
/// Create a dynamic combobox option with signal-based selection.
pub fn[E] combobox_option_dyn(
  id : String,
  option_id : String,
  active_id : @resource.Signal[String],
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let is_disabled = disabled.unwrap_or(false)
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("option")),
    ("id", @luna.attr_static(id)),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if active_id.get() == option_id {
          "true"
        } else {
          "false"
        }
      }),
    ),
  ]
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) && not(is_disabled) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  @luna.h("li", attrs, children)
}

///|
/// Filter options based on input text.
fn filter_options(
  options : Array[ComboboxOption],
  query : String,
) -> Array[ComboboxOption] {
  if query == "" {
    return options.copy()
  }
  let query_lower = query.to_lower()
  let result : Array[ComboboxOption] = []
  for opt in options {
    if opt.label.to_lower().contains(query_lower) {
      result.push(opt)
    }
  }
  result
}

///|
/// Create a combobox keyboard handler.
/// Handles arrow navigation, Enter selection, Escape to close.
pub fn make_combobox_handler(
  is_open : () -> Bool,
  filtered_options : () -> Array[ComboboxOption],
  current_index : () -> Int,
  open_listbox : () -> Unit,
  close_listbox : () -> Unit,
  set_index : (Int) -> Unit,
  on_select : (ComboboxOption) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let options = filtered_options()
    let count = options.length()
    let curr = current_index()
    match key {
      "ArrowDown" => {
        let _ = e._call("preventDefault", [])
        if not(is_open()) {
          open_listbox()
          if count > 0 {
            set_index(0)
          }
        } else if count > 0 {
          let next = if curr >= count - 1 { 0 } else { curr + 1 }
          set_index(next)
        }
      }
      "ArrowUp" => {
        let _ = e._call("preventDefault", [])
        if not(is_open()) {
          open_listbox()
          if count > 0 {
            set_index(count - 1)
          }
        } else if count > 0 {
          let next = if curr <= 0 { count - 1 } else { curr - 1 }
          set_index(next)
        }
      }
      "Enter" =>
        if is_open() && curr >= 0 && curr < count {
          let _ = e._call("preventDefault", [])
          let opt = options[curr]
          if not(opt.disabled) {
            on_select(opt)
            close_listbox()
          }
        }
      "Escape" =>
        if is_open() {
          let _ = e._call("preventDefault", [])
          close_listbox()
        }
      "Home" =>
        if is_open() && count > 0 {
          let _ = e._call("preventDefault", [])
          set_index(0)
        }
      "End" =>
        if is_open() && count > 0 {
          let _ = e._call("preventDefault", [])
          set_index(count - 1)
        }
      _ => ()
    }
  })
}

///|
/// Create a complete interactive combobox with filtering.
///
/// Parameters:
/// - id: Base ID for the component
/// - options: Available options
/// - placeholder: Placeholder text for input
/// - aria_label: Accessible label
/// - on_select: Called when an option is selected
pub fn combobox_interactive(
  id : String,
  options : Array[ComboboxOption],
  placeholder? : String,
  aria_label? : String,
  on_select : (ComboboxOption) -> Unit,
) -> @luna.Node[@js.Any] {
  let input_value = @resource.signal("")
  let is_open = @resource.signal(false)
  let active_index = @resource.signal(-1)
  let active_option_id = @resource.signal("")
  let input_id = id + "-input"
  let listbox_id = id + "-listbox"
  // Filtered options based on input
  let get_filtered = fn() -> Array[ComboboxOption] {
    filter_options(options, input_value.get())
  }
  // Update active option ID when index changes
  let update_active_id = fn(idx : Int) {
    active_index.set(idx)
    let filtered = get_filtered()
    if idx >= 0 && idx < filtered.length() {
      active_option_id.set(id + "-option-" + filtered[idx].id)
    } else {
      active_option_id.set("")
    }
  }
  // Keyboard handler
  let keydown_handler = make_combobox_handler(
    fn() { is_open.get() },
    get_filtered,
    fn() { active_index.get() },
    fn() {
      is_open.set(true)
      update_active_id(0)
    },
    fn() {
      is_open.set(false)
      active_index.set(-1)
      active_option_id.set("")
    },
    update_active_id,
    fn(opt) {
      input_value.set(opt.label)
      on_select(opt)
    },
  )
  // Input handler for filtering
  let input_handler = @luna.handler(fn(e : @js.Any) {
    let target = e._get("target")
    let val : String = target._get("value").cast()
    input_value.set(val)
    is_open.set(true)
    // Reset selection when typing
    let filtered = get_filtered()
    if filtered.length() > 0 {
      update_active_id(0)
    } else {
      update_active_id(-1)
    }
  })
  // Focus handler - open listbox
  let focus_handler = @luna.handler(fn(_ : @js.Any) { is_open.set(true) })
  // Blur handler - close listbox (with delay for click handling)
  let blur_handler = @luna.handler(fn(_ : @js.Any) {
    // Use setTimeout to allow click events on options to fire first
    let window = @js.global_this()
    let _ = window._call("setTimeout", [
      @js.any(fn() { is_open.set(false) }),
      @js.any(200),
    ])

  })
  // Build input
  let input_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("text")),
    ("id", @luna.attr_static(input_id)),
    ("role", @luna.attr_static("combobox")),
    ("aria-haspopup", @luna.attr_static("listbox")),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if is_open.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(listbox_id)),
    ("aria-autocomplete", @luna.attr_static("list")),
    ("value", @luna.attr_dynamic(fn() { input_value.get() })),
    ("autocomplete", @luna.attr_static("off")),
    (
      "aria-activedescendant",
      @luna.attr_dynamic(fn() { active_option_id.get() }),
    ),
    ("input", @luna.attr_handler(input_handler)),
    ("keydown", @luna.attr_handler(keydown_handler)),
    ("focus", @luna.attr_handler(focus_handler)),
    ("blur", @luna.attr_handler(blur_handler)),
  ]
  if placeholder is Some(p) {
    input_attrs.push(("placeholder", @luna.attr_static(p)))
  }
  if aria_label is Some(label) {
    input_attrs.push(("aria-label", @luna.attr_static(label)))
  }
  // Build listbox with reactive content using For node
  let build_listbox = fn() -> @luna.Node[@js.Any] {
    @luna.h(
      "ul",
      [
        ("role", @luna.attr_static("listbox")),
        ("id", @luna.attr_static(listbox_id)),
        ("aria-labelledby", @luna.attr_static(input_id)),
        ("class", @luna.attr_static("combobox-listbox")),
      ],
      [
        @luna.Node::For(render=fn() {
          let filtered = get_filtered()
          let option_nodes : Array[@luna.Node[@js.Any]] = []
          for opt in filtered {
            let opt_id = id + "-option-" + opt.id
            option_nodes.push(
              combobox_option_dyn(
                opt_id,
                opt_id,
                active_option_id,
                disabled=opt.disabled,
                on_click=@luna.handler(fn(_ : @js.Any) {
                  if not(opt.disabled) {
                    input_value.set(opt.label)
                    on_select(opt)
                    is_open.set(false)
                  }
                }),
                [@luna.text(opt.label)],
              ),
            )
          }
          option_nodes
        }),
      ],
    )
  }
  // Caret icon (CSS-based, since Luna doesn't support SVG namespace yet)
  let caret_icon = @luna.h(
    "span",
    [
      ("class", @luna.attr_static("combobox-caret")),
      ("aria-hidden", @luna.attr_static("true")),
    ],
    [],
  )
  @luna.h("div", [("class", @luna.attr_static("combobox-container"))], [
    @luna.h("div", [("class", @luna.attr_static("combobox-input-wrapper"))], [
      @luna.h("input", input_attrs, []),
      caret_icon,
    ]),
    @luna.show(fn() { is_open.get() }, build_listbox),
  ])
}

///|
/// Create a select-only combobox (no text input filtering).
/// This is useful when options should not be filtered by typing.
pub fn combobox_select_only(
  id : String,
  options : Array[ComboboxOption],
  initial_value? : String,
  aria_label? : String,
  on_select : (ComboboxOption) -> Unit,
) -> @luna.Node[@js.Any] {
  let init_label = initial_value.unwrap_or_else(fn() {
    if options.length() > 0 {
      options[0].label
    } else {
      ""
    }
  })
  let selected_label = @resource.signal(init_label)
  let is_open = @resource.signal(false)
  let active_index = @resource.signal(0)
  let button_id = id + "-button"
  let listbox_id = id + "-listbox"
  let item_count = options.length()
  // Keyboard handler for button
  let button_keydown = @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    match key {
      "ArrowDown" | "Enter" | " " => {
        let _ = e._call("preventDefault", [])
        is_open.set(true)
      }
      "ArrowUp" => {
        let _ = e._call("preventDefault", [])
        is_open.set(true)
        active_index.set(item_count - 1)
      }
      _ => ()
    }
  })
  // Keyboard handler for listbox
  let listbox_keydown = @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let curr = active_index.get()
    match key {
      "ArrowDown" => {
        let _ = e._call("preventDefault", [])
        let next = if curr >= item_count - 1 { 0 } else { curr + 1 }
        active_index.set(next)
      }
      "ArrowUp" => {
        let _ = e._call("preventDefault", [])
        let next = if curr <= 0 { item_count - 1 } else { curr - 1 }
        active_index.set(next)
      }
      "Enter" | " " => {
        let _ = e._call("preventDefault", [])
        if curr >= 0 && curr < item_count {
          let opt = options[curr]
          if not(opt.disabled) {
            selected_label.set(opt.label)
            on_select(opt)
            is_open.set(false)
          }
        }
      }
      "Escape" => {
        let _ = e._call("preventDefault", [])
        is_open.set(false)
      }
      "Home" => {
        let _ = e._call("preventDefault", [])
        active_index.set(0)
      }
      "End" => {
        let _ = e._call("preventDefault", [])
        active_index.set(item_count - 1)
      }
      _ => ()
    }
  })
  // Build option items
  let option_items : Array[@luna.Node[@js.Any]] = []
  for i, opt in options {
    let idx = i
    let opt_id = id + "-option-" + i.to_string()
    option_items.push(
      @luna.h(
        "li",
        [
          ("role", @luna.attr_static("option")),
          ("id", @luna.attr_static(opt_id)),
          (
            "aria-selected",
            @luna.attr_dynamic(fn() {
              if active_index.get() == idx {
                "true"
              } else {
                "false"
              }
            }),
          ),
          (
            "click",
            @luna.attr_handler(
              @luna.handler(fn(_ : @js.Any) {
                if not(opt.disabled) {
                  selected_label.set(opt.label)
                  on_select(opt)
                  is_open.set(false)
                }
              }),
            ),
          ),
          ("keydown", @luna.attr_handler(listbox_keydown)),
          (
            "tabindex",
            @luna.attr_dynamic(fn() {
              if active_index.get() == idx {
                "0"
              } else {
                "-1"
              }
            }),
          ),
        ],
        [@luna.text(opt.label)],
      ),
    )
  }
  // Build button
  let button_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(button_id)),
    ("aria-haspopup", @luna.attr_static("listbox")),
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if is_open.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(listbox_id)),
    ("keydown", @luna.attr_handler(button_keydown)),
    (
      "click",
      @luna.attr_handler(
        @luna.handler(fn(_ : @js.Any) { is_open.set(not(is_open.get())) }),
      ),
    ),
  ]
  if aria_label is Some(label) {
    button_attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("div", [("class", @luna.attr_static("combobox-select-container"))], [
    @luna.h("button", button_attrs, [
      @luna.text_dyn(fn() { selected_label.get() }),
    ]),
    @luna.show(fn() { is_open.get() }, fn() {
      @luna.h(
        "ul",
        [
          ("role", @luna.attr_static("listbox")),
          ("id", @luna.attr_static(listbox_id)),
          ("aria-labelledby", @luna.attr_static(button_id)),
          ("class", @luna.attr_static("combobox-listbox")),
        ],
        option_items,
      )
    }),
  ])
}
