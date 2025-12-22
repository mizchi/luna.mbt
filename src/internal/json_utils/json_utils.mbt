// JSON parsing utility functions
//
// Shared helpers for extracting values from JSON objects.
// Used by both Astra (config.mbt) and Sol (cli/generate.mbt).

///|
/// Extract a string value from a JSON object with a default fallback
pub fn extract_string(
  obj : Map[String, Json],
  key : String,
  default : String,
) -> String {
  match obj.get(key) {
    Some(String(s)) => s
    _ => default
  }
}

///|
/// Extract an optional string value from a JSON object
pub fn extract_string_opt(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
/// Extract a boolean value from a JSON object with a default fallback
pub fn extract_bool(
  obj : Map[String, Json],
  key : String,
  default : Bool,
) -> Bool {
  match obj.get(key) {
    Some(True) => true
    Some(False) => false
    _ => default
  }
}

///|
/// Extract an integer value from a JSON object with a default fallback
pub fn extract_int(obj : Map[String, Json], key : String, default : Int) -> Int {
  match obj.get(key) {
    Some(Number(n, ..)) => n.to_int()
    _ => default
  }
}

///|
/// Extract an optional integer value from a JSON object
pub fn extract_int_opt(obj : Map[String, Json], key : String) -> Int? {
  match obj.get(key) {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
}

///|
/// Extract a JSON array from an object
pub fn extract_array(obj : Map[String, Json], key : String) -> Array[Json] {
  match obj.get(key) {
    Some(Array(arr)) => arr
    _ => []
  }
}

///|
/// Extract a JSON object from an object
pub fn extract_object(
  obj : Map[String, Json],
  key : String,
) -> Map[String, Json]? {
  match obj.get(key) {
    Some(Object(inner)) => Some(inner)
    _ => None
  }
}

///|
/// Parse a JSON array into a string array (filtering non-strings)
pub fn parse_string_array(arr : Array[Json]) -> Array[String] {
  let result : Array[String] = []
  for item in arr {
    guard item is String(s) else { continue }
    result.push(s)
  }
  result
}

///|
/// Extract a string array from a JSON object
pub fn extract_string_array(
  obj : Map[String, Json],
  key : String,
) -> Array[String] {
  match obj.get(key) {
    Some(Array(arr)) => parse_string_array(arr)
    _ => []
  }
}
