///|
/// Radix-style AspectRatio component for Luna (Headless)
/// Maintains a consistent width/height ratio

///|
/// Create a headless aspect ratio container
/// Outputs: <div class="radix-aspect-ratio" style="...">children</div>
pub fn radix_aspect_ratio(
  ratio? : Double,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let ratio_val = match ratio {
    Some(r) => r
    None => 1.0
  }
  let padding_bottom = 100.0 / ratio_val

  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-aspect-ratio")),
      (
        "style",
        @luna.attr_static(
          "position: relative; width: 100%; padding-bottom: " +
          padding_bottom.to_string() +
          "%",
        ),
      ),
    ],
    [
      @luna.h(
        "div",
        [
          (
            "style",
            @luna.attr_static(
              "position: absolute; top: 0; right: 0; bottom: 0; left: 0",
            ),
          ),
        ],
        children,
      ),
    ],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the aspect ratio component
fn aspect_ratio_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.aspect-ratio {
    #|  position: relative;
    #|  width: 100%;
    #|}
    #|
    #|.aspect-ratio-inner {
    #|  position: absolute;
    #|  top: 0;
    #|  right: 0;
    #|  bottom: 0;
    #|  left: 0;
    #|}
  css
}

///|
/// Create a styled aspect ratio with Declarative Shadow DOM
pub fn radix_aspect_ratio_styled(
  ratio? : Double,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let ratio_val = match ratio {
    Some(r) => r
    None => 1.0
  }
  let padding_bottom = 100.0 / ratio_val

  let css = match styles {
    Some(s) => s
    None => aspect_ratio_styles()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h(
      "div",
      [
        ("class", @luna.attr_static("aspect-ratio")),
        (
          "style",
          @luna.attr_static("padding-bottom: " + padding_bottom.to_string() + "%"),
        ),
      ],
      [
        @luna.h(
          "div",
          [("class", @luna.attr_static("aspect-ratio-inner"))],
          [@luna.h("slot", [], [])],
        ),
      ],
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

  @luna.h("radix-aspect-ratio", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an aspect ratio container with luna/css atomic styles
pub fn radix_aspect_ratio_ucss(
  ratio? : Double,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let ratio_val = match ratio {
    Some(r) => r
    None => 1.0
  }
  let padding_bottom = 100.0 / ratio_val

  let outer_class = aspect_ratio_outer_styles()
  let inner_class = aspect_ratio_inner_styles()

  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(outer_class)),
      (
        "style",
        @luna.attr_static("padding-bottom: " + padding_bottom.to_string() + "%"),
      ),
    ],
    [@luna.h("div", [("class", @luna.attr_static(inner_class))], children)],
  )
}

// =============================================================================
// Common aspect ratio presets
// =============================================================================

///|
/// 16:9 aspect ratio (widescreen video)
pub fn radix_aspect_ratio_16_9(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  radix_aspect_ratio(ratio=16.0 / 9.0, children)
}

///|
/// 4:3 aspect ratio (standard photo)
pub fn radix_aspect_ratio_4_3(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  radix_aspect_ratio(ratio=4.0 / 3.0, children)
}

///|
/// 1:1 aspect ratio (square)
pub fn radix_aspect_ratio_square(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  radix_aspect_ratio(ratio=1.0, children)
}

///|
/// 21:9 aspect ratio (ultra-wide)
pub fn radix_aspect_ratio_21_9(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  radix_aspect_ratio(ratio=21.0 / 9.0, children)
}
