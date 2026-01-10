///|
/// Radix-style Accordion component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Accordion type (single or multiple open items)
pub(all) enum AccordionType {
  Single
  Multiple
}

///|
pub fn AccordionType::to_string(self : AccordionType) -> String {
  match self {
    Single => "single"
    Multiple => "multiple"
  }
}

///|
/// Create a headless accordion root
/// Outputs: <div class="radix-accordion" data-type="...">children</div>
pub fn radix_accordion(
  type_? : AccordionType,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Single
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-accordion")),
      ("data-type", @luna.attr_static(type_val.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless accordion item
/// Outputs: <div class="radix-accordion-item" data-value="...">children</div>
pub fn radix_accordion_item(
  value : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-accordion-item")),
      ("data-value", @luna.attr_static(value)),
    ],
    children,
  )
}

///|
/// Create a headless accordion trigger (header button)
/// Outputs: <button class="radix-accordion-trigger">children</button>
pub fn radix_accordion_trigger(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-accordion-trigger")),
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
/// Create a headless accordion content
/// Outputs: <div class="radix-accordion-content">children</div>
pub fn radix_accordion_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-accordion-content"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the accordion component
fn accordion_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.accordion {
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|  overflow: hidden;
    #|}
    #|
    #|.accordion-item {
    #|  border-bottom: 1px solid #e4e4e7;
    #|}
    #|
    #|.accordion-item:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|.accordion-trigger {
    #|  display: flex;
    #|  width: 100%;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  padding: 1rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  font-family: inherit;
    #|  background: transparent;
    #|  border: none;
    #|  text-align: left;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.accordion-trigger:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.accordion-trigger[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.accordion-trigger:focus-visible {
    #|  outline: 2px solid #2563eb;
    #|  outline-offset: -2px;
    #|}
    #|
    #|.accordion-content {
    #|  padding: 0 1rem 1rem;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled accordion with Declarative Shadow DOM
pub fn radix_accordion_styled(
  type_? : AccordionType,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let type_val = match type_ {
    Some(t) => t
    None => Single
  }
  let css = match styles {
    Some(s) => s
    None => accordion_styles()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h(
      "div",
      [
        ("class", @luna.attr_static("accordion")),
        ("data-type", @luna.attr_static(type_val.to_string())),
      ],
      [@luna.h("slot", [], [])],
    ),
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
  @luna.h("radix-accordion", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an accordion with luna/css atomic styles
pub fn radix_accordion_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = accordion_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an accordion item with luna/css atomic styles
pub fn radix_accordion_item_ucss(
  value : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = accordion_item_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-value", @luna.attr_static(value)),
    ],
    children,
  )
}

///|
/// Create an accordion trigger with luna/css atomic styles
pub fn radix_accordion_trigger_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = accordion_trigger_styles() +
    " " +
    accordion_trigger_focus_styles()
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create an accordion content with luna/css atomic styles
pub fn radix_accordion_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = accordion_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
