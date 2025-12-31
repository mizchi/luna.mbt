///|
/// Radix-style Carousel component for Luna (Headless)
/// Content carousel/slider

///|
/// Create a headless carousel root
/// Outputs: <div class="radix-carousel" data-orientation="...">children</div>
pub fn radix_carousel(
  orientation? : Orientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }

  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-carousel")),
      ("data-orientation", @luna.attr_static(orient.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless carousel content
/// Outputs: <div class="radix-carousel-content">children</div>
pub fn radix_carousel_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-carousel-content"))],
    children,
  )
}

///|
/// Create a headless carousel item
/// Outputs: <div class="radix-carousel-item">children</div>
pub fn radix_carousel_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-carousel-item"))],
    children,
  )
}

///|
/// Create a headless carousel previous button
/// Outputs: <button class="radix-carousel-previous">children</button>
pub fn radix_carousel_previous(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-carousel-previous")),
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
/// Create a headless carousel next button
/// Outputs: <button class="radix-carousel-next">children</button>
pub fn radix_carousel_next(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-carousel-next")),
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
/// Create a headless carousel dots/indicators
/// Outputs: <div class="radix-carousel-dots">children</div>
pub fn radix_carousel_dots(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-carousel-dots"))],
    children,
  )
}

///|
/// Create a headless carousel dot
/// Outputs: <button class="radix-carousel-dot" data-state="..."></button>
pub fn radix_carousel_dot(active? : Bool) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }
  let state = if is_active { "active" } else { "inactive" }

  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-carousel-dot")),
      ("data-state", @luna.attr_static(state)),
    ],
    [],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the carousel component
fn carousel_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.carousel {
    #|  position: relative;
    #|  width: 100%;
    #|}
    #|
    #|.carousel-content {
    #|  display: flex;
    #|  overflow: hidden;
    #|}
    #|
    #|.carousel[data-orientation="vertical"] .carousel-content {
    #|  flex-direction: column;
    #|}
    #|
    #|.carousel-item {
    #|  flex: 0 0 100%;
    #|  min-width: 0;
    #|}
    #|
    #|.carousel-previous,
    #|.carousel-next {
    #|  position: absolute;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|  padding: 0;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 50%;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|  z-index: 10;
    #|}
    #|
    #|.carousel-previous:hover:not([data-disabled]),
    #|.carousel-next:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.carousel-previous[data-disabled],
    #|.carousel-next[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.carousel-previous {
    #|  left: -1rem;
    #|}
    #|
    #|.carousel-next {
    #|  right: -1rem;
    #|}
    #|
    #|.carousel-dots {
    #|  display: flex;
    #|  justify-content: center;
    #|  gap: 0.5rem;
    #|  margin-top: 1rem;
    #|}
    #|
    #|.carousel-dot {
    #|  width: 0.5rem;
    #|  height: 0.5rem;
    #|  padding: 0;
    #|  background: #d4d4d8;
    #|  border: none;
    #|  border-radius: 50%;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.carousel-dot:hover {
    #|  background: #a1a1aa;
    #|}
    #|
    #|.carousel-dot[data-state="active"] {
    #|  background: #18181b;
    #|}
  css
}

///|
/// Create a styled carousel with Declarative Shadow DOM
pub fn radix_carousel_styled(
  orientation? : Orientation,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }

  let css = match styles {
    Some(s) => s
    None => carousel_styles()
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

  @luna.h(
    "radix-carousel",
    [("data-orientation", @luna.attr_static(orient.to_string()))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a carousel with luna/css atomic styles
pub fn radix_carousel_ucss(
  orientation? : Orientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(o) => o
    None => Horizontal
  }

  let class_names = carousel_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-orientation", @luna.attr_static(orient.to_string())),
    ],
    children,
  )
}

///|
/// Create a carousel content with luna/css atomic styles
pub fn radix_carousel_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = carousel_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a carousel item with luna/css atomic styles
pub fn radix_carousel_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = carousel_item_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a carousel nav button with luna/css atomic styles
pub fn radix_carousel_nav_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = carousel_nav_styles()

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
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }

  @luna.h("button", attrs, children)
}

///|
/// Create a carousel dot with luna/css atomic styles
pub fn radix_carousel_dot_ucss(active? : Bool) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }
  let state = if is_active { "active" } else { "inactive" }

  let mut class_names = carousel_dot_styles()
  if is_active {
    class_names = class_names + " " + @css.styles([("background", "#18181b")])
  }

  @luna.h(
    "button",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-state", @luna.attr_static(state)),
    ],
    [],
  )
}
