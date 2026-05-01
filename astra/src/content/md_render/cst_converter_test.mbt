//

///|
/// Tests for CST to MdNode converter
test "parse_markdown_native: basic paragraph" {
  let (fm, nodes) = parse_markdown_native("Hello World")
  inspect(fm.title, content="None")
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @markdown.MdNode::Paragraph(children~) => {
      inspect(children.length(), content="1")
      match children[0] {
        @markdown.MdNode::Text(text) => inspect(text, content="Hello World")
        _ => fail("Expected Text node")
      }
    }
    _ => fail("Expected Paragraph node")
  }
}

///|
test "parse_markdown_native: heading" {
  let (_, nodes) = parse_markdown_native("# Hello")
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @markdown.MdNode::Heading(level~, children~, id~) => {
      inspect(level, content="1")
      inspect(id, content="hello")
      inspect(children.length(), content="1")
    }
    _ => fail("Expected Heading node")
  }
}

///|
test "parse_markdown_native: frontmatter" {
  let content = "---\ntitle: Test\ndescription: A test doc\n---\n\nHello"
  let (fm, nodes) = parse_markdown_native(content)
  inspect(fm.title, content="Some(\"Test\")")
  inspect(fm.description, content="Some(\"A test doc\")")
  inspect(nodes.length(), content="1")
}

///|
test "parse_markdown_native: code block" {
  let content = "```javascript\nconst x = 1;\n```"
  let (_, nodes) = parse_markdown_native(content)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @markdown.MdNode::CodeBlock(lang~, code~) => {
      inspect(lang, content="javascript")
      inspect(code.trim(chars=" \t\n\r").to_string(), content="const x = 1;")
    }
    _ => fail("Expected CodeBlock node")
  }
}

///|
test "parse_markdown_native: list" {
  let content = "- Item 1\n- Item 2\n- Item 3"
  let (_, nodes) = parse_markdown_native(content)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @markdown.MdNode::List(ordered~, items~) => {
      inspect(ordered, content="false")
      inspect(items.length(), content="3")
    }
    _ => fail("Expected List node")
  }
}

///|
test "parse_markdown_native: ordered list" {
  let content = "1. First\n2. Second"
  let (_, nodes) = parse_markdown_native(content)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @markdown.MdNode::List(ordered~, items~) => {
      inspect(ordered, content="true")
      inspect(items.length(), content="2")
    }
    _ => fail("Expected List node")
  }
}

///|
test "parse_markdown_native: emphasis and strong" {
  let content = "*italic* and **bold**"
  let (_, nodes) = parse_markdown_native(content)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @markdown.MdNode::Paragraph(children~) =>
      // Should have: italic text, " and ", bold text
      inspect(children.length() >= 3, content="true")
    _ => fail("Expected Paragraph node")
  }
}

///|
test "parse_markdown_native: link" {
  let content = "[Link text](https://example.com)"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @markdown.MdNode::Paragraph(children~) =>
      match children[0] {
        @markdown.MdNode::Link(href~, children=link_children, ..) => {
          inspect(href, content="https://example.com")
          inspect(link_children.length(), content="1")
        }
        _ => fail("Expected Link node")
      }
    _ => fail("Expected Paragraph node")
  }
}

///|
test "parse_markdown_native: image" {
  let content = "![Alt text](image.png \"Title\")"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @markdown.MdNode::Paragraph(children~) =>
      match children[0] {
        @markdown.MdNode::Image(src~, alt~, title~) => {
          inspect(src, content="image.png")
          inspect(alt, content="Alt text")
          inspect(title, content="Title")
        }
        _ => fail("Expected Image node")
      }
    _ => fail("Expected Paragraph node")
  }
}

///|
test "parse_markdown_native: blockquote" {
  let content = "> Quote text"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @markdown.MdNode::Blockquote(children~) =>
      inspect(children.length(), content="1")
    _ => fail("Expected Blockquote node")
  }
}

///|
test "parse_markdown_native: thematic break" {
  let content = "Before\n\n---\n\nAfter"
  let (_, nodes) = parse_markdown_native(content)
  // Should have: paragraph, thematic break, paragraph
  let mut found_hr = false
  for node in nodes {
    match node {
      @markdown.MdNode::ThematicBreak => found_hr = true
      _ => ()
    }
  }
  inspect(found_hr, content="true")
}

///|
test "parse_markdown_native: table" {
  let content = "| A | B |\n|---|---|\n| 1 | 2 |"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @markdown.MdNode::Table(headers~, rows~) => {
      inspect(headers.length(), content="2")
      inspect(rows.length(), content="1")
    }
    _ => fail("Expected Table node")
  }
}

///|
test "parse_markdown_native: inline code" {
  let content = "Use `code` here"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @markdown.MdNode::Paragraph(children~) => {
      let mut found_code = false
      for child in children {
        match child {
          @markdown.MdNode::Code(code) => {
            inspect(code, content="code")
            found_code = true
          }
          _ => ()
        }
      }
      inspect(found_code, content="true")
    }
    _ => fail("Expected Paragraph node")
  }
}

// =============================================================================
// Info String Parsing Tests
// =============================================================================

///|
test "parse_code_block_info: lang only" {
  let info = parse_code_block_info("javascript")
  inspect(info.lang, content="javascript")
  inspect(info.filename, content="")
  inspect(info.meta, content="")
}

///|
test "parse_code_block_info: lang with filename" {
  let info = parse_code_block_info("js:app.js")
  inspect(info.lang, content="js")
  inspect(info.filename, content="app.js")
  inspect(info.meta, content="")
}

///|
test "parse_code_block_info: lang with path filename" {
  let info = parse_code_block_info("typescript:src/index.ts")
  inspect(info.lang, content="typescript")
  inspect(info.filename, content="src/index.ts")
  inspect(info.meta, content="")
}

///|
test "parse_code_block_info: lang with meta" {
  let info = parse_code_block_info("js {highlight=[1,3]}")
  inspect(info.lang, content="js")
  inspect(info.filename, content="")
  inspect(info.meta, content="{highlight=[1,3]}")
}

///|
test "parse_code_block_info: lang, filename, and meta" {
  let info = parse_code_block_info("ts:index.ts {highlight=[1,3]}")
  inspect(info.lang, content="ts")
  inspect(info.filename, content="index.ts")
  inspect(info.meta, content="{highlight=[1,3]}")
}

///|
test "parse_code_block_info: empty string" {
  let info = parse_code_block_info("")
  inspect(info.lang, content="")
  inspect(info.filename, content="")
  inspect(info.meta, content="")
}

///|
test "parse_code_block_info: whitespace only" {
  let info = parse_code_block_info("  ")
  inspect(info.lang, content="")
  inspect(info.filename, content="")
  inspect(info.meta, content="")
}

///|
test "parse_code_block_info: json package.json" {
  let info = parse_code_block_info("json:package.json")
  inspect(info.lang, content="json")
  inspect(info.filename, content="package.json")
  inspect(info.meta, content="")
}
