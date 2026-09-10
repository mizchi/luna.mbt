///|
test "updated Markdown blocks retain their rendered content" {
  for
    source in [
      "$$\nx^2 < y\n$$\n", "> [!NOTE]\n> Keep this note.\n", ":::note Optional title\n**Body**\n:::\n",
      "MoonBit\n: A programming language\n", "# Heading\n\n{#intro .wide key=value}\n",
    ] {
    let (_, nodes) = parse_markdown_native(source)
    assert_eq(nodes.length(), 1)
    match nodes[0] {
      @markdown.MdNode::Html(html) =>
        assert_eq(html, @md_parser.md_to_html(source))
      _ => fail("Expected the Markdown extension's HTML")
    }
  }
}

///|
test "inline directives preserve attributes and escape their labels" {
  let inlines = @md_parser.parse_inlines(":badge[a < b]{.green level=high}")
  let node = convert_inline(inlines[0]).unwrap()
  match node {
    @markdown.MdNode::Html(html) => {
      assert_true(html.has_prefix("<span data-directive=\"badge\""))
      assert_true(html.contains("class=\"green\""))
      assert_true(html.contains("a &lt; b"))
      assert_true(html.has_suffix("</span>"))
    }
    _ => fail("Expected inline directive HTML")
  }
}
