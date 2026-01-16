// StateValue - JSON-compatible value types for serialization
//
// Pure MoonBit implementation with no external dependencies.
// Can be used across all targets (JS, WASM, Native).
//

///|
/// Supported state value types for serialization
pub enum StateValue {
  Null
  Bool(Bool)
  Int(Int)
  Number(Double)
  Str(String)
  Arr(Array[StateValue])
} derive(Show, Eq)

///|
/// Check if value is null
pub fn StateValue::is_null(self : StateValue) -> Bool {
  match self {
    Null => true
    _ => false
  }
}

///|
/// Get as Bool
pub fn StateValue::as_bool(self : StateValue) -> Bool? {
  match self {
    Bool(b) => Some(b)
    _ => None
  }
}

///|
/// Get as Int
pub fn StateValue::as_int(self : StateValue) -> Int? {
  match self {
    Int(n) => Some(n)
    _ => None
  }
}

///|
/// Get as Double
pub fn StateValue::as_number(self : StateValue) -> Double? {
  match self {
    Number(f) => Some(f)
    _ => None
  }
}

///|
/// Get as String
pub fn StateValue::as_string(self : StateValue) -> String? {
  match self {
    Str(s) => Some(s)
    _ => None
  }
}

///|
/// Get as Array
pub fn StateValue::as_array(self : StateValue) -> Array[StateValue]? {
  match self {
    Arr(arr) => Some(arr)
    _ => None
  }
}

///|
/// Create null value
pub fn sv_null() -> StateValue {
  Null
}

///|
/// Create bool value
pub fn sv_bool(b : Bool) -> StateValue {
  Bool(b)
}

///|
/// Create int value
pub fn sv_int(n : Int) -> StateValue {
  Int(n)
}

///|
/// Create number value
pub fn sv_number(f : Double) -> StateValue {
  Number(f)
}

///|
/// Create string value
pub fn sv_str(s : String) -> StateValue {
  Str(s)
}

///|
/// Create array value
pub fn sv_arr(values : Array[StateValue]) -> StateValue {
  Arr(values)
}
