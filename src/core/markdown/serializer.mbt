///| CST Serializer - Convert CST back to markdown text (lossless roundtrip)

///| Serialize document to markdown string
pub fn serialize(doc : Document) -> String {
  let buf = StringBuilder::new()

  // Serialize frontmatter if present
  match doc.frontmatter {
    Some(fm) => serialize_frontmatter(fm, buf)
    None => ()
  }

  // Serialize blocks
  for block in doc.children {
    serialize_block(block, buf)
  }

  buf.to_string()
}

///| Serialize frontmatter
fn serialize_frontmatter(fm : Frontmatter, buf : StringBuilder) -> Unit {
  buf.write_string("---\n")
  buf.write_string(fm.raw)
  if not(fm.raw.has_suffix("\n")) {
    buf.write_char('\n')
  }
  buf.write_string("---\n")
}

///| Write n copies of a character
fn write_chars(buf : StringBuilder, c : Char, n : Int) -> Unit {
  for i = 0; i < n; i = i + 1 {
    buf.write_char(c)
  }
}

///| Serialize a block
fn serialize_block(block : Block, buf : StringBuilder) -> Unit {
  match block {
    Block::ThematicBreak(marker~, count~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      write_chars(buf, marker, count)
      buf.write_string(trailing_trivia.content)
      if not(trailing_trivia.content.has_suffix("\n")) {
        buf.write_char('\n')
      }
    }

    Block::Heading(level~, style~, children~, closing_hashes~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      match style {
        HeadingStyle::Atx => {
          write_chars(buf, '#', level)
          buf.write_char(' ')
          serialize_inlines(children, buf)
          if closing_hashes > 0 {
            buf.write_char(' ')
            write_chars(buf, '#', closing_hashes)
          }
          buf.write_string(trailing_trivia.content)
          if not(trailing_trivia.content.has_suffix("\n")) {
            buf.write_char('\n')
          }
        }
        HeadingStyle::Setext => {
          serialize_inlines(children, buf)
          buf.write_char('\n')
          let underline_char = if level == 1 { '=' } else { '-' }
          // At least 3 chars for consistency
          write_chars(buf, underline_char, 3)
          buf.write_char('\n')
        }
      }
    }

    Block::Paragraph(children~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      serialize_inlines(children, buf)
      buf.write_string(trailing_trivia.content)
      if not(trailing_trivia.content.has_suffix("\n")) {
        buf.write_char('\n')
      }
    }

    Block::FencedCode(fence_marker~, fence_length~, info~, code~, indent~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      // Leading indent
      write_chars(buf, ' ', indent)
      // Opening fence
      let fence_char = match fence_marker {
        FenceMarker::Backtick => '`'
        FenceMarker::Tilde => '~'
      }
      write_chars(buf, fence_char, fence_length)
      if not(info.is_empty()) {
        buf.write_string(info)
      }
      buf.write_char('\n')
      // Code content
      buf.write_string(code)
      if not(code.is_empty()) && not(code.has_suffix("\n")) {
        buf.write_char('\n')
      }
      // Closing fence
      write_chars(buf, ' ', indent)
      write_chars(buf, fence_char, fence_length)
      buf.write_string(trailing_trivia.content)
      if not(trailing_trivia.content.has_suffix("\n")) {
        buf.write_char('\n')
      }
    }

    Block::IndentedCode(code~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      for line in code.split("\n") {
        buf.write_string("    ")
        buf.write_string(line.to_string())
        buf.write_char('\n')
      }
      buf.write_string(trailing_trivia.content)
    }

    Block::Blockquote(children~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      for child in children {
        // Serialize each block with > prefix
        let child_buf = StringBuilder::new()
        serialize_block(child, child_buf)
        let child_str = child_buf.to_string()
        for line in child_str.split("\n") {
          let line_str = line.to_string()
          if not(line_str.is_empty()) {
            buf.write_string("> ")
            buf.write_string(line_str)
            buf.write_char('\n')
          }
        }
      }
      buf.write_string(trailing_trivia.content)
    }

    Block::BulletList(marker~, items~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      let marker_char = match marker {
        BulletMarker::Dash => '-'
        BulletMarker::Asterisk => '*'
        BulletMarker::Plus => '+'
      }
      for item in items {
        // Write leading spaces for marker
        write_chars(buf, ' ', item.marker_offset)
        buf.write_char(marker_char)
        buf.write_char(' ')

        // Task list checkbox
        match item.checked {
          Some(true) => buf.write_string("[x] ")
          Some(false) => buf.write_string("[ ] ")
          None => ()
        }

        // Serialize item content
        for child in item.children {
          match child {
            Block::Paragraph(children=para_children, ..) =>
              serialize_inlines(para_children, buf)
            _ => serialize_block(child, buf)
          }
        }
        buf.write_char('\n')
      }
      buf.write_string(trailing_trivia.content)
    }

    Block::OrderedList(start~, delimiter~, items~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      let delim_char = match delimiter {
        OrderedDelimiter::Dot => '.'
        OrderedDelimiter::Paren => ')'
      }
      let mut num = start
      for item in items {
        // Write leading spaces for marker
        write_chars(buf, ' ', item.marker_offset)
        buf.write_string(num.to_string())
        buf.write_char(delim_char)
        buf.write_char(' ')
        // Serialize item content
        for child in item.children {
          match child {
            Block::Paragraph(children=para_children, ..) =>
              serialize_inlines(para_children, buf)
            _ => serialize_block(child, buf)
          }
        }
        buf.write_char('\n')
        num += 1
      }
      buf.write_string(trailing_trivia.content)
    }

    Block::HtmlBlock(html~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      buf.write_string(html)
      buf.write_string(trailing_trivia.content)
      if not(trailing_trivia.content.has_suffix("\n")) {
        buf.write_char('\n')
      }
    }

    Block::Table(header~, alignments~, rows~, leading_trivia~, trailing_trivia~, ..) => {
      buf.write_string(leading_trivia.content)
      // Header row
      buf.write_char('|')
      for cell in header {
        buf.write_char(' ')
        serialize_inlines(cell.children, buf)
        buf.write_string(" |")
      }
      buf.write_char('\n')
      // Separator row
      buf.write_char('|')
      for align in alignments {
        match align {
          TableAlign::Left => buf.write_string(":---|")
          TableAlign::Center => buf.write_string(":---:|")
          TableAlign::Right => buf.write_string("---:|")
          TableAlign::None => buf.write_string("---|")
        }
      }
      buf.write_char('\n')
      // Data rows
      for row in rows {
        buf.write_char('|')
        for cell in row {
          buf.write_char(' ')
          serialize_inlines(cell.children, buf)
          buf.write_string(" |")
        }
        buf.write_char('\n')
      }
      buf.write_string(trailing_trivia.content)
    }

    Block::BlankLines(count~, ..) => {
      for i = 0; i < count; i = i + 1 {
        buf.write_char('\n')
      }
    }
  }
}

