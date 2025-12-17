///| Block parser tests

test "parse heading" {
  let result = parse("# Hello World\n")
  let blocks = result.document.children
  inspect(blocks.length(), content="1")
  match blocks[0] {
    Block::Heading(level~, style~, children~, ..) => {
      inspect(level, content="1")
      inspect(style, content="Atx")
      inspect(children.length(), content="1")
      match children[0] {
        Inline::Text(content~, ..) => inspect(content, content="Hello World")
        _ => fail("Expected text")
      }
    }
    _ => fail("Expected heading")
  }
}

test "parse heading level 2-6" {
  for level = 2; level <= 6; level = level + 1 {
    let prefix = String::make(level, '#')
    let result = parse("\{prefix} Test\n")
    match result.document.children[0] {
      Block::Heading(level=l, ..) => inspect(l == level, content="true")
      _ => fail("Expected heading")
    }
  }
}

test "parse heading with closing hashes" {
  let result = parse("## Title ##\n")
  match result.document.children[0] {
    Block::Heading(level~, closing_hashes~, ..) => {
      inspect(level, content="2")
      inspect(closing_hashes, content="2")
    }
    _ => fail("Expected heading")
  }
}

test "parse paragraph" {
  let result = parse("Hello world.\n")
  match result.document.children[0] {
    Block::Paragraph(children~, ..) => {
      match children[0] {
        Inline::Text(content~, ..) => inspect(content, content="Hello world.")
        _ => fail("Expected text")
      }
    }
    _ => fail("Expected paragraph")
  }
}

test "parse multiline paragraph" {
  let result = parse("Line 1\nLine 2\n")
  match result.document.children[0] {
    Block::Paragraph(children~, ..) => {
      // With inline parsing: "Line 1" + SoftBreak + "Line 2"
      inspect(children.length() >= 2, content="true")
      match children[0] {
        Inline::Text(content~, ..) => inspect(content, content="Line 1")
        _ => fail("Expected text")
      }
    }
    _ => fail("Expected paragraph")
  }
}

test "parse fenced code block" {
  let result = parse("```js\nconsole.log('hello');\n```\n")
  match result.document.children[0] {
    Block::FencedCode(info~, code~, fence_marker~, fence_length~, ..) => {
      inspect(info, content="js")
      inspect(code, content="console.log('hello');\n")
      inspect(fence_marker, content="Backtick")
      inspect(fence_length, content="3")
    }
    _ => fail("Expected fenced code")
  }
}

test "parse fenced code with tilde" {
  let result = parse("~~~python\nprint('hello')\n~~~\n")
  match result.document.children[0] {
    Block::FencedCode(info~, fence_marker~, ..) => {
      inspect(info, content="python")
      inspect(fence_marker, content="Tilde")
    }
    _ => fail("Expected fenced code")
  }
}

test "parse fenced code with filename" {
  let result = parse("```json:package.json\n{\"name\": \"test\"}\n```\n")
  match result.document.children[0] {
    Block::FencedCode(info~, ..) => {
      inspect(info, content="json:package.json")
    }
    _ => fail("Expected fenced code")
  }
}

test "parse thematic break" {
  // Thematic break after content to avoid frontmatter confusion
  let result = parse("text\n\n---\n")
  let children = result.document.children
  // Find the thematic break
  let mut found = false
  for block in children {
    match block {
      Block::ThematicBreak(marker~, count~, ..) => {
        inspect(marker == '-', content="true")
        inspect(count, content="3")
        found = true
      }
      _ => ()
    }
  }
  inspect(found, content="true")
}

test "parse thematic break with asterisk" {
  let result = parse("***\n")
  match result.document.children[0] {
    Block::ThematicBreak(marker~, ..) => {
      inspect(marker == '*', content="true")
    }
    _ => fail("Expected thematic break")
  }
}

test "parse blockquote" {
  let result = parse("> Quote\n")
  match result.document.children[0] {
    Block::Blockquote(children~, ..) => {
      inspect(children.length(), content="1")
      match children[0] {
        Block::Paragraph(children=p_children, ..) => {
          match p_children[0] {
            Inline::Text(content~, ..) => inspect(content, content="Quote")
            _ => fail("Expected text")
          }
        }
        _ => fail("Expected paragraph in blockquote")
      }
    }
    _ => fail("Expected blockquote")
  }
}

test "parse bullet list" {
  let result = parse("- Item 1\n- Item 2\n")
  match result.document.children[0] {
    Block::BulletList(marker~, items~, tight~, ..) => {
      inspect(marker, content="Dash")
      inspect(items.length(), content="2")
      inspect(tight, content="true")
    }
    _ => fail("Expected bullet list")
  }
}

