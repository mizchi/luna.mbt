///|
/// Code component for Luna (Headless)
/// Inline code and code blocks

///|
/// Create a headless inline code
/// Outputs: <code class="radix-code">children</code>
pub fn radix_code(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("code", [("class", @luna.attr_static("radix-code"))], children)
}

///|
/// Create a headless code block (pre + code)
/// Outputs: <pre class="radix-code-block"><code>children</code></pre>
pub fn radix_code_block(
  language? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-code-block")),
  ]

  match language {
    Some(lang) => attrs.push(("data-language", @luna.attr_static(lang)))
    None => ()
  }

  @luna.h(
    "pre",
    attrs,
    [@luna.h("code", [("class", @luna.attr_static("radix-code-content"))], children)],
  )
}

///|
/// Create a headless code block header (for filename, copy button, etc.)
/// Outputs: <div class="radix-code-header">children</div>
pub fn radix_code_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-code-header"))], children)
}

///|
/// Create a headless code filename
/// Outputs: <span class="radix-code-filename">children</span>
pub fn radix_code_filename(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-code-filename"))],
    children,
  )
}

///|
/// Create a headless code copy button
/// Outputs: <button class="radix-code-copy">children</button>
pub fn radix_code_copy(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-code-copy")),
      ("type", @luna.attr_static("button")),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the code component
fn code_styles() -> String {
  let css =
    #|:host {
    #|  display: inline;
    #|}
    #|
    #|.code {
    #|  display: inline;
    #|  padding: 0.125rem 0.375rem;
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
    #|  font-size: 0.875em;
    #|  background: #f4f4f5;
    #|  border-radius: 4px;
    #|  color: #18181b;
    #|}
    #|
    #|.code-block {
    #|  display: block;
    #|  padding: 1rem;
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
    #|  font-size: 0.875rem;
    #|  line-height: 1.5;
    #|  background: #18181b;
    #|  border-radius: 8px;
    #|  color: #fafafa;
    #|  overflow-x: auto;
    #|  margin: 0;
    #|}
    #|
    #|.code-content {
    #|  display: block;
    #|  background: transparent;
    #|  padding: 0;
    #|}
    #|
    #|.code-header {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  padding: 0.5rem 1rem;
    #|  background: #27272a;
    #|  border-top-left-radius: 8px;
    #|  border-top-right-radius: 8px;
    #|  font-size: 0.75rem;
    #|  color: #a1a1aa;
    #|}
    #|
    #|.code-filename {
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
    #|}
    #|
    #|.code-copy {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0.25rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  color: #a1a1aa;
    #|  cursor: pointer;
    #|  transition: color 0.15s ease, background 0.15s ease;
    #|}
    #|
    #|.code-copy:hover {
    #|  color: #fafafa;
    #|  background: rgba(255,255,255,0.1);
    #|}
  css
}

///|
/// Create a styled code with Declarative Shadow DOM
pub fn radix_code_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => code_styles()
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

  @luna.h("radix-code", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create inline code with luna/css atomic styles
pub fn radix_code_ucss(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  let class_names = code_inline_styles()
  @luna.h("code", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a code block with luna/css atomic styles
pub fn radix_code_block_ucss(
  language? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = code_block_styles()

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]

  match language {
    Some(lang) => attrs.push(("data-language", @luna.attr_static(lang)))
    None => ()
  }

  @luna.h("pre", attrs, [@luna.h("code", [], children)])
}

///|
/// Create a code header with luna/css atomic styles
pub fn radix_code_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = code_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
