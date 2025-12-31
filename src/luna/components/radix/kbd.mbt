///|
/// Kbd (Keyboard) component for Luna (Headless)
/// Display keyboard shortcuts and keys

///|
/// Create a headless kbd element
/// Outputs: <kbd class="radix-kbd">children</kbd>
pub fn radix_kbd(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("kbd", [("class", @luna.attr_static("radix-kbd"))], children)
}

///|
/// Create a headless kbd group (for key combinations)
/// Outputs: <span class="radix-kbd-group">children</span>
pub fn radix_kbd_group(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-kbd-group"))], children)
}

///|
/// Create a headless kbd separator
/// Outputs: <span class="radix-kbd-separator">+</span>
pub fn radix_kbd_separator() -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-kbd-separator"))], [
    @luna.text("+"),
  ])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the kbd component
fn kbd_styles() -> String {
  let css =
    #|:host {
    #|  display: inline;
    #|}
    #|
    #|.kbd {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  min-width: 1.5rem;
    #|  height: 1.5rem;
    #|  padding: 0 0.375rem;
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  background: linear-gradient(180deg, #fafafa 0%, #e4e4e7 100%);
    #|  border: 1px solid #d4d4d8;
    #|  border-radius: 4px;
    #|  box-shadow: 0 1px 0 1px rgba(0,0,0,0.05), inset 0 1px 0 rgba(255,255,255,0.5);
    #|  color: #3f3f46;
    #|}
    #|
    #|.kbd-group {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|}
    #|
    #|.kbd-separator {
    #|  color: #a1a1aa;
    #|  font-size: 0.75rem;
    #|}
  css
}

///|
/// Create a styled kbd with Declarative Shadow DOM
pub fn radix_kbd_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => kbd_styles()
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
  @luna.h("radix-kbd", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a kbd with luna/css atomic styles
pub fn radix_kbd_ucss(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  let class_names = kbd_base_styles()
  @luna.h("kbd", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a kbd group with luna/css atomic styles
pub fn radix_kbd_group_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = kbd_group_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], children)
}
