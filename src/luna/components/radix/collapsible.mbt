///|
/// Radix-style Collapsible component for Luna (Headless)
/// Simple expandable/collapsible section

///|
/// Create a headless collapsible root
/// Outputs: <div class="radix-collapsible" data-state="...">children</div>
pub fn radix_collapsible(
  open? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-collapsible")),
    ("data-state", @luna.attr_static(state)),
  ]

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless collapsible trigger
/// Outputs: <button class="radix-collapsible-trigger">children</button>
pub fn radix_collapsible_trigger(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-collapsible-trigger")),
      ("aria-expanded", @luna.attr_static("false")),
    ],
    children,
  )
}

///|
/// Create a headless collapsible content
/// Outputs: <div class="radix-collapsible-content">children</div>
pub fn radix_collapsible_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-collapsible-content"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the collapsible component
fn collapsible_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.collapsible {
    #|  width: 100%;
    #|}
    #|
    #|.collapsible[data-disabled] {
    #|  opacity: 0.5;
    #|  pointer-events: none;
    #|}
    #|
    #|.collapsible-trigger {
    #|  display: flex;
    #|  width: 100%;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  padding: 0.75rem 1rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  background: transparent;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.collapsible-trigger:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.collapsible-trigger:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: 2px;
    #|}
    #|
    #|.collapsible-content {
    #|  overflow: hidden;
    #|  margin-top: 0.5rem;
    #|  padding: 0.75rem 1rem;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.collapsible[data-state="closed"] .collapsible-content {
    #|  display: none;
    #|}
  css
}

///|
/// Create a styled collapsible with Declarative Shadow DOM
pub fn radix_collapsible_styled(
  open? : Bool,
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }

  let css = match styles {
    Some(s) => s
    None => collapsible_styles()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-state", @luna.attr_static(state)),
  ]

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
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

  @luna.h("radix-collapsible", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a collapsible with luna/css atomic styles
pub fn radix_collapsible_ucss(
  open? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_open = match open {
    Some(true) => true
    _ => false
  }
  let state = if is_open { "open" } else { "closed" }

  let mut class_names = collapsible_base_styles()

  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("pointer-events", "none")])
    _ => ()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("data-state", @luna.attr_static(state)),
  ]

  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a collapsible trigger with luna/css atomic styles
pub fn radix_collapsible_trigger_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = collapsible_trigger_styles()
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static(class_names)),
      ("aria-expanded", @luna.attr_static("false")),
    ],
    children,
  )
}

///|
/// Create a collapsible content with luna/css atomic styles
pub fn radix_collapsible_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = collapsible_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
