///|
/// BackTop component for Luna (Headless)
/// Back to top button

///|
/// Create a headless back to top button
/// Outputs: <button class="radix-back-top" data-visible="...">children</button>
pub fn radix_back_top(
  visible? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_visible = match visible {
    Some(true) => true
    _ => false
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-back-top")),
    ("type", @luna.attr_static("button")),
    ("aria-label", @luna.attr_static("Back to top")),
  ]
  if is_visible {
    attrs.push(("data-visible", @luna.attr_static("")))
  }
  @luna.h("button", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the back top component
fn back_top_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.back-top {
    #|  position: fixed;
    #|  bottom: 2rem;
    #|  right: 2rem;
    #|  z-index: 50;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|  background: #18181b;
    #|  color: white;
    #|  border: none;
    #|  border-radius: 50%;
    #|  cursor: pointer;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    #|  opacity: 0;
    #|  visibility: hidden;
    #|  transform: translateY(1rem);
    #|  transition: opacity 0.3s ease, visibility 0.3s ease, transform 0.3s ease;
    #|}
    #|
    #|.back-top[data-visible] {
    #|  opacity: 1;
    #|  visibility: visible;
    #|  transform: translateY(0);
    #|}
    #|
    #|.back-top:hover {
    #|  background: #27272a;
    #|}
  css
}

///|
/// Create a styled back top with Declarative Shadow DOM
pub fn radix_back_top_styled(
  visible? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_visible = match visible {
    Some(true) => true
    _ => false
  }
  let css = match styles {
    Some(s) => s
    None => back_top_styles()
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
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("aria-label", @luna.attr_static("Back to top")),
  ]
  if is_visible {
    attrs.push(("data-visible", @luna.attr_static("")))
  }
  @luna.h("radix-back-top", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a back top button with luna/css atomic styles
pub fn radix_back_top_ucss(
  visible? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_visible = match visible {
    Some(true) => true
    _ => false
  }
  let class_names = back_top_styles_ucss(visible)
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
    ("aria-label", @luna.attr_static("Back to top")),
  ]
  if is_visible {
    attrs.push(("data-visible", @luna.attr_static("")))
  }
  @luna.h("button", attrs, children)
}