///| Serialize inline content
fn serialize_inlines(inlines : Array[Inline], buf : StringBuilder) -> Unit {
  for inline in inlines {
    serialize_inline(inline, buf)
  }
}

///| Serialize a single inline element
fn serialize_inline(inline : Inline, buf : StringBuilder) -> Unit {
  match inline {
    Inline::Text(content~, ..) => buf.write_string(content)

    Inline::SoftBreak(..) => buf.write_char('\n')

    Inline::HardBreak(style~, ..) => {
      match style {
        HardBreakStyle::TwoSpaces => buf.write_string("  \n")
        HardBreakStyle::Backslash => buf.write_string("\\\n")
      }
    }

    Inline::Emphasis(marker~, children~, ..) => {
      let marker_char = match marker {
        EmphasisMarker::Asterisk => '*'
        EmphasisMarker::Underscore => '_'
      }
      buf.write_char(marker_char)
      serialize_inlines(children, buf)
      buf.write_char(marker_char)
    }

    Inline::Strong(marker~, children~, ..) => {
      let marker_char = match marker {
        EmphasisMarker::Asterisk => '*'
        EmphasisMarker::Underscore => '_'
      }
      buf.write_char(marker_char)
      buf.write_char(marker_char)
      serialize_inlines(children, buf)
      buf.write_char(marker_char)
      buf.write_char(marker_char)
    }

    Inline::Strikethrough(children~, ..) => {
      buf.write_string("~~")
      serialize_inlines(children, buf)
      buf.write_string("~~")
    }

    Inline::Code(content~, backtick_count~, ..) => {
      write_chars(buf, '`', backtick_count)
      buf.write_string(content)
      write_chars(buf, '`', backtick_count)
    }

    Inline::Link(children~, url~, title~, ..) => {
      buf.write_char('[')
      serialize_inlines(children, buf)
      buf.write_string("](")
      buf.write_string(url)
      if not(title.is_empty()) {
        buf.write_string(" \"")
        buf.write_string(title)
        buf.write_char('"')
      }
      buf.write_char(')')
    }

    Inline::RefLink(children~, label~, ..) => {
      buf.write_char('[')
      serialize_inlines(children, buf)
      buf.write_string("][")
      buf.write_string(label)
      buf.write_char(']')
    }

    Inline::Autolink(url~, is_email~, ..) => {
      buf.write_char('<')
      if is_email {
        buf.write_string("mailto:")
      }
      buf.write_string(url)
      buf.write_char('>')
    }

    Inline::Image(alt~, url~, title~, ..) => {
      buf.write_string("![")
      buf.write_string(alt)
      buf.write_string("](")
      buf.write_string(url)
      if not(title.is_empty()) {
        buf.write_string(" \"")
        buf.write_string(title)
        buf.write_char('"')
      }
      buf.write_char(')')
    }

    Inline::RefImage(alt~, label~, ..) => {
      buf.write_string("![")
      buf.write_string(alt)
      buf.write_string("][")
      buf.write_string(label)
      buf.write_char(']')
    }

    Inline::HtmlInline(html~, ..) => buf.write_string(html)
  }
}

///| Serialize link definitions
pub fn serialize_definitions(defs : Array[LinkDefinition]) -> String {
  let buf = StringBuilder::new()
  for def in defs {
    buf.write_char('[')
    buf.write_string(def.label)
    buf.write_string("]: ")
    buf.write_string(def.url)
    if not(def.title.is_empty()) {
      buf.write_string(" \"")
      buf.write_string(def.title)
      buf.write_char('"')
    }
    buf.write_char('\n')
  }
  buf.to_string()
}
