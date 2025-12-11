///| JSON Serializer - Serialize StateValue to JSON string
///|
///| Pure MoonBit implementation with no external dependencies.

///|
/// Serialize a StateValue to JSON string
pub fn to_json(value : StateValue) -> String {
  let buf = StringBuilder::new()
  write_json(value, buf)
  buf.to_string()
}

///|
/// Serialize an array of StateValues to JSON string
pub fn array_to_json(values : Array[StateValue]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(",")
    }
    write_json(values[i], buf)
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
      for i = 0; i < arr.length(); i = i + 1 {
        if i > 0 {
          buf.write_string(",")
        }
        write_json(arr[i], buf)
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
  let hex_chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
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
