///| JSON Parser - Parse JSON string to StateValue
///|
///| Uses MoonBit's builtin @json package for parsing.

///|
/// Parse JSON string to StateValue
pub fn from_json(json : String) -> StateValue? {
  try {
    let json_value = @json.parse(json.view())
    json_value_to_state_value(json_value)
  } catch {
    _ => None
  }
}

///|
/// Parse JSON array string to Array[StateValue]
pub fn array_from_json(json : String) -> Array[StateValue]? {
  try {
    let json_value = @json.parse(json.view())
    match json_value {
      Array(arr) => {
        let result : Array[StateValue] = []
        for item in arr {
          match json_value_to_state_value(item) {
            Some(v) => result.push(v)
            None => return None
          }
        }
        Some(result)
      }
      _ => None
    }
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
        match json_value_to_state_value(item) {
          Some(v) => result.push(v)
          None => return None
        }
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
    Arr(arr) => {
      let result : Array[Json] = []
      for item in arr {
        result.push(state_value_to_json_value(item))
      }
      Json::array(result)
    }
  }
}
