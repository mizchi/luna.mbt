///|
/// Radix-style Skeleton component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Skeleton shape variants
pub(all) enum SkeletonShape {
  Rectangle
  Circle
  Text
}

///|
pub fn SkeletonShape::to_string(self : SkeletonShape) -> String {
  match self {
    Rectangle => "rectangle"
    Circle => "circle"
    Text => "text"
  }
}

///|
/// Create a headless skeleton element
/// Outputs: <div class="radix-skeleton" data-shape="..." aria-hidden="true"></div>
pub fn radix_skeleton(
  shape? : SkeletonShape,
  width? : String,
  height? : String,
) -> @luna.Node[Unit] {
  let shape_val = match shape {
    Some(s) => s
    None => Rectangle
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-skeleton")),
    ("data-shape", @luna.attr_static(shape_val.to_string())),
    ("aria-hidden", @luna.attr_static("true")),
  ]

  // Add inline style for custom dimensions
  let style_parts : Array[String] = []
  match width {
    Some(w) => style_parts.push("width: " + w)
    None => ()
  }
  match height {
    Some(h) => style_parts.push("height: " + h)
    None => ()
  }
  if style_parts.length() > 0 {
    attrs.push(("style", @luna.attr_static(style_parts.iter().join(";"))))
  }
  @luna.h("div", attrs, [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the skeleton component
fn skeleton_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.skeleton {
    #|  background: linear-gradient(90deg, #e4e4e7 25%, #f4f4f5 50%, #e4e4e7 75%);
    #|  background-size: 200% 100%;
    #|  animation: skeleton-loading 1.5s ease-in-out infinite;
    #|}
    #|
    #|@keyframes skeleton-loading {
    #|  0% { background-position: 200% 0; }
    #|  100% { background-position: -200% 0; }
    #|}
    #|
    #|.skeleton[data-shape="rectangle"] {
    #|  border-radius: 4px;
    #|  min-height: 1rem;
    #|}
    #|
    #|.skeleton[data-shape="circle"] {
    #|  border-radius: 50%;
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|}
    #|
    #|.skeleton[data-shape="text"] {
    #|  border-radius: 2px;
    #|  height: 1em;
    #|  width: 100%;
    #|}
  css
}

///|
/// Create a styled skeleton with Declarative Shadow DOM
pub fn radix_skeleton_styled(
  shape? : SkeletonShape,
  width? : String,
  height? : String,
  styles? : String,
) -> @luna.Node[Unit] {
  let shape_val = match shape {
    Some(s) => s
    None => Rectangle
  }
  let css = match styles {
    Some(s) => s
    None => skeleton_styles()
  }

  // Build skeleton attributes
  let skeleton_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("skeleton")),
    ("data-shape", @luna.attr_static(shape_val.to_string())),
    ("aria-hidden", @luna.attr_static("true")),
  ]

  // Add inline style for custom dimensions
  let style_parts : Array[String] = []
  match width {
    Some(w) => style_parts.push("width: " + w)
    None => ()
  }
  match height {
    Some(h) => style_parts.push("height: " + h)
    None => ()
  }
  if style_parts.length() > 0 {
    skeleton_attrs.push(
      ("style", @luna.attr_static(style_parts.iter().join(";"))),
    )
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("div", skeleton_attrs, []),
  ]

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-shape", @luna.attr_static(shape_val.to_string())),
  ]

  // Create DSD structure
  @luna.h("radix-skeleton", host_attrs, [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ])
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a skeleton with luna/css atomic styles
pub fn radix_skeleton_ucss(
  shape? : SkeletonShape,
  width? : String,
  height? : String,
) -> @luna.Node[Unit] {
  let shape_val = match shape {
    Some(s) => s
    None => Rectangle
  }
  let class_names = skeleton_base_styles() +
    " " +
    skeleton_shape_styles(shape_val)
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("aria-hidden", @luna.attr_static("true")),
  ]

  // Add inline style for custom dimensions
  let style_parts : Array[String] = []
  match width {
    Some(w) => style_parts.push("width: " + w)
    None => ()
  }
  match height {
    Some(h) => style_parts.push("height: " + h)
    None => ()
  }
  if style_parts.length() > 0 {
    attrs.push(("style", @luna.attr_static(style_parts.iter().join(";"))))
  }
  @luna.h("div", attrs, [])
}
