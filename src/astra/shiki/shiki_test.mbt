//

///|
/// Shiki binding tests
test "resolve_language: aliases" {
  inspect(resolve_language("js"), content="javascript")
  inspect(resolve_language("ts"), content="typescript")
  inspect(resolve_language("mbt"), content="rust")
  inspect(resolve_language("moonbit"), content="rust")
  inspect(resolve_language("sh"), content="bash")
  inspect(resolve_language("yml"), content="yaml")
}

///|
test "resolve_language: passthrough" {
  inspect(resolve_language("javascript"), content="javascript")
  inspect(resolve_language("rust"), content="rust")
  inspect(resolve_language("python"), content="python")
}

///|
test "is_language_supported: common languages" {
  inspect(is_language_supported("javascript"), content="true")
  inspect(is_language_supported("typescript"), content="true")
  inspect(is_language_supported("json"), content="true")
  inspect(is_language_supported("html"), content="true")
  inspect(is_language_supported("css"), content="true")
  inspect(is_language_supported("rust"), content="true")
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
  inspect(css.contains("--shiki-light"), content="true")
  inspect(css.contains("--shiki-dark"), content="true")
  inspect(css.contains("html.dark"), content="true")
  inspect(css.contains(".code-block-wrapper"), content="true")
}
