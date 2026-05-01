///|
test "render_document wraps body with app container by default" {
  let html = render_document("App", "", "<p>hello</p>")
  assert_true(html.contains("<div id=\"app\"><p>hello</p></div>"))
}

///|
test "render_document can disable app container wrapping" {
  let html = render_document("App", "", "<p>hello</p>", wrap_in_app=false)
  assert_true(html.contains("<body><p>hello</p></body>"))
}

///|
test "render_template replaces all placeholders" {
  let tpl = "__LUNA_TITLE__|__LUNA_HEAD__|__LUNA_PRELOAD__|__LUNA_MAIN__"
  let result = render_template(tpl, "T", "H", "P", "M")
  assert_eq(result, "T|H|P|M")
}

///|
test "render_streaming_header includes loader url" {
  let header = render_streaming_header("App", "", "/__sol__/loader.js")
  assert_true(
    header.contains(
      "<script type=\"module\" src=\"/__sol__/loader.js\"></script>",
    ),
  )
}

///|
test "render_streaming_template_parts splits template and injects loader" {
  let tpl = "<html><head><title>__LUNA_TITLE__</title>__LUNA_PRELOAD____LUNA_HEAD__</head><body><main id=\"root\">__LUNA_MAIN__</main></body></html>"
  let result = render_streaming_template_parts(
    tpl, "App", "<meta name=\"x\" content=\"1\">", "<link rel=\"modulepreload\" href=\"/entry.js\">",
    "/__sol__/loader.js",
  )
  guard result is Some((header, footer)) else {
    fail("expected template parts")
  }
  assert_true(header.contains("<title>App</title>"))
  assert_true(header.contains("<meta name=\"x\" content=\"1\">"))
  assert_true(
    header.contains(
      "<script type=\"module\" src=\"/__sol__/loader.js\"></script>",
    ),
  )
  assert_true(header.contains("<main id=\"root\">"))
  assert_true(footer.contains("</main></body></html>"))
}

///|
test "render_streaming_template_parts returns None without main placeholder" {
  let tpl = "<html><body>No placeholder</body></html>"
  let result = render_streaming_template_parts(tpl, "App", "", "", "/loader.js")
  assert_true(result is None)
}

///|
test "escape_html_text escapes entities" {
  let escaped = escape_html_text("<>&\"'")
  assert_eq(escaped, "&lt;&gt;&amp;&quot;&#39;")
}

///|
test "escape_html_text returns empty string unchanged" {
  assert_eq(escape_html_text(""), "")
}

///|
test "escape_html_text leaves plain text unchanged" {
  assert_eq(escape_html_text("Hello World"), "Hello World")
}

///|
test "render_template escapes HTML in title" {
  let tpl = "<title>__LUNA_TITLE__</title>__LUNA_HEAD____LUNA_PRELOAD____LUNA_MAIN__"
  let result = render_template(tpl, "<script>alert(1)</script>", "", "", "")
  assert_true(result.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
  assert_false(result.contains("<script>"))
}

///|
test "render_document escapes HTML in title" {
  let html = render_document("<My & App>", "", "")
  assert_true(html.contains("&lt;My &amp; App&gt;"))
  assert_false(html.contains("<My"))
}

///|
test "render_streaming_header escapes HTML in title" {
  let header = render_streaming_header("<App & Co>", "", "/loader.js")
  assert_true(header.contains("&lt;App &amp; Co&gt;"))
}

///|
test "app_container wraps inner html" {
  let result = app_container("<p>test</p>")
  assert_eq(result, "<div id=\"app\"><p>test</p></div>")
}

///|
test "render_streaming_footer returns closing tags" {
  assert_eq(render_streaming_footer(), "</div></body></html>")
}
