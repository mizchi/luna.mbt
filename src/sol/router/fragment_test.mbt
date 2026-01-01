// Tests for Sol Fragment Response
//
// Tests for render_fragment_response which generates HTML fragments
// for CSR navigation with X-Sol-Fragment header

// =============================================================================
// render_fragment_response Tests
// =============================================================================

///|
test "render_fragment_response - basic content" {
  let node = @luna.h("div", [], [@luna.text("Hello, World!")])
  let html = @router.render_fragment_response(node, "Test Page", false)
  // Should contain main outlet template
  inspect(html.contains("<template data-sol-outlet=\"main\">"), content="true")
  inspect(html.contains("</template>"), content="true")
  // Should contain title template
  inspect(html.contains("<template data-sol-title>"), content="true")
  inspect(html.contains("Test Page"), content="true")
}

///|
test "render_fragment_response - escapes HTML in title" {
  let node = @luna.h("div", [], [@luna.text("Content")])
  let html = @router.render_fragment_response(
    node, "<script>alert('xss')</script>", false,
  )
  // Title should be escaped
  inspect(html.contains("&lt;script&gt;"), content="true")
  inspect(html.contains("<script>") && html.contains("alert"), content="false")
}

///|
test "render_fragment_response - special characters in title" {
  let node = @luna.h("div", [], [])
  let html = @router.render_fragment_response(
    node, "Tom & Jerry's \"Adventure\"", false,
  )
  // Should escape &, ', "
  inspect(html.contains("&amp;"), content="true")
  inspect(html.contains("&#39;"), content="true")
  inspect(html.contains("&quot;"), content="true")
}

///|
test "render_fragment_response - without hydration" {
  let node = @luna.h("p", [], [@luna.text("Simple text")])
  let html = @router.render_fragment_response(node, "Title", false)
  // Should contain the content
  inspect(html.contains("<p>"), content="true")
  inspect(html.contains("Simple text"), content="true")
}

///|
test "render_fragment_response - with hydration" {
  let node = @luna.h("p", [], [@luna.text("Hydrated content")])
  let html = @router.render_fragment_response(node, "Title", true)
  // Should contain the content (hydration adds data attributes)
  inspect(html.contains("Hydrated content"), content="true")
}

///|
test "render_fragment_response - nested elements" {
  let node = @luna.h("article", [], [
    @luna.h("h1", [], [@luna.text("Heading")]),
    @luna.h("p", [], [@luna.text("Paragraph 1")]),
    @luna.h("p", [], [@luna.text("Paragraph 2")]),
  ])
  let html = @router.render_fragment_response(node, "Article", false)
  inspect(html.contains("<article>"), content="true")
  inspect(html.contains("<h1>"), content="true")
  inspect(html.contains("Heading"), content="true")
  inspect(html.contains("Paragraph 1"), content="true")
  inspect(html.contains("Paragraph 2"), content="true")
}

///|
test "render_fragment_response - with attributes" {
  let node = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("container")),
      ("id", @luna.attr_static("main")),
    ],
    [@luna.text("Content")],
  )
  let html = @router.render_fragment_response(node, "Title", false)
  inspect(html.contains("class=\"container\""), content="true")
  inspect(html.contains("id=\"main\""), content="true")
}

///|
test "render_fragment_response - empty title" {
  let node = @luna.h("div", [], [])
  let html = @router.render_fragment_response(node, "", false)
  inspect(html.contains("<template data-sol-title>"), content="true")
  inspect(html.contains("</template>"), content="true")
}

///|
test "render_fragment_response - unicode title" {
  let node = @luna.h("div", [], [])
  let html = @router.render_fragment_response(
    node, "日本語タイトル", false,
  )
  inspect(html.contains("日本語タイトル"), content="true")
}

///|
test "render_fragment_response - structure order" {
  let node = @luna.h("div", [], [@luna.text("Content")])
  let html = @router.render_fragment_response(node, "Title", false)
  // Main outlet should come before title template
  let main_pos = html.find("<template data-sol-outlet=\"main\">")
  let title_pos = html.find("<template data-sol-title>")
  guard main_pos is Some(m) else { fail("Expected main outlet") }
  guard title_pos is Some(t) else { fail("Expected title template") }
  inspect(m < t, content="true")
}
