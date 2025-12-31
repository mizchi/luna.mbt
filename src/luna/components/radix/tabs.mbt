///|
/// Radix-style Tabs component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless tabs root container
/// Outputs: <div class="radix-tabs" data-orientation="...">children</div>
pub fn radix_tabs(
  orientation? : Orientation,
  default_value? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-tabs")),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]
  match default_value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless tabs list (container for triggers)
/// Outputs: <div class="radix-tabs-list" role="tablist">children</div>
pub fn radix_tabs_list(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-tabs-list")),
      ("role", @luna.attr_static("tablist")),
    ],
    children,
  )
}

///|
/// Create a headless tabs trigger (tab button)
/// Outputs: <button class="radix-tabs-trigger" role="tab" data-value="...">children</button>
pub fn radix_tabs_trigger(
  value : String,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-tabs-trigger")),
    ("role", @luna.attr_static("tab")),
    ("data-value", @luna.attr_static(value)),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless tabs content panel
/// Outputs: <div class="radix-tabs-content" role="tabpanel" data-value="...">children</div>
pub fn radix_tabs_content(
  value : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-tabs-content")),
      ("role", @luna.attr_static("tabpanel")),
      ("data-value", @luna.attr_static(value)),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the tabs component
fn tabs_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.tabs {
    #|  display: flex;
    #|  flex-direction: column;
    #|}
    #|
    #|.tabs[data-orientation="vertical"] {
    #|  flex-direction: row;
    #|}
    #|
    #|.tabs-list {
    #|  display: flex;
    #|  gap: 0.25rem;
    #|  background: #f4f4f5;
    #|  padding: 0.25rem;
    #|  border-radius: 6px;
    #|}
    #|
    #|.tabs[data-orientation="vertical"] .tabs-list {
    #|  flex-direction: column;
    #|}
    #|
    #|.tabs-trigger {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  font-family: inherit;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  color: #71717a;
    #|  cursor: pointer;
    #|  transition: all 0.15s ease;
    #|}
    #|
    #|.tabs-trigger:hover:not([data-disabled]) {
    #|  color: #18181b;
    #|}
    #|
    #|.tabs-trigger[data-state="active"] {
    #|  background: white;
    #|  color: #18181b;
    #|  box-shadow: 0 1px 2px rgba(0,0,0,0.1);
    #|}
    #|
    #|.tabs-trigger[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.tabs-trigger:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
    #|
    #|.tabs-content {
    #|  padding: 1rem 0;
    #|}
  css
}

///|
/// Create a styled tabs with Declarative Shadow DOM
pub fn radix_tabs_styled(
  orientation? : Orientation,
  default_value? : String,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let css = match styles {
    Some(s) => s
    None => tabs_styles()
  }

  // Build tabs attributes
  let tabs_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("tabs")),
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]
  match default_value {
    Some(v) => tabs_attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("div", tabs_attrs, [@luna.h("slot", [], [])]),
  ]

  // Create DSD structure
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

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-orientation", @luna.attr_static(orient.to_string())),
  ]
  @luna.h("radix-tabs", host_attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create tabs with luna/css atomic styles
pub fn radix_tabs_ucss(
  orientation? : Orientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }
  let class_names = tabs_base_styles() + " " + tabs_orientation_styles(orient)
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create tabs list with luna/css atomic styles
pub fn radix_tabs_list_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tabs_list_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("tablist")),
    ],
    children,
  )
}

///|
/// Create tabs trigger with luna/css atomic styles
pub fn radix_tabs_trigger_ucss(
  value : String,
  active? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }
  let mut class_names = tabs_trigger_styles() +
    " " +
    tabs_trigger_focus_styles()
  if is_active {
    class_names = class_names + " " + tabs_trigger_active_styles()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("tab")),
    ("data-value", @luna.attr_static(value)),
  ]
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create tabs content with luna/css atomic styles
pub fn radix_tabs_content_ucss(
  value : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = tabs_content_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("tabpanel")),
      ("data-value", @luna.attr_static(value)),
    ],
    children,
  )
}
