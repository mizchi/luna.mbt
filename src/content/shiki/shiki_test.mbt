///|
test "resolve_language: aliases" {
  inspect(resolve_language("js"), content="typescript")
  inspect(resolve_language("ts"), content="typescript")
  inspect(resolve_language("mbt"), content="moonbit")
  inspect(resolve_language("sh"), content="bash")
  inspect(resolve_language("yml"), content="yaml")
}

///|
test "resolve_language: passthrough" {
  inspect(resolve_language("typescript"), content="typescript")
  inspect(resolve_language("rust"), content="rust")
  inspect(resolve_language("python"), content="python")
}

///|
test "is_language_supported: common languages" {
  inspect(is_language_supported("typescript"), content="true")
  inspect(is_language_supported("json"), content="true")
  inspect(is_language_supported("html"), content="true")
  inspect(is_language_supported("css"), content="true")
  inspect(is_language_supported("rust"), content="true")
  inspect(is_language_supported("moonbit"), content="true")
}

///|
test "is_language_supported: aliases" {
  inspect(is_language_supported("js"), content="true")
  inspect(is_language_supported("ts"), content="true")
  inspect(is_language_supported("mbt"), content="true")
}

///|
test "decode_html_entities" {
  inspect(decode_html_entities("&lt;div&gt;"), content="<div>")
  inspect(decode_html_entities("&amp;"), content="&")
  inspect(decode_html_entities("&quot;text&quot;"), content="\"text\"")
  inspect(decode_html_entities("it&#39;s"), content="it's")
}

///|
test "generate_shiki_css: contains expected rules" {
  let css = generate_shiki_css()
  inspect(css.contains("pre.shiki"), content="true")
  inspect(css.contains("background-color"), content="true")
  inspect(css.contains(".code-block-wrapper"), content="true")
  inspect(css.contains("font-family"), content="true")
}

///|
test "highlight: produces HTML" {
  let h = create_default_highlighter()
  let html = h.highlight("let x = 1", "typescript")
  inspect(html.contains("<pre"), content="true")
  inspect(html.contains("</pre>"), content="true")
}

///|
test "highlight: unsupported language fallback" {
  let h = create_default_highlighter()
  let html = h.highlight("hello", "brainfuck")
  inspect(html.contains("data-lang=\"brainfuck\""), content="true")
  inspect(html.contains("hello"), content="true")
}
