///|
/// Image component for Luna (Headless)
/// Image with lazy loading, fallback, and blur placeholder

///|
/// Image loading state enum
pub enum ImageLoadingState {
  Loading
  Loaded
  Error
}

///|
/// Create a headless image root
/// Outputs: <div class="radix-image">children</div>
pub fn radix_image(
  state? : ImageLoadingState,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_str = match state {
    Some(Loading) => "loading"
    Some(Loaded) => "loaded"
    Some(Error) => "error"
    None => "loading"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-image")),
      ("data-state", @luna.attr_static(state_str)),
    ],
    children,
  )
}

///|
/// Create a headless image element
/// Outputs: <img class="radix-image-img" src="..." alt="..." loading="lazy" />
pub fn radix_image_img(
  src : String,
  alt : String,
  width? : String,
  height? : String,
  lazy_load? : Bool,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-image-img")),
    ("src", @luna.attr_static(src)),
    ("alt", @luna.attr_static(alt)),
  ]
  match width {
    Some(w) => attrs.push(("width", @luna.attr_static(w)))
    None => ()
  }
  match height {
    Some(h) => attrs.push(("height", @luna.attr_static(h)))
    None => ()
  }
  match lazy_load {
    Some(false) => ()
    _ => attrs.push(("loading", @luna.attr_static("lazy")))
  }
  @luna.h("img", attrs, [])
}

///|
/// Create a headless image fallback
/// Outputs: <div class="radix-image-fallback">children</div>
pub fn radix_image_fallback(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-image-fallback"))],
    children,
  )
}

///|
/// Create a headless image placeholder (blur)
/// Outputs: <div class="radix-image-placeholder" style="background-image: ..."></div>
pub fn radix_image_placeholder(blur_data_url? : String) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-image-placeholder")),
  ]
  match blur_data_url {
    Some(url) =>
      attrs.push(
        ("style", @luna.attr_static("background-image: url(" + url + ")")),
      )
    None => ()
  }
  @luna.h("div", attrs, [])
}

///|
/// Create a headless image caption
/// Outputs: <figcaption class="radix-image-caption">children</figcaption>
pub fn radix_image_caption(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "figcaption",
    [("class", @luna.attr_static("radix-image-caption"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the image component
fn image_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.image {
    #|  position: relative;
    #|  overflow: hidden;
    #|}
    #|
    #|.image-img {
    #|  display: block;
    #|  width: 100%;
    #|  height: auto;
    #|  object-fit: cover;
    #|  transition: opacity 0.3s ease;
    #|}
    #|
    #|.image[data-state="loading"] .image-img {
    #|  opacity: 0;
    #|}
    #|
    #|.image[data-state="loaded"] .image-img {
    #|  opacity: 1;
    #|}
    #|
    #|.image[data-state="error"] .image-img {
    #|  display: none;
    #|}
    #|
    #|.image-fallback {
    #|  position: absolute;
    #|  inset: 0;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  background: #f4f4f5;
    #|  color: #71717a;
    #|}
    #|
    #|.image[data-state="loaded"] .image-fallback {
    #|  display: none;
    #|}
    #|
    #|.image-placeholder {
    #|  position: absolute;
    #|  inset: 0;
    #|  background-size: cover;
    #|  background-position: center;
    #|  filter: blur(20px);
    #|  transform: scale(1.1);
    #|  transition: opacity 0.3s ease;
    #|}
    #|
    #|.image[data-state="loaded"] .image-placeholder {
    #|  opacity: 0;
    #|}
    #|
    #|.image-caption {
    #|  padding: 0.5rem 0;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  text-align: center;
    #|}
  css
}

///|
/// Create a styled image with Declarative Shadow DOM
pub fn radix_image_styled(
  state? : ImageLoadingState,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_str = match state {
    Some(Loading) => "loading"
    Some(Loaded) => "loaded"
    Some(Error) => "error"
    None => "loading"
  }
  let css = match styles {
    Some(s) => s
    None => image_styles()
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
    "radix-image",
    [("data-state", @luna.attr_static(state_str))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an image with luna/css atomic styles
pub fn radix_image_ucss(
  state? : ImageLoadingState,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let state_str = match state {
    Some(Loading) => "loading"
    Some(Loaded) => "loaded"
    Some(Error) => "error"
    None => "loading"
  }
  let class_names = image_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-state", @luna.attr_static(state_str)),
    ],
    children,
  )
}

///|
/// Create an image element with luna/css atomic styles
pub fn radix_image_img_ucss(
  src : String,
  alt : String,
  lazy_load? : Bool,
) -> @luna.Node[Unit] {
  let class_names = image_img_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("src", @luna.attr_static(src)),
    ("alt", @luna.attr_static(alt)),
  ]
  match lazy_load {
    Some(false) => ()
    _ => attrs.push(("loading", @luna.attr_static("lazy")))
  }
  @luna.h("img", attrs, [])
}

///|
/// Create an image fallback with luna/css atomic styles
pub fn radix_image_fallback_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = image_fallback_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
