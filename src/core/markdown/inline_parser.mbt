///| Inline-level markdown parser
///| Parses emphasis, strong, code, links, images, etc.

///| Parse inline content from text
pub fn parse_inlines(text : String) -> Array[Inline] {
  let scanner = Scanner::new(text)
  let parser = InlineParser::new(scanner)
  parser.parse()
}

///| Inline parser state
priv struct InlineParser {
  scanner : Scanner
}

fn InlineParser::new(scanner : Scanner) -> InlineParser {
  { scanner, }
}

///| Parse all inline content
fn InlineParser::parse(self : InlineParser) -> Array[Inline] {
  let inlines : Array[Inline] = []

  while not(self.scanner.is_eof()) {
    match self.parse_inline() {
      Some(inline) => inlines.push(inline)
      None => {
        // Consume single character as text
        let start = self.scanner.pos
        match self.scanner.consume() {
          Some(c) => {
            // Merge with previous text if possible
            let text = String::make(1, c)
            match inlines.last() {
              Some(Inline::Text(content~, span~)) => {
                // Merge with previous text
                let _ = inlines.pop()
                inlines.push(Inline::Text(
                  content=content + text,
                  span=Span::new(span.from, self.scanner.pos),
                ))
              }
              _ => {
                inlines.push(Inline::Text(
                  content=text,
                  span=Span::new(start, self.scanner.pos),
                ))
              }
            }
          }
          None => break
        }
      }
    }
  }

  inlines
}

///| Parse a single inline element
fn InlineParser::parse_inline(self : InlineParser) -> Inline? {
  let start = self.scanner.pos

  match self.scanner.peek() {
    // Backslash escape
    Some('\\') => self.try_parse_escape(start)

    // Code span
    Some('`') => self.try_parse_code_span(start)

    // Emphasis/Strong with asterisk
    Some('*') => self.try_parse_emphasis(start, '*')

    // Emphasis/Strong with underscore
    Some('_') => self.try_parse_emphasis(start, '_')

    // Strikethrough
    Some('~') => self.try_parse_strikethrough(start)

    // Link or Image
    Some('[') => self.try_parse_link(start)
    Some('!') => self.try_parse_image(start)

    // Autolink
    Some('<') => self.try_parse_autolink(start)

    // Hard break (two spaces at end of line)
    Some(' ') => self.try_parse_hard_break(start)

    // Soft break (newline)
    Some('\n') => {
      self.scanner.advance(1)
      Some(Inline::SoftBreak(span=Span::new(start, self.scanner.pos)))
    }

    _ => None
  }
}

///| Try to parse backslash escape
fn InlineParser::try_parse_escape(self : InlineParser, start : Int) -> Inline? {
  self.scanner.advance(1)  // Skip backslash

  match self.scanner.peek() {
    Some('\n') => {
      // Backslash + newline = hard break
      self.scanner.advance(1)
      Some(Inline::HardBreak(
        style=HardBreakStyle::Backslash,
        span=Span::new(start, self.scanner.pos),
      ))
    }
    Some(c) if is_punctuation(c) => {
      // Escaped punctuation becomes literal text
      self.scanner.advance(1)
      Some(Inline::Text(
        content=String::make(1, c),
        span=Span::new(start, self.scanner.pos),
      ))
    }
    _ => {
      // Not a valid escape, return backslash as text
      Some(Inline::Text(
        content="\\",
        span=Span::new(start, self.scanner.pos),
      ))
    }
  }
}

///| Try to parse code span
fn InlineParser::try_parse_code_span(self : InlineParser, start : Int) -> Inline? {
  // Count opening backticks
  let backtick_count = self.scanner.count_char('`')
  if backtick_count == 0 {
    return None
  }
  self.scanner.advance(backtick_count)

  // Find closing backticks
  let content_buf = StringBuilder::new()

  while not(self.scanner.is_eof()) {
    let closing_count = self.scanner.count_char('`')
    if closing_count == backtick_count {
      // Found matching closing backticks
      let content = content_buf.to_string()
      self.scanner.advance(closing_count)

      // Trim single leading/trailing space if present and content has them
      let trimmed = if content.length() >= 2 {
        let first = content.get_char(0)
        let last = content.get_char(content.length() - 1)
        if first == Some(' ') && last == Some(' ') {
          content.unsafe_substring(start=1, end=content.length() - 1)
        } else {
          content
        }
      } else {
        content
      }

      return Some(Inline::Code(
        content=trimmed,
        backtick_count~,
        span=Span::new(start, self.scanner.pos),
      ))
    } else if closing_count > 0 {
      // Wrong number of backticks, include them in content
      for i = 0; i < closing_count; i = i + 1 {
        content_buf.write_char('`')
      }
      self.scanner.advance(closing_count)
    } else {
      // Regular character
      match self.scanner.consume() {
        Some(c) => content_buf.write_char(c)
        None => break
      }
    }
  }

  // No closing backticks found, restore position
  self.scanner.restore(start)
  None
}

