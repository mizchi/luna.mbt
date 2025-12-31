///|
/// Blockquote component for Luna (Headless)
/// Quote/citation display

///|
/// Create a headless blockquote
/// Outputs: <blockquote class="radix-blockquote">children</blockquote>
pub fn radix_blockquote(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "blockquote",
    [("class", @luna.attr_static("radix-blockquote"))],
    children,
  )
}

///|
/// Create a headless blockquote content
/// Outputs: <p class="radix-blockquote-content">children</p>
pub fn radix_blockquote_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-blockquote-content"))],
    children,
  )
}

///|
/// Create a headless blockquote footer (for citation)
/// Outputs: <footer class="radix-blockquote-footer">children</footer>
pub fn radix_blockquote_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "footer",
    [("class", @luna.attr_static("radix-blockquote-footer"))],
    children,
  )
}

///|
/// Create a headless blockquote cite
/// Outputs: <cite class="radix-blockquote-cite">children</cite>
pub fn radix_blockquote_cite(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "cite",
    [("class", @luna.attr_static("radix-blockquote-cite"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the blockquote component
fn blockquote_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.blockquote {
    #|  margin: 0;
    #|  padding: 0 0 0 1rem;
    #|  border-left: 4px solid #e4e4e7;
    #|}
    #|
    #|.blockquote-content {
    #|  margin: 0;
    #|  font-size: 1rem;
    #|  font-style: italic;
    #|  color: #3f3f46;
    #|  line-height: 1.6;
    #|}
    #|
    #|.blockquote-footer {
    #|  margin-top: 0.75rem;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.blockquote-footer::before {
    #|  content: "— ";
    #|}
    #|
    #|.blockquote-cite {
    #|  font-style: normal;
    #|}
  css
}

///|
/// Create a styled blockquote with Declarative Shadow DOM
pub fn radix_blockquote_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => blockquote_styles()
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

  @luna.h("radix-blockquote", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a blockquote with luna/css atomic styles
pub fn radix_blockquote_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = blockquote_base_styles()
  @luna.h("blockquote", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a blockquote content with luna/css atomic styles
pub fn radix_blockquote_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = blockquote_content_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a blockquote footer with luna/css atomic styles
pub fn radix_blockquote_footer_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = blockquote_footer_styles()
  @luna.h("footer", [("class", @luna.attr_static(class_names))], children)
}
