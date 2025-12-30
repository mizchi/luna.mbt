// CSS Utility Registry
//
// Tracks CSS declarations and generates minimal class names.
// Uses DJB2 hash for deterministic class names that match extract.ts output.

///|
/// Style registry: declaration → short class name
priv struct StyleRegistry {
  // "display:flex" → "_a1b2c"
  decl_to_class : Map[String, String]
  // All declarations for debugging
  declarations : Array[String]
}

///|
/// Global style registry (singleton)
let registry : StyleRegistry = { decl_to_class: Map::new(), declarations: [] }

///|
/// DJB2 hash function - must match extract.ts implementation
fn djb2_hash(s : String) -> UInt {
  let mut hash : UInt = 5381
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].to_uint()
    // hash * 33 + c
    hash = (hash << 5) + hash + c
  }
  hash
}

///|
/// Base36 characters
let base36_chars : String = "0123456789abcdefghijklmnopqrstuvwxyz"

///|
/// Convert hash to base36 string (0-9a-z)
fn to_base36(n : UInt) -> String {
  let mut num = n & 0xFFFFFF // Take lower 24 bits
  if num == 0 {
    return "0"
  }
  let buf = StringBuilder::new()
  while num > 0 {
    let idx = (num % 36).reinterpret_as_int()
    buf.write_string(base36_chars.substring(start=idx, end=idx + 1))
    num = num / 36
  }
  // Reverse the string
  let s = buf.to_string()
  let result = StringBuilder::new()
  for i = s.length() - 1; i >= 0; i = i - 1 {
    result.write_string(s.substring(start=i, end=i + 1))
  }
  result.to_string()
}

///|
/// Generate class name from declaration hash
fn hash_class_name(decl : String) -> String {
  let hash = djb2_hash(decl)
  let base36 = to_base36(hash)
  "_" + base36
}

///|
/// Register a CSS declaration and return its class name
fn register_decl(decl : String) -> String {
  match registry.decl_to_class.get(decl) {
    Some(cls) => cls
    None => {
      let cls = hash_class_name(decl)
      registry.decl_to_class.set(decl, cls)
      registry.declarations.push(decl)
      cls
    }
  }
}

///|
/// Reset registry (useful for testing)
pub fn reset_registry() -> Unit {
  registry.decl_to_class.clear()
  registry.declarations.clear()
}

///|
/// Get number of registered declarations
pub fn registry_size() -> Int {
  registry.declarations.length()
}
