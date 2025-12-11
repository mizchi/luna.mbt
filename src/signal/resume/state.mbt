///| Resumable State - Qwik-like state serialization and restoration
///|
///| This module provides functionality to serialize Signal states to JSON
///| and restore them on the client side for hydration.

///|
/// State container that can be serialized
pub struct ResumableState {
  /// Serialized values as JSON-compatible array
  values : Array[StateValue]
  /// Map from signal ID to index in values array
  mut next_id : Int
}

///|
/// Supported state value types for serialization
pub enum StateValue {
  Null
  Bool(Bool)
  Int(Int)
  Float(Double)
  Str(String)
  Arr(Array[StateValue])
}

///|
/// Create a new empty resumable state
pub fn ResumableState::new() -> ResumableState {
  { values: [], next_id: 0 }
}

///|
/// Add a null value to state
pub fn ResumableState::register_null(self : ResumableState) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(Null)
  id
}

///|
/// Register a signal value and return its ID
pub fn ResumableState::register_int(self : ResumableState, value : Int) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(Int(value))
  id
}

///|
/// Register a string value and return its ID
pub fn ResumableState::register_string(
  self : ResumableState,
  value : String,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(Str(value))
  id
}

///|
/// Register a bool value and return its ID
pub fn ResumableState::register_bool(
  self : ResumableState,
  value : Bool,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(Bool(value))
  id
}

///|
/// Register a float value and return its ID
pub fn ResumableState::register_float(
  self : ResumableState,
  value : Double,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(Float(value))
  id
}

///|
/// Get value at index
pub fn ResumableState::get(self : ResumableState, id : Int) -> StateValue? {
  if id >= 0 && id < self.values.length() {
    Some(self.values[id])
  } else {
    None
  }
}

///|
/// Get int value at index
pub fn ResumableState::get_int(self : ResumableState, id : Int) -> Int? {
  match self.get(id) {
    Some(Int(v)) => Some(v)
    _ => None
  }
}

///|
/// Get string value at index
pub fn ResumableState::get_string(self : ResumableState, id : Int) -> String? {
  match self.get(id) {
    Some(Str(v)) => Some(v)
    _ => None
  }
}

///|
/// Get bool value at index
pub fn ResumableState::get_bool(self : ResumableState, id : Int) -> Bool? {
  match self.get(id) {
    Some(Bool(v)) => Some(v)
    _ => None
  }
}

///|
/// Get float value at index
pub fn ResumableState::get_float(self : ResumableState, id : Int) -> Double? {
  match self.get(id) {
    Some(Float(v)) => Some(v)
    _ => None
  }
}

///|
/// Serialize state to JSON string
pub fn ResumableState::to_json(self : ResumableState) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i = 0; i < self.values.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(",")
    }
    state_value_to_json(self.values[i], buf)
  }
  buf.write_string("]")
  buf.to_string()
}

///|
/// Serialize a StateValue to JSON
fn state_value_to_json(value : StateValue, buf : StringBuilder) -> Unit {
  match value {
    Null => buf.write_string("null")
    Bool(b) => buf.write_string(if b { "true" } else { "false" })
    Int(n) => buf.write_string(n.to_string())
    Float(f) => buf.write_string(f.to_string())
    Str(s) => {
      buf.write_string("\"")
      buf.write_string(escape_json_string(s))
      buf.write_string("\"")
    }
    Arr(arr) => {
      buf.write_string("[")
      for i = 0; i < arr.length(); i = i + 1 {
        if i > 0 {
          buf.write_string(",")
        }
        state_value_to_json(arr[i], buf)
      }
      buf.write_string("]")
    }
  }
}

///|
/// Escape special characters in JSON string
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for char in s {
    match char {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(char)
    }
  }
  buf.to_string()
}

///|
/// Parse JSON string to ResumableState
pub fn ResumableState::from_json(json : String) -> ResumableState? {
  let parser = JsonParser::new(json)
  match parser.parse_array() {
    Some(values) => Some({ values, next_id: values.length() })
    None => None
  }
}

///|
/// Simple JSON parser for state restoration
priv struct JsonParser {
  input : String
  mut pos : Int
}

///|
fn JsonParser::new(input : String) -> JsonParser {
  { input, pos: 0 }
}

///|
fn JsonParser::peek(self : JsonParser) -> Char? {
  if self.pos < self.input.length() {
    Some(self.input.iter().take(self.pos + 1).last().unwrap())
  } else {
    None
  }
}

///|
fn JsonParser::advance(self : JsonParser) -> Char? {
  if self.pos < self.input.length() {
    let c = self.input.iter().take(self.pos + 1).last().unwrap()
    self.pos = self.pos + 1
    Some(c)
  } else {
    None
  }
}