///| Try to parse emphasis or strong
fn InlineParser::try_parse_emphasis(self : InlineParser, start : Int, marker_char : Char) -> Inline? {
  // Count opening markers
  let marker_count = self.scanner.count_char(marker_char)
  if marker_count == 0 {
    return None
  }

  // Only handle 1 or 2 markers (emphasis or strong)
  let is_strong = marker_count >= 2
  let consume_count = if is_strong { 2 } else { 1 }
  self.scanner.advance(consume_count)

  // Check if followed by whitespace (not valid opener)
  match self.scanner.peek() {
    Some(' ') | Some('\t') | Some('\n') | None => {
      self.scanner.restore(start)
      return None
    }
    _ => ()
  }

  // Parse content until closing marker
  let children = self.parse_until_closing_marker(marker_char, consume_count)

  if children.is_empty() {
    self.scanner.restore(start)
    return None
  }

  let marker = if marker_char == '*' {
    EmphasisMarker::Asterisk
  } else {
    EmphasisMarker::Underscore
  }

  if is_strong {
    Some(Inline::Strong(
      marker~,
      children~,
      span=Span::new(start, self.scanner.pos),
    ))
  } else {
    Some(Inline::Emphasis(
      marker~,
      children~,
      span=Span::new(start, self.scanner.pos),
    ))
  }
}

///| Parse content until closing marker
fn InlineParser::parse_until_closing_marker(
  self : InlineParser,
  marker_char : Char,
  marker_count : Int
) -> Array[Inline] {
  let children : Array[Inline] = []
  let text_buf = StringBuilder::new()
  let text_start = self.scanner.pos

  while not(self.scanner.is_eof()) {
    // Check for closing marker
    let closing_count = self.scanner.count_char(marker_char)
    if closing_count >= marker_count {
      // Check if preceded by non-whitespace
      let prev_char = self.scanner.peek_at(-1)
      match prev_char {
        Some(' ') | Some('\t') | Some('\n') => ()  // Not valid closer
        _ => {
          // Valid closer - flush text and consume markers
          if not(text_buf.is_empty()) {
            children.push(Inline::Text(
              content=text_buf.to_string(),
              span=Span::new(text_start, self.scanner.pos),
            ))
          }
          self.scanner.advance(marker_count)
          return children
        }
      }
    }

    // Handle nested inline elements
    match self.scanner.peek() {
      Some('`') => {
        // Flush text before inline
        if not(text_buf.is_empty()) {
          children.push(Inline::Text(
            content=text_buf.to_string(),
            span=Span::new(text_start, self.scanner.pos),
          ))
        }
        let nested_start = self.scanner.pos
        match self.try_parse_code_span(nested_start) {
          Some(code) => {
            children.push(code)
            continue
          }
          None => ()
        }
      }
      Some('[') => {
        if not(text_buf.is_empty()) {
          children.push(Inline::Text(
            content=text_buf.to_string(),
            span=Span::new(text_start, self.scanner.pos),
          ))
        }
        let nested_start = self.scanner.pos
        match self.try_parse_link(nested_start) {
          Some(link) => {
            children.push(link)
            continue
          }
          None => ()
        }
      }
      Some('\n') => {
        // Newline ends emphasis in most cases
        break
      }
      _ => ()
    }

    // Regular character
    match self.scanner.consume() {
      Some(c) => text_buf.write_char(c)
      None => break
    }
  }

  // No closing marker found
  []
}

///| Try to parse strikethrough
fn InlineParser::try_parse_strikethrough(self : InlineParser, start : Int) -> Inline? {
  // Need exactly two tildes
  if self.scanner.count_char('~') < 2 {
    return None
  }
  self.scanner.advance(2)

  // Parse content until closing ~~
  let content_buf = StringBuilder::new()
  let content_start = self.scanner.pos

  while not(self.scanner.is_eof()) {
    if self.scanner.count_char('~') >= 2 {
      // Found closing
      let content = content_buf.to_string()
      if content.is_empty() {
        self.scanner.restore(start)
        return None
      }
      self.scanner.advance(2)

      let children = [Inline::Text(
        content~,
        span=Span::new(content_start, self.scanner.pos - 2),
      )]

      return Some(Inline::Strikethrough(
        children~,
        span=Span::new(start, self.scanner.pos),
      ))
    }

    match self.scanner.consume() {
      Some('\n') => break  // Newline ends strikethrough
      Some(c) => content_buf.write_char(c)
      None => break
    }
  }

  self.scanner.restore(start)
  None
}

