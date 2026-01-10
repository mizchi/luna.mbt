///|
/// FAB (Floating Action Button) component for Luna (Headless)
/// Material Design style floating action button

///|
/// FAB size enum
pub enum FabSize {
  Sm
  Md
  Lg
}

///|
/// FAB position enum
pub enum FabPosition {
  BottomRight
  BottomLeft
  BottomCenter
  TopRight
  TopLeft
}

///|
/// Create a headless FAB
/// Outputs: <button class="radix-fab" data-size="..." data-position="...">children</button>
pub fn radix_fab(
  size? : FabSize,
  position? : FabPosition,
  extended? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    _ => "md"
  }
  let position_str = match position {
    Some(BottomLeft) => "bottom-left"
    Some(BottomCenter) => "bottom-center"
    Some(TopRight) => "top-right"
    Some(TopLeft) => "top-left"
    _ => "bottom-right"
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-fab")),
    ("type", @luna.attr_static("button")),
    ("data-size", @luna.attr_static(size_str)),
    ("data-position", @luna.attr_static(position_str)),
  ]
  match extended {
    Some(true) => attrs.push(("data-extended", @luna.attr_static("")))
    _ => ()
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

///|
/// Create a headless FAB icon slot
/// Outputs: <span class="radix-fab-icon">children</span>
pub fn radix_fab_icon(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-fab-icon"))], children)
}

///|
/// Create a headless FAB label (for extended FAB)
/// Outputs: <span class="radix-fab-label">children</span>
pub fn radix_fab_label(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-fab-label"))], children)
}

///|
/// Create a headless FAB container (for positioning)
/// Outputs: <div class="radix-fab-container">children</div>
pub fn radix_fab_container(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-fab-container"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the FAB component
fn fab_styles() -> String {
  let css =
    #|:host {
    #|  display: contents;
    #|}
    #|
    #|.fab-container {
    #|  position: fixed;
    #|  z-index: 50;
    #|}
    #|
    #|.fab-container[data-position="bottom-right"] {
    #|  bottom: 1.5rem;
    #|  right: 1.5rem;
    #|}
    #|
    #|.fab-container[data-position="bottom-left"] {
    #|  bottom: 1.5rem;
    #|  left: 1.5rem;
    #|}
    #|
    #|.fab-container[data-position="bottom-center"] {
    #|  bottom: 1.5rem;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|}
    #|
    #|.fab-container[data-position="top-right"] {
    #|  top: 1.5rem;
    #|  right: 1.5rem;
    #|}
    #|
    #|.fab-container[data-position="top-left"] {
    #|  top: 1.5rem;
    #|  left: 1.5rem;
    #|}
    #|
    #|.fab {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  background: #18181b;
    #|  color: white;
    #|  border: none;
    #|  border-radius: 9999px;
    #|  cursor: pointer;
    #|  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06);
    #|  transition: transform 0.15s ease, box-shadow 0.15s ease;
    #|}
    #|
    #|.fab:hover:not([data-disabled]) {
    #|  transform: scale(1.05);
    #|  box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
    #|}
    #|
    #|.fab:active:not([data-disabled]) {
    #|  transform: scale(0.98);
    #|}
    #|
    #|.fab[data-size="sm"] {
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|}
    #|
    #|.fab[data-size="md"] {
    #|  width: 3.5rem;
    #|  height: 3.5rem;
    #|}
    #|
    #|.fab[data-size="lg"] {
    #|  width: 4rem;
    #|  height: 4rem;
    #|}
    #|
    #|.fab[data-extended] {
    #|  width: auto;
    #|  padding: 0 1.25rem;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.fab[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.fab-icon {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|}
    #|
    #|.fab[data-size="sm"] .fab-icon {
    #|  width: 1rem;
    #|  height: 1rem;
    #|}
    #|
    #|.fab[data-size="md"] .fab-icon {
    #|  width: 1.5rem;
    #|  height: 1.5rem;
    #|}
    #|
    #|.fab[data-size="lg"] .fab-icon {
    #|  width: 1.75rem;
    #|  height: 1.75rem;
    #|}
    #|
    #|.fab-label {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  white-space: nowrap;
    #|}
  css
}

///|
/// Create a styled FAB with Declarative Shadow DOM
pub fn radix_fab_styled(
  size? : FabSize,
  extended? : Bool,
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    _ => "md"
  }
  let css = match styles {
    Some(s) => s
    None => fab_styles()
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
    ("data-size", @luna.attr_static(size_str)),
  ]
  match extended {
    Some(true) => attrs.push(("data-extended", @luna.attr_static("")))
    _ => ()
  }
  match disabled {
    Some(true) => {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("data-disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("radix-fab", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a FAB with luna/css atomic styles
pub fn radix_fab_ucss(
  size? : FabSize,
  extended? : Bool,
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = fab_base_styles(size, extended)
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    _ => "md"
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
    ("data-size", @luna.attr_static(size_str)),
  ]
  match extended {
    Some(true) => attrs.push(("data-extended", @luna.attr_static("")))
    _ => ()
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

///|
/// Create a FAB container with luna/css atomic styles
pub fn radix_fab_container_ucss(
  position? : FabPosition,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = fab_container_styles(position)
  let position_str = match position {
    Some(BottomLeft) => "bottom-left"
    Some(BottomCenter) => "bottom-center"
    Some(TopRight) => "top-right"
    Some(TopLeft) => "top-left"
    _ => "bottom-right"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-position", @luna.attr_static(position_str)),
    ],
    children,
  )
}
