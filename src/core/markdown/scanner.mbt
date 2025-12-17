///| Scanner utilities for markdown parsing

///| Scanner state - uses Array[Char] for O(1) character access
pub(all) struct Scanner {
  source : String
  chars : Array[Char]  // Pre-converted for fast access
  mut pos : Int
  len : Int
}

///| Create a new scanner
pub fn Scanner::new(source : String) -> Scanner {
  let chars = source.to_array()
  { source, chars, pos: 0, len: chars.length() }
}

///| Check if at end of input
pub fn Scanner::is_eof(self : Scanner) -> Bool {
  self.pos >= self.len
}

///| Peek current character (O(1) with Array[Char])
pub fn Scanner::peek(self : Scanner) -> Char? {
  if self.pos >= self.len {
    None
  } else {
    Some(self.chars[self.pos])
  }
}

///| Peek character at offset from current position (O(1))
pub fn Scanner::peek_at(self : Scanner, offset : Int) -> Char? {
  let idx = self.pos + offset
  if idx >= self.len || idx < 0 {
    None
  } else {
    Some(self.chars[idx])
  }
}

///| Advance position by n characters
pub fn Scanner::advance(self : Scanner, n : Int) -> Unit {
  self.pos = self.pos + n
  if self.pos > self.len {
    self.pos = self.len
  }
}

///| Consume and return current character (O(1))
pub fn Scanner::consume(self : Scanner) -> Char? {
  if self.pos >= self.len {
    None
  } else {
    let c = self.chars[self.pos]
    self.pos += 1
    Some(c)
  }
}

///| Get remaining substring from current position
pub fn Scanner::remaining(self : Scanner) -> String {
  if self.pos >= self.len {
    ""
  } else {
    self.source.unsafe_substring(start=self.pos, end=self.len)
  }
}

///| Get substring from start to end position
pub fn Scanner::substring(self : Scanner, start : Int, end : Int) -> String {
  self.source.unsafe_substring(start~, end~)
}

///| Skip whitespace (space and tab only) - O(1) per char
pub fn Scanner::skip_spaces(self : Scanner) -> Int {
  let start = self.pos
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == ' ' || c == '\t' {
      self.pos += 1
    } else {
      break
    }
  }
  self.pos - start
}

///| Count leading spaces (without advancing) - O(1) per char
pub fn Scanner::count_leading_spaces(self : Scanner) -> Int {
  let mut count = 0
  let mut idx = self.pos
  while idx < self.len {
    let c = self.chars[idx]
    if c == ' ' {
      count += 1
      idx += 1
    } else if c == '\t' {
      // Tab counts as up to 4 spaces to next multiple of 4
      count = (count / 4 + 1) * 4
      idx += 1
    } else {
      break
    }
  }
  count
}

///| Read until end of line (not consuming newline) - O(1) per char
pub fn Scanner::read_line(self : Scanner) -> String {
  let start = self.pos
  while self.pos < self.len {
    if self.chars[self.pos] == '\n' {
      break
    }
    self.pos += 1
  }
  self.source.unsafe_substring(start~, end=self.pos)
}

///| Skip to next line (consuming newline if present) - O(1) per char
pub fn Scanner::skip_line(self : Scanner) -> Unit {
  while self.pos < self.len {
    let c = self.chars[self.pos]
    self.pos += 1
    if c == '\n' {
      break
    }
  }
}

///| Check if current line is blank (only whitespace) - O(1) per char
pub fn Scanner::is_blank_line(self : Scanner) -> Bool {
  let mut idx = self.pos
  while idx < self.len {
    let c = self.chars[idx]
    if c == '\n' {
      return true
    }
    if c != ' ' && c != '\t' {
      return false
    }
    idx += 1
  }
  true
}

///| Match a string at current position - optimized with Array[Char]
pub fn Scanner::matches(self : Scanner, s : String) -> Bool {
  let s_len = s.length()
  if self.pos + s_len > self.len {
    return false
  }
  // Note: s.get_char still O(n), but s is usually short (e.g. "---", "```")
  for i = 0; i < s_len; i = i + 1 {
    match s.get_char(i) {
      Some(b) if self.chars[self.pos + i] == b => continue
      _ => return false
    }
  }
  true
}

///| Match and consume a string
pub fn Scanner::consume_str(self : Scanner, s : String) -> Bool {
  if self.matches(s) {
    self.pos += s.length()
    true
  } else {
    false
  }
}

///| Count consecutive occurrences of a character from current position - O(1) per char
pub fn Scanner::count_char(self : Scanner, c : Char) -> Int {
  let mut count = 0
  let mut idx = self.pos
  while idx < self.len {
    if self.chars[idx] == c {
      count += 1
      idx += 1
    } else {
      break
    }
  }
  count
}

///| Save current position
pub fn Scanner::save(self : Scanner) -> Int {
  self.pos
}

///| Restore to saved position
pub fn Scanner::restore(self : Scanner, pos : Int) -> Unit {
  self.pos = pos
}

// =============================================================================
// Character utilities
// =============================================================================

///| Check if character is ASCII whitespace
pub fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///| Check if character is a digit
pub fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///| Check if character is ASCII letter
pub fn is_letter(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///| Check if character is alphanumeric
pub fn is_alphanumeric(c : Char) -> Bool {
  is_digit(c) || is_letter(c)
}

///| Check if character is a punctuation mark
pub fn is_punctuation(c : Char) -> Bool {
  match c {
    '!' | '"' | '#' | '$' | '%' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' |
    '-' | '.' | '/' | ':' | ';' | '<' | '=' | '>' | '?' | '@' | '[' | '\\' |
    ']' | '^' | '_' | '`' | '{' | '|' | '}' | '~' => true
    _ => false
  }
}

///| Check if char option matches specific char
pub fn char_is(opt : Char?, c : Char) -> Bool {
  match opt {
    Some(ch) => ch == c
    None => false
  }
}

///| Check if char option is a digit
pub fn char_is_digit(opt : Char?) -> Bool {
  match opt {
    Some(c) => is_digit(c)
    None => false
  }
}
