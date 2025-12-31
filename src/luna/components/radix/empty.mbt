///|
/// Empty state component for Luna (Headless)
/// Empty state placeholder with icon, title, description, and action

///|
/// Create a headless empty state
/// Outputs: <div class="radix-empty">children</div>
pub fn radix_empty(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-empty"))], children)
}

///|
/// Create a headless empty icon container
/// Outputs: <div class="radix-empty-icon">children</div>
pub fn radix_empty_icon(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-empty-icon"))], children)
}

///|
/// Create a headless empty title
/// Outputs: <h3 class="radix-empty-title">children</h3>
pub fn radix_empty_title(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("h3", [("class", @luna.attr_static("radix-empty-title"))], children)
}

///|
/// Create a headless empty description
/// Outputs: <p class="radix-empty-description">children</p>
pub fn radix_empty_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-empty-description"))],
    children,
  )
}

///|
/// Create a headless empty action container
/// Outputs: <div class="radix-empty-action">children</div>
pub fn radix_empty_action(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-empty-action"))], children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the empty component
fn empty_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.empty {
    #|  display: flex;
    #|  flex-direction: column;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 2rem;
    #|  text-align: center;
    #|}
    #|
    #|.empty-icon {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 4rem;
    #|  height: 4rem;
    #|  margin-bottom: 1rem;
    #|  color: #a1a1aa;
    #|}
    #|
    #|.empty-icon svg {
    #|  width: 3rem;
    #|  height: 3rem;
    #|}
    #|
    #|.empty-title {
    #|  font-size: 1rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|  margin: 0 0 0.5rem 0;
    #|}
    #|
    #|.empty-description {
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  margin: 0 0 1rem 0;
    #|  max-width: 24rem;
    #|}
    #|
    #|.empty-action {
    #|  display: flex;
    #|  gap: 0.5rem;
    #|}
  css
}

///|
/// Create a styled empty state with Declarative Shadow DOM
pub fn radix_empty_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => empty_styles()
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

  @luna.h("radix-empty", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an empty state with luna/css atomic styles
pub fn radix_empty_ucss(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  let class_names = empty_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an empty icon with luna/css atomic styles
pub fn radix_empty_icon_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = empty_icon_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an empty title with luna/css atomic styles
pub fn radix_empty_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = empty_title_styles()
  @luna.h("h3", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an empty description with luna/css atomic styles
pub fn radix_empty_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = empty_description_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an empty action with luna/css atomic styles
pub fn radix_empty_action_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = empty_action_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
