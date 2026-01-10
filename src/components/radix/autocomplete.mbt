///|
/// AutoComplete component for Luna (Headless)
/// Input with suggestions dropdown

///|
/// Create a headless autocomplete root
/// Outputs: <div class="radix-autocomplete">children</div>
pub fn radix_autocomplete(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-autocomplete")),
  ]
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless autocomplete input
/// Outputs: <input class="radix-autocomplete-input" type="text" role="combobox" />
pub fn radix_autocomplete_input(
  value? : String,
  placeholder? : String,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-autocomplete-input")),
    ("type", @luna.attr_static("text")),
    ("role", @luna.attr_static("combobox")),
    ("aria-autocomplete", @luna.attr_static("list")),
    ("autocomplete", @luna.attr_static("off")),
  ]
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a headless autocomplete content (dropdown)
/// Outputs: <div class="radix-autocomplete-content" role="listbox">children</div>
pub fn radix_autocomplete_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-autocomplete-content")),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a headless autocomplete item
/// Outputs: <div class="radix-autocomplete-item" role="option">children</div>
pub fn radix_autocomplete_item(
  value : String,
  selected? : Bool,
  highlighted? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-autocomplete-item")),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  match selected {
    Some(true) => {
      attrs.push(("aria-selected", @luna.attr_static("true")))
      attrs.push(("data-selected", @luna.attr_static("")))
    }
    _ => ()
  }
  match highlighted {
    Some(true) => attrs.push(("data-highlighted", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless autocomplete empty state
/// Outputs: <div class="radix-autocomplete-empty">children</div>
pub fn radix_autocomplete_empty(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-autocomplete-empty"))],
    children,
  )
}

///|
/// Create a headless autocomplete loading state
/// Outputs: <div class="radix-autocomplete-loading">children</div>
pub fn radix_autocomplete_loading(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-autocomplete-loading"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the autocomplete component
fn autocomplete_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|  position: relative;
    #|}
    #|
    #|.autocomplete {
    #|  position: relative;
    #|}
    #|
    #|.autocomplete-input {
    #|  width: 100%;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  background: white;
    #|  transition: border-color 0.15s ease, box-shadow 0.15s ease;
    #|}
    #|
    #|.autocomplete-input:focus {
    #|  outline: none;
    #|  border-color: #18181b;
    #|  box-shadow: 0 0 0 3px rgba(24, 24, 27, 0.1);
    #|}
    #|
    #|.autocomplete-input:disabled {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.autocomplete-content {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  right: 0;
    #|  z-index: 50;
    #|  margin-top: 0.25rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|  max-height: 15rem;
    #|  overflow-y: auto;
    #|}
    #|
    #|.autocomplete:not([data-open]) .autocomplete-content {
    #|  display: none;
    #|}
    #|
    #|.autocomplete-item {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.autocomplete-item:hover,
    #|.autocomplete-item[data-highlighted] {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.autocomplete-item[data-selected] {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|.autocomplete-empty,
    #|.autocomplete-loading {
    #|  padding: 0.75rem;
    #|  text-align: center;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled autocomplete with Declarative Shadow DOM
pub fn radix_autocomplete_styled(
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => autocomplete_styles()
  }
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]
  for child in children {
    all_children.push(child)
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = []
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-autocomplete", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an autocomplete with luna/css atomic styles
pub fn radix_autocomplete_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = autocomplete_base_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create an autocomplete input with luna/css atomic styles
pub fn radix_autocomplete_input_ucss(
  value? : String,
  placeholder? : String,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let class_names = autocomplete_input_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("text")),
    ("role", @luna.attr_static("combobox")),
    ("aria-autocomplete", @luna.attr_static("list")),
  ]
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create an autocomplete content with luna/css atomic styles
pub fn radix_autocomplete_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = autocomplete_content_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create an autocomplete item with luna/css atomic styles
pub fn radix_autocomplete_item_ucss(
  value : String,
  selected? : Bool,
  highlighted? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = autocomplete_item_styles(selected, highlighted)
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  match selected {
    Some(true) => attrs.push(("aria-selected", @luna.attr_static("true")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}
