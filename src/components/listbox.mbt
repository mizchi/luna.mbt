///|
/// APG Listbox Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/listbox/
///
/// A listbox presents a list of options and allows selecting one or more.
///
/// Keyboard Interaction:
/// - Down Arrow: Move focus to next option
/// - Up Arrow: Move focus to previous option
/// - Home: Move focus to first option
/// - End: Move focus to last option
/// - Space: Toggle selection (multi-select)
/// - Type-ahead: Focus option starting with typed characters
///
/// ARIA:
/// - role="listbox" with aria-multiselectable (if multi-select)
/// - role="option" with aria-selected

///|
/// Listbox option data
pub(all) struct ListboxOption {
  value : String
  label : String
  disabled : Bool
}

///|
/// Create a listbox option
pub fn listbox_option(
  value : String,
  label : String,
  disabled? : Bool,
) -> ListboxOption {
  let dis = match disabled {
    Some(d) => d
    None => false
  }
  { value, label, disabled: dis }
}

///|
/// Create a listbox container.
///
/// Parameters:
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - multiselectable: Whether multiple options can be selected
/// - on_keydown: Keydown handler (for arrow key navigation, type-ahead)
/// - children: Option elements
pub fn[E] listbox(
  aria_label? : String,
  aria_labelledby? : String,
  multiselectable? : Bool,
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("listbox")),
    ("tabindex", @luna.attr_static("0")),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_labelledby {
    Some(id) => attrs.push(("aria-labelledby", @luna.attr_static(id)))
    None => ()
  }
  match multiselectable {
    Some(true) =>
      attrs.push(("aria-multiselectable", @luna.attr_static("true")))
    _ => ()
  }
  match on_keydown {
    Some(handler) => attrs.push(("keydown", @luna.attr_handler(handler)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a listbox option.
///
/// Parameters:
/// - value: Option value
/// - selected: Whether selected
/// - disabled: Whether disabled
/// - children: Option content
pub fn[E] option(
  value : String,
  selected : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("option")),
    (
      "aria-selected",
      @luna.attr_static(if selected { "true" } else { "false" }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic option with signal-based selection.
pub fn[E] option_dyn(
  value : String,
  selected_values : @signal.Signal[Array[String]],
  disabled? : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("option")),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected_values.get().contains(value) { "true" } else { "false" }
      }),
    ),
    ("data-value", @luna.attr_static(value)),
  ]
  match disabled {
    Some(true) => attrs.push(("aria-disabled", @luna.attr_static("true")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create an option group.
pub fn[E] optgroup(
  aria_label : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  @luna.h(
    "div",
    [
      ("role", @luna.attr_static("group")),
      ("aria-label", @luna.attr_static(aria_label)),
    ],
    children,
  )
}

///|
/// Build a complete listbox from options.
pub fn[E] listbox_from_options(
  options : Array[ListboxOption],
  selected_value : String,
  aria_label? : String,
) -> @luna.Node[E] {
  let option_nodes : Array[@luna.Node[E]] = []
  for opt in options {
    let is_selected = opt.value == selected_value
    option_nodes.push(
      option(opt.value, is_selected, disabled=opt.disabled, [@luna.text(opt.label)]),
    )
  }
  listbox(aria_label?, option_nodes)
}

///|
/// Build a multi-select listbox.
pub fn[E] listbox_multi(
  options : Array[ListboxOption],
  selected_values : Array[String],
  aria_label? : String,
) -> @luna.Node[E] {
  let option_nodes : Array[@luna.Node[E]] = []
  for opt in options {
    let is_selected = selected_values.contains(opt.value)
    option_nodes.push(
      option(opt.value, is_selected, disabled=opt.disabled, [@luna.text(opt.label)]),
    )
  }
  listbox(aria_label?, multiselectable=true, option_nodes)
}
