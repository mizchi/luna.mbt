///|
/// Mentions component for Luna (Headless)
/// Text input with @ mentions support

///|
/// Create a headless mentions root
/// Outputs: <div class="radix-mentions">children</div>
pub fn radix_mentions(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-mentions")),
  ]
  match open {
    Some(true) => attrs.push(("data-open", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless mentions textarea
/// Outputs: <textarea class="radix-mentions-textarea">value</textarea>
pub fn radix_mentions_textarea(
  value? : String,
  placeholder? : String,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-mentions-textarea")),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  let content = match value {
    Some(v) => [@luna.text(v)]
    None => []
  }
  @luna.h("textarea", attrs, content)
}

///|
/// Create a headless mentions dropdown
/// Outputs: <div class="radix-mentions-dropdown">children</div>
pub fn radix_mentions_dropdown(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-mentions-dropdown")),
      ("role", @luna.attr_static("listbox")),
    ],
    children,
  )
}

///|
/// Create a headless mentions item
/// Outputs: <div class="radix-mentions-item" role="option">children</div>
pub fn radix_mentions_item(
  value : String,
  highlighted? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-mentions-item")),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  match highlighted {
    Some(true) => attrs.push(("data-highlighted", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless mentions item avatar
/// Outputs: <img class="radix-mentions-item-avatar" src="..." alt="..." />
pub fn radix_mentions_item_avatar(
  src : String,
  alt : String,
) -> @luna.Node[Unit] {
  @luna.h(
    "img",
    [
      ("class", @luna.attr_static("radix-mentions-item-avatar")),
      ("src", @luna.attr_static(src)),
      ("alt", @luna.attr_static(alt)),
    ],
    [],
  )
}

///|
/// Create a headless mentions item name
/// Outputs: <span class="radix-mentions-item-name">children</span>
pub fn radix_mentions_item_name(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-mentions-item-name"))],
    children,
  )
}

///|
/// Create a headless mentions item username
/// Outputs: <span class="radix-mentions-item-username">children</span>
pub fn radix_mentions_item_username(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-mentions-item-username"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the mentions component
fn mentions_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|  position: relative;
    #|}
    #|
    #|.mentions {
    #|  position: relative;
    #|}
    #|
    #|.mentions-textarea {
    #|  width: 100%;
    #|  min-height: 5rem;
    #|  padding: 0.75rem;
    #|  font-size: 0.875rem;
    #|  font-family: inherit;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  resize: vertical;
    #|  transition: border-color 0.15s ease, box-shadow 0.15s ease;
    #|}
    #|
    #|.mentions-textarea:focus {
    #|  outline: none;
    #|  border-color: #18181b;
    #|  box-shadow: 0 0 0 3px rgba(24, 24, 27, 0.1);
    #|}
    #|
    #|.mentions-textarea:disabled {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.mentions-dropdown {
    #|  position: absolute;
    #|  z-index: 50;
    #|  min-width: 12rem;
    #|  padding: 0.25rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|  max-height: 15rem;
    #|  overflow-y: auto;
    #|}
    #|
    #|.mentions:not([data-open]) .mentions-dropdown {
    #|  display: none;
    #|}
    #|
    #|.mentions-item {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  padding: 0.5rem 0.75rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.mentions-item:hover,
    #|.mentions-item[data-highlighted] {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.mentions-item-avatar {
    #|  width: 1.5rem;
    #|  height: 1.5rem;
    #|  border-radius: 50%;
    #|  object-fit: cover;
    #|}
    #|
    #|.mentions-item-name {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #18181b;
    #|}
    #|
    #|.mentions-item-username {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled mentions with Declarative Shadow DOM
pub fn radix_mentions_styled(
  open? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => mentions_styles()
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
  @luna.h("radix-mentions", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a mentions with luna/css atomic styles
pub fn radix_mentions_ucss(
  open? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = mentions_base_styles()
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
/// Create a mentions textarea with luna/css atomic styles
pub fn radix_mentions_textarea_ucss(
  value? : String,
  placeholder? : String,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let class_names = mentions_textarea_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  let content = match value {
    Some(v) => [@luna.text(v)]
    None => []
  }
  @luna.h("textarea", attrs, content)
}

///|
/// Create a mentions dropdown with luna/css atomic styles
pub fn radix_mentions_dropdown_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = mentions_dropdown_styles()
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
/// Create a mentions item with luna/css atomic styles
pub fn radix_mentions_item_ucss(
  value : String,
  highlighted? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = mentions_item_styles(highlighted)
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("option")),
    ("data-value", @luna.attr_static(value)),
  ]
  @luna.h("div", attrs, children)
}
