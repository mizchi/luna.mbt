///|
/// Radix-style Progress component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Create a headless progress container
/// Outputs: <div class="radix-progress" role="progressbar" ...>children</div>
pub fn radix_progress(
  value? : Int,
  max? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let value_val = match value {
    Some(v) => v
    None => 0
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-progress")),
    ("role", @luna.attr_static("progressbar")),
    ("aria-valuenow", @luna.attr_static(value_val.to_string())),
    ("aria-valuemin", @luna.attr_static("0")),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
    ("data-value", @luna.attr_static(value_val.to_string())),
    ("data-max", @luna.attr_static(max_val.to_string())),
  ]

  @luna.h("div", attrs, children)
}

///|
/// Create a headless progress indicator
/// Outputs: <div class="radix-progress-indicator" style="transform: translateX(-...%)"></div>
pub fn radix_progress_indicator(value? : Int, max? : Int) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let value_val = match value {
    Some(v) => v
    None => 0
  }

  // Calculate percentage
  let percentage = if max_val > 0 { value_val * 100 / max_val } else { 0 }
  let translate = 100 - percentage

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-progress-indicator")),
    (
      "style",
      @luna.attr_static("transform: translateX(-" + translate.to_string() + "%)"),
    ),
  ]

  @luna.h("div", attrs, [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the progress component
fn progress_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.progress {
    #|  position: relative;
    #|  height: 0.5rem;
    #|  width: 100%;
    #|  background: #e4e4e7;
    #|  border-radius: 9999px;
    #|  overflow: hidden;
    #|}
    #|
    #|.progress-indicator {
    #|  height: 100%;
    #|  width: 100%;
    #|  background: #18181b;
    #|  transition: transform 0.3s ease;
    #|}
  css
}

///|
/// Create a styled progress with Declarative Shadow DOM
pub fn radix_progress_styled(
  value? : Int,
  max? : Int,
  styles? : String,
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let value_val = match value {
    Some(v) => v
    None => 0
  }

  let css = match styles {
    Some(s) => s
    None => progress_styles()
  }

  // Calculate percentage
  let percentage = if max_val > 0 { value_val * 100 / max_val } else { 0 }
  let translate = 100 - percentage

  // Build progress attributes
  let progress_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("progress")),
    ("role", @luna.attr_static("progressbar")),
    ("aria-valuenow", @luna.attr_static(value_val.to_string())),
    ("aria-valuemin", @luna.attr_static("0")),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
  ]

  // Build indicator
  let indicator = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("progress-indicator")),
      (
        "style",
        @luna.attr_static(
          "transform: translateX(-" + translate.to_string() + "%)",
        ),
      ),
    ],
    [],
  )

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("div", progress_attrs, [indicator]),
  ]

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-value", @luna.attr_static(value_val.to_string())),
    ("data-max", @luna.attr_static(max_val.to_string())),
  ]

  // Create DSD structure
  @luna.h("radix-progress", host_attrs, [
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
/// Create a progress with luna/css atomic styles
pub fn radix_progress_ucss(
  value? : Int,
  max? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let value_val = match value {
    Some(v) => v
    None => 0
  }

  let class_names = progress_base_styles()

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("progressbar")),
    ("aria-valuenow", @luna.attr_static(value_val.to_string())),
    ("aria-valuemin", @luna.attr_static("0")),
    ("aria-valuemax", @luna.attr_static(max_val.to_string())),
  ]

  @luna.h("div", attrs, children)
}

///|
/// Create a progress indicator with luna/css atomic styles
pub fn radix_progress_indicator_ucss(
  value? : Int,
  max? : Int,
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 100
  }
  let value_val = match value {
    Some(v) => v
    None => 0
  }

  // Calculate percentage
  let percentage = if max_val > 0 { value_val * 100 / max_val } else { 0 }
  let translate = 100 - percentage

  let class_names = progress_indicator_styles()

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    (
      "style",
      @luna.attr_static("transform: translateX(-" + translate.to_string() + "%)"),
    ),
  ]

  @luna.h("div", attrs, [])
}
