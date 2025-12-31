// Hash Utilities for Cache Keys
//
// Fast, simple hash functions with good distribution for cache keys.
// Shared between Astra and Sol.

// =============================================================================
// FNV-1a Hash
// =============================================================================

///|
/// FNV-1a 32-bit hash
/// Fast non-cryptographic hash suitable for cache keys
pub fn fnv1a(data : String) -> String {
  let fnv_offset_basis : UInt = 2166136261
  let fnv_prime : UInt = 16777619
  let mut hash = fnv_offset_basis
  for c in data {
    hash = hash ^ c.to_uint()
    hash = hash * fnv_prime
  }
  uint_to_hex(hash)
}

///|
/// FNV-1a 64-bit hash for longer keys
pub fn fnv1a_64(data : String) -> String {
  let fnv_offset_basis : UInt64 = 14695981039346656037UL
  let fnv_prime : UInt64 = 1099511628211UL
  let mut hash = fnv_offset_basis
  for c in data {
    hash = hash ^ c.to_int().to_uint64()
    hash = hash * fnv_prime
  }
  uint64_to_hex(hash)
}

///|
/// Convert UInt to hexadecimal string (8 chars)
fn uint_to_hex(n : UInt) -> String {
  let hex_chars = "0123456789abcdef"
  let chars = hex_chars.to_array()
  let buf = StringBuilder::new()
  for i = 7; i >= 0; i = i - 1 {
    let shift = i * 4
    let nibble = (n >> shift) & 0xF
    buf.write_char(chars[nibble.reinterpret_as_int()])
  }
  buf.to_string()
}

///|
/// Convert UInt64 to hexadecimal string (16 chars)
fn uint64_to_hex(n : UInt64) -> String {
  let hex_chars = "0123456789abcdef"
  let chars = hex_chars.to_array()
  let buf = StringBuilder::new()
  for i = 15; i >= 0; i = i - 1 {
    let shift = i * 4
    let nibble = (n >> shift) & 0xFUL
    buf.write_char(chars[nibble.to_int()])
  }
  buf.to_string()
}

// =============================================================================
// Cache Key Helpers
// =============================================================================

///|
/// Compute hash for multiple strings (joined with null separator)
pub fn hash_strings(parts : Array[String]) -> String {
  fnv1a(parts.join("\u0000"))
}

///|
/// Compute hash for content with additional context
pub fn hash_content(content : String, context : String) -> String {
  fnv1a(content + "\u0000" + context)
}