///| Try to parse link
fn InlineParser::try_parse_link(self : InlineParser, start : Int) -> Inline? {
  self.scanner.advance(1)  // Skip [

  // Parse link text
  let text_buf = StringBuilder::new()
  let mut bracket_depth = 1

  while not(self.scanner.is_eof()) && bracket_depth > 0 {
    match self.scanner.peek() {
      Some('[') => {
        bracket_depth += 1
        text_buf.write_char('[')
        self.scanner.advance(1)
      }
      Some(']') => {
        bracket_depth -= 1
        if bracket_depth > 0 {
          text_buf.write_char(']')
        }
        self.scanner.advance(1)
      }
      Some('\\') => {
        self.scanner.advance(1)
        match self.scanner.consume() {
          Some(c) => text_buf.write_char(c)
          None => break
        }
      }
      Some(c) => {
        text_buf.write_char(c)
        self.scanner.advance(1)
      }
      None => break
    }
  }

  let link_text = text_buf.to_string()

  // Check for inline link (url)
  if char_is(self.scanner.peek(), '(') {
    self.scanner.advance(1)

    // Parse URL
    let url_buf = StringBuilder::new()
    let mut paren_depth = 1

    // Skip leading whitespace
    let _ = self.scanner.skip_spaces()

    // Check for angle-bracketed URL
    if char_is(self.scanner.peek(), '<') {
      self.scanner.advance(1)
      while not(self.scanner.is_eof()) {
        match self.scanner.peek() {
          Some('>') => {
            self.scanner.advance(1)
            break
          }
          Some(c) => {
            url_buf.write_char(c)
            self.scanner.advance(1)
          }
          None => break
        }
      }
    } else {
      while not(self.scanner.is_eof()) {
        match self.scanner.peek() {
          Some('(') => {
            paren_depth += 1
            url_buf.write_char('(')
            self.scanner.advance(1)
          }
          Some(')') => {
            paren_depth -= 1
            if paren_depth == 0 {
              break
            }
            url_buf.write_char(')')
            self.scanner.advance(1)
          }
          Some(' ') | Some('\t') => break  // End of URL
          Some(c) => {
            url_buf.write_char(c)
            self.scanner.advance(1)
          }
          None => break
        }
      }
    }

    let url = url_buf.to_string()

    // Skip whitespace
    let _ = self.scanner.skip_spaces()

    // Parse optional title
    let title = match self.scanner.peek() {
      Some('"') | Some('\'') => {
        let quote = match self.scanner.consume() {
          Some(c) => c
          None => '"'
        }
        let title_buf = StringBuilder::new()
        while not(self.scanner.is_eof()) {
          match self.scanner.peek() {
            Some(c) if c == quote => {
              self.scanner.advance(1)
              break
            }
            Some('\\') => {
              self.scanner.advance(1)
              match self.scanner.consume() {
                Some(c) => title_buf.write_char(c)
                None => break
              }
            }
            Some(c) => {
              title_buf.write_char(c)
              self.scanner.advance(1)
            }
            None => break
          }
        }
        title_buf.to_string()
      }
      _ => ""
    }

    // Skip whitespace and closing paren
    let _ = self.scanner.skip_spaces()
    if char_is(self.scanner.peek(), ')') {
      self.scanner.advance(1)

      // Parse link text as inlines
      let children = parse_inlines(link_text)

      return Some(Inline::Link(
        children~,
        url~,
        title~,
        span=Span::new(start, self.scanner.pos),
      ))
    }
  }

  // Check for reference link [text][ref]
  if char_is(self.scanner.peek(), '[') {
    self.scanner.advance(1)
    let label_buf = StringBuilder::new()
    while not(self.scanner.is_eof()) {
      match self.scanner.peek() {
        Some(']') => {
          self.scanner.advance(1)
          break
        }
        Some(c) => {
          label_buf.write_char(c)
          self.scanner.advance(1)
        }
        None => break
      }
    }

    let label = label_buf.to_string()
    let children = parse_inlines(link_text)

    return Some(Inline::RefLink(
      children~,
      label~,
      span=Span::new(start, self.scanner.pos),
    ))
  }

  // Not a valid link
  self.scanner.restore(start)
  None
}

