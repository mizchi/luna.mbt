///|
/// SegmentedControl component for Luna (Headless)
/// iOS-style segmented control/toggle

///|
/// Create a headless segmented control root
/// Outputs: <div class="radix-segmented" role="radiogroup">children</div>
pub fn radix_segmented(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-segmented")),
      ("role", @luna.attr_static("radiogroup")),
    ],
    children,
  )
}

///|
/// Create a headless segmented control item
/// Outputs: <button class="radix-segmented-item" role="radio">children</button>
pub fn radix_segmented_item(
  value : String,
  selected? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_selected = match selected {
    Some(true) => true
    _ => false
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-segmented-item")),
    ("role", @luna.attr_static("radio")),
    ("data-value", @luna.attr_static(value)),
    (
      "aria-checked",
      @luna.attr_static(if is_selected { "true" } else { "false" }),
    ),
  ]

  if is_selected {
    attrs.push(("data-selected", @luna.attr_static("")))
  }

  match disabled {
    Some(true) => {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("data-disabled", @luna.attr_static("")))
    }
    _ => ()
  }

  @luna.h("button", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the segmented control component
fn segmented_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.segmented {
    #|  display: inline-flex;
    #|  padding: 0.25rem;
    #|  background: #f4f4f5;
    #|  border-radius: 8px;
    #|  gap: 0.125rem;
    #|}
    #|
    #|.segmented-item {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.375rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 6px;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|  transition: all 0.15s ease;
    #|}
    #|
    #|.segmented-item:hover:not([data-disabled]) {
    #|  color: #18181b;
    #|}
    #|
    #|.segmented-item[data-selected] {
    #|  background: white;
    #|  color: #18181b;
    #|  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    #|}
    #|
    #|.segmented-item[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
  css
}

///|
/// Create a styled segmented control with Declarative Shadow DOM
pub fn radix_segmented_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => segmented_styles()
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

  @luna.h(
    "radix-segmented",
    [("role", @luna.attr_static("radiogroup"))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a segmented control with luna/css atomic styles
pub fn radix_segmented_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = segmented_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("radiogroup")),
    ],
    children,
  )
}

///|
/// Create a segmented control item with luna/css atomic styles
pub fn radix_segmented_item_ucss(
  value : String,
  selected? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_selected = match selected {
    Some(true) => true
    _ => false
  }

  let class_names = segmented_item_styles(selected)

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("radio")),
    ("data-value", @luna.attr_static(value)),
    (
      "aria-checked",
      @luna.attr_static(if is_selected { "true" } else { "false" }),
    ),
  ]

  if is_selected {
    attrs.push(("data-selected", @luna.attr_static("")))
  }

  match disabled {
    Some(true) => {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("data-disabled", @luna.attr_static("")))
    }
    _ => ()
  }

  @luna.h("button", attrs, children)
}
