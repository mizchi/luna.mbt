// JSON Serializer/Parser - Serialize/Parse StateValue to/from JSON string
//
// Pure MoonBit implementation using builtin @json package.

// =============================================================================
// JSON Serializer
// =============================================================================

///|
/// Serialize a StateValue to JSON string
pub fn state_value_to_json(value : StateValue) -> String {
  let buf = StringBuilder::new()
  write_json(value, buf)
  buf.to_string()
}

///|
/// Serialize an array of StateValues to JSON string
pub fn state_values_to_json(values : Array[StateValue]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i, value in values {
    if i > 0 {
      buf.write_string(",")
    }
    write_json(value, buf)
  }
  buf.write_string("]")
  buf.to_string()
}

///|
/// Write a StateValue to StringBuilder
fn write_json(value : StateValue, buf : StringBuilder) -> Unit {
  match value {
    Null => buf.write_string("null")
    Bool(b) => buf.write_string(if b { "true" } else { "false" })
    Int(n) => buf.write_string(n.to_string())
    Number(f) => write_double(f, buf)
    Str(s) => {
      buf.write_string("\"")
      write_escaped_string(s, buf)
      buf.write_string("\"")
    }
    Arr(arr) => {
      buf.write_string("[")
      for i, item in arr {
        if i > 0 {
          buf.write_string(",")
        }
        write_json(item, buf)
      }
      buf.write_string("]")
    }
  }
}

///|
/// Write double value, handling special cases
fn write_double(f : Double, buf : StringBuilder) -> Unit {
  let s = f.to_string()
  // Ensure it looks like a float (has decimal point)
  if not(s.contains(".")) && not(s.contains("e")) && not(s.contains("E")) {
    buf.write_string(s)
    buf.write_string(".0")
  } else {
    buf.write_string(s)
  }
}

///|
/// Escape special characters in JSON string
fn write_escaped_string(s : String, buf : StringBuilder) -> Unit {
  for char in s {
    match char {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ =>
        if char.to_int() < 32 {
          // Control characters
          buf.write_string("\\u")
          write_hex4(char.to_int(), buf)
        } else {
          buf.write_char(char)
        }
    }
  }
}

///|
/// Write 4-digit hex number
fn write_hex4(n : Int, buf : StringBuilder) -> Unit {
  let hex_chars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  buf.write_char(hex_chars[(n >> 12) & 0xF])
  buf.write_char(hex_chars[(n >> 8) & 0xF])
  buf.write_char(hex_chars[(n >> 4) & 0xF])
  buf.write_char(hex_chars[n & 0xF])
}

///|
/// Escape JSON string (convenience function)
pub fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  write_escaped_string(s, buf)
  buf.to_string()
}

// =============================================================================
// JSON Parser
// =============================================================================

///|
/// Parse JSON string to StateValue
pub fn state_value_from_json(json : String) -> StateValue? {
  try {
    let json_value = @json.parse(json.view())
    json_value_to_state_value(json_value)
  } catch {
    _ => None
  }
}

///|
/// Parse JSON array string to Array[StateValue]
pub fn state_values_from_json(json : String) -> Array[StateValue]? {
  try {
    let json_value = @json.parse(json.view())
    guard json_value is Array(arr) else { return None }
    let result : Array[StateValue] = []
    for item in arr {
      guard json_value_to_state_value(item) is Some(v) else { return None }
      result.push(v)
    }
    Some(result)
  } catch {
    _ => None
  }
}

///|
/// Convert Json to StateValue
fn json_value_to_state_value(value : Json) -> StateValue? {
  match value {
    Null => Some(Null)
    True => Some(Bool(true))
    False => Some(Bool(false))
    Number(n, ..) => {
      // Check if it's an integer
      let int_val = n.to_int()
      if int_val.to_double() == n {
        Some(Int(int_val))
      } else {
        Some(Number(n))
      }
    }
    String(s) => Some(Str(s))
    Array(arr) => {
      let result : Array[StateValue] = []
      for item in arr {
        guard json_value_to_state_value(item) is Some(v) else { return None }
        result.push(v)
      }
      Some(Arr(result))
    }
    Object(_) => None // StateValue doesn't support objects
  }
}

///|
/// Convert StateValue to Json
pub fn state_value_to_json_value(value : StateValue) -> Json {
  match value {
    Null => Json::null()
    Bool(b) => Json::boolean(b)
    Int(n) => Json::number(n.to_double())
    Number(f) => Json::number(f)
    Str(s) => Json::string(s)
    Arr(arr) => Json::array(arr.map(state_value_to_json_value))
  }
}
