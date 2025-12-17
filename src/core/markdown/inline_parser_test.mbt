///| Inline parser tests

test "parse inline text" {
  let inlines = parse_inlines("Hello World")
  inspect(inlines.length(), content="1")
  match inlines[0] {
    Inline::Text(content~, ..) => inspect(content, content="Hello World")
    _ => fail("Expected Text")
  }
}

test "parse emphasis with asterisk" {
  let inlines = parse_inlines("Hello *world*")
  inspect(inlines.length(), content="2")
  match inlines[1] {
    Inline::Emphasis(marker~, children~, ..) => {
      inspect(marker, content="Asterisk")
      inspect(children.length(), content="1")
    }
    _ => fail("Expected Emphasis")
  }
}

test "parse emphasis with underscore" {
  let inlines = parse_inlines("Hello _world_")
  inspect(inlines.length(), content="2")
  match inlines[1] {
    Inline::Emphasis(marker~, ..) => inspect(marker, content="Underscore")
    _ => fail("Expected Emphasis")
  }
}

test "parse strong with asterisk" {
  let inlines = parse_inlines("Hello **world**")
  inspect(inlines.length(), content="2")
  match inlines[1] {
    Inline::Strong(marker~, children~, ..) => {
      inspect(marker, content="Asterisk")
      inspect(children.length(), content="1")
    }
    _ => fail("Expected Strong")
  }
}

test "parse strong with underscore" {
  let inlines = parse_inlines("Hello __world__")
  inspect(inlines.length(), content="2")
  match inlines[1] {
    Inline::Strong(marker~, ..) => inspect(marker, content="Underscore")
    _ => fail("Expected Strong")
  }
}

test "parse inline code" {
  let inlines = parse_inlines("Hello `code` world")
  inspect(inlines.length(), content="3")
  match inlines[1] {
    Inline::Code(content~, backtick_count~, ..) => {
      inspect(content, content="code")
      inspect(backtick_count, content="1")
    }
    _ => fail("Expected Code")
  }
}

test "parse inline code with double backticks" {
  let inlines = parse_inlines("Use ``code with `backticks` inside``")
  match inlines[1] {
    Inline::Code(content~, backtick_count~, ..) => {
      inspect(backtick_count, content="2")
      inspect(content.contains("`"), content="true")
    }
    _ => fail("Expected Code")
  }
}

test "parse link" {
  let inlines = parse_inlines("Click [here](https://example.com)")
  inspect(inlines.length(), content="2")
  match inlines[1] {
    Inline::Link(url~, title~, children~, ..) => {
      inspect(url, content="https://example.com")
      inspect(title, content="")
      inspect(children.length(), content="1")
    }
    _ => fail("Expected Link")
  }
}

test "parse link with title" {
  let inlines = parse_inlines("[link](https://example.com \"Title\")")
  match inlines[0] {
    Inline::Link(url~, title~, ..) => {
      inspect(url, content="https://example.com")
      inspect(title, content="Title")
    }
    _ => fail("Expected Link")
  }
}

test "parse reference link" {
  let inlines = parse_inlines("[text][ref]")
  match inlines[0] {
    Inline::RefLink(label~, children~, ..) => {
      inspect(label, content="ref")
      inspect(children.length(), content="1")
    }
    _ => fail("Expected RefLink")
  }
}

test "parse image" {
  let inlines = parse_inlines("![alt text](image.png)")
  match inlines[0] {
    Inline::Image(alt~, url~, title~, ..) => {
      inspect(alt, content="alt text")
      inspect(url, content="image.png")
      inspect(title, content="")
    }
    _ => fail("Expected Image")
  }
}

test "parse image with title" {
  let inlines = parse_inlines("![alt](image.png \"Title\")")
  match inlines[0] {
    Inline::Image(alt~, url~, title~, ..) => {
      inspect(alt, content="alt")
      inspect(url, content="image.png")
      inspect(title, content="Title")
    }
    _ => fail("Expected Image")
  }
}

test "parse reference image" {
  let inlines = parse_inlines("![alt][ref]")
  match inlines[0] {
    Inline::RefImage(alt~, label~, ..) => {
      inspect(alt, content="alt")
      inspect(label, content="ref")
    }
    _ => fail("Expected RefImage")
  }
}

test "parse autolink URL" {
  let inlines = parse_inlines("<https://example.com>")
  match inlines[0] {
    Inline::Autolink(url~, is_email~, ..) => {
      inspect(url, content="https://example.com")
      inspect(is_email, content="false")
    }
    _ => fail("Expected Autolink")
  }
}

test "parse autolink email" {
  let inlines = parse_inlines("<user@example.com>")
  match inlines[0] {
    Inline::Autolink(url~, is_email~, ..) => {
      inspect(url, content="user@example.com")
      inspect(is_email, content="true")
    }
    _ => fail("Expected Autolink")
  }
}

test "parse strikethrough" {
  let inlines = parse_inlines("Hello ~~deleted~~ world")
  inspect(inlines.length(), content="3")
  match inlines[1] {
    Inline::Strikethrough(children~, ..) => {
      inspect(children.length(), content="1")
    }
    _ => fail("Expected Strikethrough")
  }
}

test "parse hard break two spaces" {
  let inlines = parse_inlines("Line 1  \nLine 2")
  // Should have: "Line 1", HardBreak, "Line 2"
  let has_hard_break = inlines.iter().any(fn(i) {
    match i {
      Inline::HardBreak(style=HardBreakStyle::TwoSpaces, ..) => true
      _ => false
    }
  })
  inspect(has_hard_break, content="true")
}

test "parse hard break backslash" {
  let inlines = parse_inlines("Line 1\\\nLine 2")
  let has_hard_break = inlines.iter().any(fn(i) {
    match i {
      Inline::HardBreak(style=HardBreakStyle::Backslash, ..) => true
      _ => false
    }
  })
  inspect(has_hard_break, content="true")
}

test "parse soft break" {
  let inlines = parse_inlines("Line 1\nLine 2")
  let has_soft_break = inlines.iter().any(fn(i) {
    match i {
      Inline::SoftBreak(..) => true
      _ => false
    }
  })
  inspect(has_soft_break, content="true")
}

test "parse escaped character" {
  let inlines = parse_inlines("Hello \\*not emphasis\\*")
  // Should parse as text, not emphasis
  let is_all_text = inlines.iter().all(fn(i) {
    match i {
      Inline::Text(..) => true
      _ => false
    }
  })
  inspect(is_all_text, content="true")
}

test "parse nested emphasis in link" {
  let inlines = parse_inlines("[**bold** link](url)")
  match inlines[0] {
    Inline::Link(children~, ..) => {
      // Should have Strong as first child
      match children[0] {
        Inline::Strong(..) => ()
        _ => fail("Expected Strong inside Link")
      }
    }
    _ => fail("Expected Link")
  }
}

test "parse mixed inline content" {
  let inlines = parse_inlines("Hello *world* and `code`")
  inspect(inlines.length() >= 4, content="true")
}