test "parse ordered list" {
  let result = parse("1. First\n2. Second\n")
  match result.document.children[0] {
    Block::OrderedList(start~, delimiter~, items~, ..) => {
      inspect(start, content="1")
      inspect(delimiter, content="Dot")
      inspect(items.length(), content="2")
    }
    _ => fail("Expected ordered list")
  }
}

test "parse indented code" {
  let result = parse("    code line\n    more code\n")
  match result.document.children[0] {
    Block::IndentedCode(code~, ..) => {
      inspect(code, content="code line\nmore code")
    }
    _ => fail("Expected indented code")
  }
}

test "parse setext heading h1" {
  let result = parse("Title\n=====\n")
  match result.document.children[0] {
    Block::Heading(level~, style~, ..) => {
      inspect(level, content="1")
      inspect(style, content="Setext")
    }
    _ => fail("Expected setext heading")
  }
}

test "parse setext heading h2" {
  let result = parse("Title\n-----\n")
  match result.document.children[0] {
    Block::Heading(level~, style~, ..) => {
      inspect(level, content="2")
      inspect(style, content="Setext")
    }
    _ => fail("Expected setext heading")
  }
}

test "parse frontmatter" {
  let result = parse("---\ntitle: Hello\nauthor: World\n---\n# Content\n")
  match result.document.frontmatter {
    Some(fm) => {
      inspect(fm.entries.length(), content="2")
      let (k1, v1) = fm.entries[0]
      inspect(k1, content="title")
      inspect(v1, content="Hello")
    }
    None => fail("Expected frontmatter")
  }
}

test "parse link definition" {
  let result = parse("[link]: https://example.com \"Title\"\n")
  inspect(result.definitions.length(), content="1")
  let def = result.definitions[0]
  inspect(def.label, content="link")
  inspect(def.url, content="https://example.com")
  inspect(def.title, content="Title")
}

test "parse mixed content" {
  let result = parse("# Title\n\nParagraph text.\n\n```js\ncode\n```\n")
  let children = result.document.children
  // Should have: Heading, BlankLines, Paragraph, BlankLines, FencedCode
  let mut heading_count = 0
  let mut para_count = 0
  let mut code_count = 0
  for block in children {
    match block {
      Block::Heading(..) => heading_count += 1
      Block::Paragraph(..) => para_count += 1
      Block::FencedCode(..) => code_count += 1
      _ => ()
    }
  }
  inspect(heading_count, content="1")
  inspect(para_count, content="1")
  inspect(code_count, content="1")
}

test "parse simple table" {
  let source = "| A | B |\n|---|---|\n| 1 | 2 |\n"
  let result = parse(source)
  match result.document.children[0] {
    Block::Table(header~, alignments~, rows~, ..) => {
      inspect(header.length(), content="2")
      inspect(alignments.length(), content="2")
      inspect(rows.length(), content="1")
    }
    _ => fail("Expected Table")
  }
}

test "parse table with alignment" {
  let source = "| Left | Center | Right |\n|:---|:---:|---:|\n| a | b | c |\n"
  let result = parse(source)
  match result.document.children[0] {
    Block::Table(alignments~, ..) => {
      inspect(alignments[0], content="Left")
      inspect(alignments[1], content="Center")
      inspect(alignments[2], content="Right")
    }
    _ => fail("Expected Table")
  }
}

test "parse table with multiple rows" {
  let source = "| H1 | H2 |\n|---|---|\n| R1C1 | R1C2 |\n| R2C1 | R2C2 |\n| R3C1 | R3C2 |\n"
  let result = parse(source)
  match result.document.children[0] {
    Block::Table(rows~, header~, ..) => {
      inspect(header.length(), content="2")
      inspect(rows.length(), content="3")
    }
    _ => fail("Expected Table")
  }
}

test "parse table with inline formatting" {
  let source = "| **Bold** | *Italic* |\n|---|---|\n| `code` | [link](url) |\n"
  let result = parse(source)
  match result.document.children[0] {
    Block::Table(header~, rows~, ..) => {
      // Header cell should have Strong
      match header[0].children[0] {
        Inline::Strong(..) => ()
        _ => fail("Expected Strong in header")
      }
      // Data cell should have Code
      match rows[0][0].children[0] {
        Inline::Code(..) => ()
        _ => fail("Expected Code in cell")
      }
    }
    _ => fail("Expected Table")
  }
}

test "serialize table roundtrip" {
  let source = "| A | B |\n|:---|---:|\n| 1 | 2 |\n"
  let result = parse(source)
  let output = serialize(result.document)
  inspect(output.contains("| A |"), content="true")
  inspect(output.contains(":---|"), content="true")
  inspect(output.contains("---:|"), content="true")
}
