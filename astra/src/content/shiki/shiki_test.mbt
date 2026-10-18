///|
test "resolve_language: aliases" {
  inspect(@shiki.resolve_language("js"), content="typescript")
  inspect(@shiki.resolve_language("ts"), content="typescript")
  inspect(@shiki.resolve_language("mbt"), content="moonbit")
  inspect(@shiki.resolve_language("sh"), content="bash")
  inspect(@shiki.resolve_language("yml"), content="yaml")
}

///|
test "resolve_language: passthrough" {
  inspect(@shiki.resolve_language("typescript"), content="typescript")
  inspect(@shiki.resolve_language("rust"), content="rust")
  inspect(@shiki.resolve_language("python"), content="python")
}

///|
test "is_language_supported: common languages" {
  inspect(@shiki.is_language_supported("typescript"), content="true")
  inspect(@shiki.is_language_supported("json"), content="true")
  inspect(@shiki.is_language_supported("html"), content="true")
  inspect(@shiki.is_language_supported("css"), content="true")
  inspect(@shiki.is_language_supported("rust"), content="true")
  inspect(@shiki.is_language_supported("moonbit"), content="true")
}

///|
test "is_language_supported: aliases" {
  inspect(@shiki.is_language_supported("js"), content="true")
  inspect(@shiki.is_language_supported("ts"), content="true")
  inspect(@shiki.is_language_supported("mbt"), content="true")
}

///|
test "decode_html_entities" {
  inspect(@shiki.decode_html_entities("&lt;div&gt;"), content="<div>")
  inspect(@shiki.decode_html_entities("&amp;"), content="&")
  inspect(@shiki.decode_html_entities("&quot;text&quot;"), content="\"text\"")
  inspect(@shiki.decode_html_entities("it&#39;s"), content="it's")
}

///|
test "generate_shiki_css: contains expected rules" {
  let css = @shiki.generate_shiki_css()
  inspect(css.contains("pre.shiki"), content="true")
  inspect(css.contains("background-color"), content="true")
  inspect(css.contains(".code-block-wrapper"), content="true")
  inspect(css.contains("font-family"), content="true")
}

///|
test "highlight: produces HTML" {
  let h = @shiki.create_default_highlighter()
  let html = h.highlight("let x = 1", "typescript")
  inspect(html.contains("<pre"), content="true")
  inspect(html.contains("</pre>"), content="true")
}

///|
test "highlight: unsupported language fallback" {
  let h = @shiki.create_default_highlighter()
  let html = h.highlight("hello", "brainfuck")
  inspect(html.contains("data-lang=\"brainfuck\""), content="true")
  inspect(html.contains("hello"), content="true")
}