///| Try to parse image
fn InlineParser::try_parse_image(self : InlineParser, start : Int) -> Inline? {
  self.scanner.advance(1)  // Skip !

  if not(char_is(self.scanner.peek(), '[')) {
    self.scanner.restore(start)
    return None
  }
  self.scanner.advance(1)  // Skip [

  // Parse alt text
  let alt_buf = StringBuilder::new()
  while not(self.scanner.is_eof()) {
    match self.scanner.peek() {
      Some(']') => {
        self.scanner.advance(1)
        break
      }
      Some('\\') => {
        self.scanner.advance(1)
        match self.scanner.consume() {
          Some(c) => alt_buf.write_char(c)
          None => break
        }
      }
      Some(c) => {
        alt_buf.write_char(c)
        self.scanner.advance(1)
      }
      None => break
    }
  }

  let alt = alt_buf.to_string()

  // Check for inline image (url)
  if char_is(self.scanner.peek(), '(') {
    self.scanner.advance(1)

    // Parse URL (same as link)
    let url_buf = StringBuilder::new()
    let _ = self.scanner.skip_spaces()

    if char_is(self.scanner.peek(), '<') {
      self.scanner.advance(1)
      while not(self.scanner.is_eof()) {
        match self.scanner.peek() {
          Some('>') => {
            self.scanner.advance(1)
            break
          }
          Some(c) => {
            url_buf.write_char(c)
            self.scanner.advance(1)
          }
          None => break
        }
      }
    } else {
      while not(self.scanner.is_eof()) {
        match self.scanner.peek() {
          Some(')') | Some(' ') | Some('\t') => break
          Some(c) => {
            url_buf.write_char(c)
            self.scanner.advance(1)
          }
          None => break
        }
      }
    }

    let url = url_buf.to_string()
    let _ = self.scanner.skip_spaces()

    // Parse optional title
    let title = match self.scanner.peek() {
      Some('"') | Some('\'') => {
        let quote = match self.scanner.consume() {
          Some(c) => c
          None => '"'
        }
        let title_buf = StringBuilder::new()
        while not(self.scanner.is_eof()) {
          match self.scanner.peek() {
            Some(c) if c == quote => {
              self.scanner.advance(1)
              break
            }
            Some(c) => {
              title_buf.write_char(c)
              self.scanner.advance(1)
            }
            None => break
          }
        }
        title_buf.to_string()
      }
      _ => ""
    }

    let _ = self.scanner.skip_spaces()
    if char_is(self.scanner.peek(), ')') {
      self.scanner.advance(1)

      return Some(Inline::Image(
        alt~,
        url~,
        title~,
        span=Span::new(start, self.scanner.pos),
      ))
    }
  }

  // Check for reference image ![alt][ref]
  if char_is(self.scanner.peek(), '[') {
    self.scanner.advance(1)
    let label_buf = StringBuilder::new()
    while not(self.scanner.is_eof()) {
      match self.scanner.peek() {
        Some(']') => {
          self.scanner.advance(1)
          break
        }
        Some(c) => {
          label_buf.write_char(c)
          self.scanner.advance(1)
        }
        None => break
      }
    }

    return Some(Inline::RefImage(
      alt~,
      label=label_buf.to_string(),
      span=Span::new(start, self.scanner.pos),
    ))
  }

  self.scanner.restore(start)
  None
}

///| Try to parse autolink
fn InlineParser::try_parse_autolink(self : InlineParser, start : Int) -> Inline? {
  self.scanner.advance(1)  // Skip <

  let url_buf = StringBuilder::new()
  let mut is_email = false

  while not(self.scanner.is_eof()) {
    match self.scanner.peek() {
      Some('>') => {
        self.scanner.advance(1)
        let url = url_buf.to_string()

        // Check if it's an email
        if url.contains("@") && not(url.has_prefix("http")) {
          is_email = true
        }

        return Some(Inline::Autolink(
          url~,
          is_email~,
          span=Span::new(start, self.scanner.pos),
        ))
      }
      Some(' ') | Some('\t') | Some('\n') => {
        // Not a valid autolink
        self.scanner.restore(start)
        return None
      }
      Some(c) => {
        url_buf.write_char(c)
        self.scanner.advance(1)
      }
      None => break
    }
  }

  self.scanner.restore(start)
  None
}

///| Try to parse hard break (two or more spaces followed by newline)
fn InlineParser::try_parse_hard_break(self : InlineParser, start : Int) -> Inline? {
  let space_count = self.scanner.count_char(' ')
  if space_count < 2 {
    return None
  }

  self.scanner.advance(space_count)

  if char_is(self.scanner.peek(), '\n') {
    self.scanner.advance(1)
    return Some(Inline::HardBreak(
      style=HardBreakStyle::TwoSpaces,
      span=Span::new(start, self.scanner.pos),
    ))
  }

  // Not followed by newline, restore and return None
  self.scanner.restore(start)
  None
}