///|
fn JsonParser::skip_whitespace(self : JsonParser) -> Unit {
  while true {
    match self.peek() {
      Some(' ') | Some('\t') | Some('\n') | Some('\r') => {
        self.pos = self.pos + 1
      }
      _ => break
    }
  }
}

///|
fn JsonParser::parse_value(self : JsonParser) -> StateValue? {
  self.skip_whitespace()
  match self.peek() {
    Some('[') => {
      match self.parse_array() {
        Some(arr) => Some(Arr(arr))
        None => None
      }
    }
    Some('"') => self.parse_string()
    Some('t') | Some('f') => self.parse_bool()
    Some('n') => self.parse_null()
    Some(c) =>
      if c == '-' || (c >= '0' && c <= '9') {
        self.parse_number()
      } else {
        None
      }
    None => None
  }
}

///|
fn JsonParser::parse_array(self : JsonParser) -> Array[StateValue]? {
  self.skip_whitespace()
  match self.advance() {
    Some('[') => ()
    _ => return None
  }
  let arr : Array[StateValue] = []
  self.skip_whitespace()
  // Empty array
  match self.peek() {
    Some(']') => {
      let _ = self.advance()
      return Some(arr)
    }
    _ => ()
  }
  // Parse elements
  while true {
    match self.parse_value() {
      Some(v) => arr.push(v)
      None => return None
    }
    self.skip_whitespace()
    match self.peek() {
      Some(',') => {
        let _ = self.advance()
        self.skip_whitespace()
      }
      Some(']') => {
        let _ = self.advance()
        return Some(arr)
      }
      _ => return None
    }
  }
  Some(arr)
}

///|
fn JsonParser::parse_string(self : JsonParser) -> StateValue? {
  match self.advance() {
    Some('"') => ()
    _ => return None
  }
  let buf = StringBuilder::new()
  while true {
    match self.advance() {
      Some('"') => return Some(Str(buf.to_string()))
      Some('\\') =>
        match self.advance() {
          Some('"') => buf.write_char('"')
          Some('\\') => buf.write_char('\\')
          Some('n') => buf.write_char('\n')
          Some('r') => buf.write_char('\r')
          Some('t') => buf.write_char('\t')
          _ => return None
        }
      Some(c) => buf.write_char(c)
      None => return None
    }
  }
  None
}

///|
fn JsonParser::parse_bool(self : JsonParser) -> StateValue? {
  let start = self.pos
  // Try "true"
  if self.pos + 4 <= self.input.length() {
    let mut is_true = true
    let true_chars = ['t', 'r', 'u', 'e']
    for i = 0; i < 4; i = i + 1 {
      match self.peek() {
        Some(c) =>
          if c == true_chars[i] {
            let _ = self.advance()
          } else {
            is_true = false
            break
          }
        None => {
          is_true = false
          break
        }
      }
    }
    if is_true {
      return Some(Bool(true))
    }
  }
  // Reset and try "false"
  self.pos = start
  if self.pos + 5 <= self.input.length() {
    let mut is_false = true
    let false_chars = ['f', 'a', 'l', 's', 'e']
    for i = 0; i < 5; i = i + 1 {
      match self.peek() {
        Some(c) =>
          if c == false_chars[i] {
            let _ = self.advance()
          } else {
            is_false = false
            break
          }
        None => {
          is_false = false
          break
        }
      }
    }
    if is_false {
      return Some(Bool(false))
    }
  }
  None
}

///|
fn JsonParser::parse_null(self : JsonParser) -> StateValue? {
  let null_chars = ['n', 'u', 'l', 'l']
  for i = 0; i < 4; i = i + 1 {
    match self.peek() {
      Some(c) =>
        if c == null_chars[i] {
          let _ = self.advance()
        } else {
          return None
        }
      None => return None
    }
  }
  Some(Null)
}

///|
fn JsonParser::parse_number(self : JsonParser) -> StateValue? {
  let buf = StringBuilder::new()
  let mut has_dot = false
  // Handle negative sign
  match self.peek() {
    Some('-') => {
      buf.write_char('-')
      let _ = self.advance()
    }
    _ => ()
  }
  // Parse digits
  while true {
    match self.peek() {
      Some(c) =>
        if c >= '0' && c <= '9' {
          buf.write_char(c)
          let _ = self.advance()
        } else if c == '.' && not(has_dot) {
          has_dot = true
          buf.write_char(c)
          let _ = self.advance()
        } else {
          break
        }
      None => break
    }
  }
  let s = buf.to_string()
  if s == "" || s == "-" {
    return None
  }
  if has_dot {
    try {
      let f = @strconv.parse_double(s)
      Some(Float(f))
    } catch {
      _ => None
    }
  } else {
    try {
      let n = @strconv.parse_int(s)
      Some(Int(n))
    } catch {
      _ => None
    }
  }
}
