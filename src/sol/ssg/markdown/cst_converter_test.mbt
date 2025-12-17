///| Tests for CST to MdNode converter

test "parse_markdown_native: basic paragraph" {
  let (fm, nodes) = parse_markdown_native("Hello World")
  inspect!(fm.title, content="None")
  inspect!(nodes.length(), content="1")
  match nodes[0] {
    @ssg.MdNode::Paragraph(children~) => {
      inspect!(children.length(), content="1")
      match children[0] {
        @ssg.MdNode::Text(text) => inspect!(text, content="Hello World")
        _ => fail!("Expected Text node")
      }
    }
    _ => fail!("Expected Paragraph node")
  }
}

test "parse_markdown_native: heading" {
  let (_, nodes) = parse_markdown_native("# Hello")
  inspect!(nodes.length(), content="1")
  match nodes[0] {
    @ssg.MdNode::Heading(level~, children~, id~) => {
      inspect!(level, content="1")
      inspect!(id, content="hello")
      inspect!(children.length(), content="1")
    }
    _ => fail!("Expected Heading node")
  }
}

test "parse_markdown_native: frontmatter" {
  let content = "---\ntitle: Test\ndescription: A test doc\n---\n\nHello"
  let (fm, nodes) = parse_markdown_native(content)
  inspect!(fm.title, content="Some(\"Test\")")
  inspect!(fm.description, content="Some(\"A test doc\")")
  inspect!(nodes.length(), content="1")
}

test "parse_markdown_native: code block" {
  let content = "```javascript\nconst x = 1;\n```"
  let (_, nodes) = parse_markdown_native(content)
  inspect!(nodes.length(), content="1")
  match nodes[0] {
    @ssg.MdNode::CodeBlock(lang~, code~) => {
      inspect!(lang, content="javascript")
      inspect!(code.trim_space().to_string(), content="const x = 1;")
    }
    _ => fail!("Expected CodeBlock node")
  }
}

test "parse_markdown_native: list" {
  let content = "- Item 1\n- Item 2\n- Item 3"
  let (_, nodes) = parse_markdown_native(content)
  inspect!(nodes.length(), content="1")
  match nodes[0] {
    @ssg.MdNode::List(ordered~, items~) => {
      inspect!(ordered, content="false")
      inspect!(items.length(), content="3")
    }
    _ => fail!("Expected List node")
  }
}

test "parse_markdown_native: ordered list" {
  let content = "1. First\n2. Second"
  let (_, nodes) = parse_markdown_native(content)
  inspect!(nodes.length(), content="1")
  match nodes[0] {
    @ssg.MdNode::List(ordered~, items~) => {
      inspect!(ordered, content="true")
      inspect!(items.length(), content="2")
    }
    _ => fail!("Expected List node")
  }
}

test "parse_markdown_native: emphasis and strong" {
  let content = "*italic* and **bold**"
  let (_, nodes) = parse_markdown_native(content)
  inspect!(nodes.length(), content="1")
  match nodes[0] {
    @ssg.MdNode::Paragraph(children~) => {
      // Should have: italic text, " and ", bold text
      inspect!(children.length() >= 3, content="true")
    }
    _ => fail!("Expected Paragraph node")
  }
}

test "parse_markdown_native: link" {
  let content = "[Link text](https://example.com)"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @ssg.MdNode::Paragraph(children~) =>
      match children[0] {
        @ssg.MdNode::Link(href~, children=link_children, ..) => {
          inspect!(href, content="https://example.com")
          inspect!(link_children.length(), content="1")
        }
        _ => fail!("Expected Link node")
      }
    _ => fail!("Expected Paragraph node")
  }
}

test "parse_markdown_native: image" {
  let content = "![Alt text](image.png \"Title\")"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @ssg.MdNode::Paragraph(children~) =>
      match children[0] {
        @ssg.MdNode::Image(src~, alt~, title~) => {
          inspect!(src, content="image.png")
          inspect!(alt, content="Alt text")
          inspect!(title, content="Title")
        }
        _ => fail!("Expected Image node")
      }
    _ => fail!("Expected Paragraph node")
  }
}

test "parse_markdown_native: blockquote" {
  let content = "> Quote text"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @ssg.MdNode::Blockquote(children~) => inspect!(children.length(), content="1")
    _ => fail!("Expected Blockquote node")
  }
}

test "parse_markdown_native: thematic break" {
  let content = "Before\n\n---\n\nAfter"
  let (_, nodes) = parse_markdown_native(content)
  // Should have: paragraph, thematic break, paragraph
  let mut found_hr = false
  for node in nodes {
    match node {
      @ssg.MdNode::ThematicBreak => found_hr = true
      _ => ()
    }
  }
  inspect!(found_hr, content="true")
}

test "parse_markdown_native: table" {
  let content = "| A | B |\n|---|---|\n| 1 | 2 |"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @ssg.MdNode::Table(headers~, rows~) => {
      inspect!(headers.length(), content="2")
      inspect!(rows.length(), content="1")
    }
    _ => fail!("Expected Table node")
  }
}

test "parse_markdown_native: inline code" {
  let content = "Use `code` here"
  let (_, nodes) = parse_markdown_native(content)
  match nodes[0] {
    @ssg.MdNode::Paragraph(children~) => {
      let mut found_code = false
      for child in children {
        match child {
          @ssg.MdNode::Code(code) => {
            inspect!(code, content="code")
            found_code = true
          }
          _ => ()
        }
      }
      inspect!(found_code, content="true")
    }
    _ => fail!("Expected Paragraph node")
  }
}
