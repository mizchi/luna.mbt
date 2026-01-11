///|
/// APG Link Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/link/
///
/// A link widget provides an interactive reference to a resource.
/// Uses native <a> element when href is provided.
///
/// Keyboard Interaction:
/// - Enter: Executes the link and moves focus to the link target
/// - Shift+F10 (Optional): Opens a context menu for the link
///
/// ARIA:
/// - role="link" (only needed for non-<a> elements)
/// - Uses native <a> element with href for best accessibility

///|
/// Link target behavior
pub(all) enum LinkTarget {
  Self_ // Same window/tab (_self)
  Blank // New window/tab (_blank)
  Parent // Parent frame (_parent)
  Top // Top frame (_top)
}

///|
fn LinkTarget::to_string(self : LinkTarget) -> String {
  match self {
    Self_ => "_self"
    Blank => "_blank"
    Parent => "_parent"
    Top => "_top"
  }
}

///|
/// Create an accessible link using native <a> element.
/// This is the recommended approach per APG guidelines.
///
/// Parameters:
/// - href: URL to navigate to
/// - target: Link target (default: Self_)
/// - aria_label: Accessible label (optional, for icon-only links)
/// - aria_describedby: ID of element describing the link (optional)
/// - disabled: Whether the link is disabled (optional)
/// - children: Child nodes (link text/content)
///
/// Example:
/// ```
/// link("https://example.com", [@luna.text("Visit Example")])
/// link("/about", target=Blank, [@luna.text("About (new tab)")])
/// ```
pub fn[E] link(
  href : String,
  target? : LinkTarget,
  aria_label? : String,
  aria_describedby? : String,
  disabled? : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("href", @luna.attr_static(href)),
  ]
  match target {
    Some(t) => attrs.push(("target", @luna.attr_static(t.to_string())))
    None => ()
  }
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  match aria_describedby {
    Some(id) => attrs.push(("aria-describedby", @luna.attr_static(id)))
    None => ()
  }
  match disabled {
    Some(true) => {
      attrs.push(("aria-disabled", @luna.attr_static("true")))
      attrs.push(("tabindex", @luna.attr_static("-1")))
    }
    _ => ()
  }
  @luna.h("a", attrs, children)
}

///|
/// Create a link-styled button (for actions that look like links).
/// Uses role="link" on a span/button element.
/// Use this when you need link appearance but button semantics.
///
/// Parameters:
/// - on_click: Click handler
/// - aria_label: Accessible label (optional)
/// - children: Child nodes
///
/// Keyboard Interaction:
/// - Enter: Activates the link action
/// - Space: Activates the link action (when focused)
pub fn[E] link_button(
  on_click : @luna.EventHandler[E],
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("link")),
    ("tabindex", @luna.attr_static("0")),
    ("click", @luna.attr_handler(on_click)),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("span", attrs, children)
}
