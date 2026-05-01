// Tests for json_utils.mbt pure functions

// ============================================================================
// extract_string Tests
// ============================================================================

///|
test "extract_string: returns string value when key exists" {
  let obj : Map[String, Json] = { "name": "alice" }
  assert_eq!(extract_string(obj, "name", "default"), "alice")
}

///|
test "extract_string: returns default when key missing" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_string(obj, "name", "fallback"), "fallback")
}

///|
test "extract_string: returns default when value is not a string" {
  let obj : Map[String, Json] = { "count": Json::number(42.0) }
  assert_eq!(extract_string(obj, "count", "default"), "default")
}

///|
test "extract_string: returns default when value is boolean" {
  let obj : Map[String, Json] = { "flag": Json::boolean(true) }
  assert_eq!(extract_string(obj, "flag", "default"), "default")
}

///|
test "extract_string: returns default when value is null" {
  let obj : Map[String, Json] = { "key": Json::null() }
  assert_eq!(extract_string(obj, "key", "default"), "default")
}

///|
test "extract_string: returns empty string when stored value is empty" {
  let obj : Map[String, Json] = { "key": "" }
  assert_eq!(extract_string(obj, "key", "default"), "")
}

// ============================================================================
// extract_string_opt Tests
// ============================================================================

///|
test "extract_string_opt: returns Some when key exists with string" {
  let obj : Map[String, Json] = { "name": "bob" }
  assert_eq!(extract_string_opt(obj, "name"), Some("bob"))
}

///|
test "extract_string_opt: returns None when key missing" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_string_opt(obj, "name"), None)
}

///|
test "extract_string_opt: returns None when value is not a string" {
  let obj : Map[String, Json] = { "val": Json::boolean(true) }
  assert_eq!(extract_string_opt(obj, "val"), None)
}

///|
test "extract_string_opt: returns None for null value" {
  let obj : Map[String, Json] = { "key": Json::null() }
  assert_eq!(extract_string_opt(obj, "key"), None)
}

// ============================================================================
// extract_bool Tests
// ============================================================================

///|
test "extract_bool: returns true when value is True" {
  let obj : Map[String, Json] = { "enabled": Json::boolean(true) }
  assert_eq!(extract_bool(obj, "enabled", false), true)
}

///|
test "extract_bool: returns false when value is False" {
  let obj : Map[String, Json] = { "enabled": Json::boolean(false) }
  assert_eq!(extract_bool(obj, "enabled", true), false)
}

///|
test "extract_bool: returns default when key missing" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_bool(obj, "enabled", true), true)
}

///|
test "extract_bool: returns default when value is not a bool" {
  let obj : Map[String, Json] = { "enabled": "yes" }
  assert_eq!(extract_bool(obj, "enabled", false), false)
}

///|
test "extract_bool: returns default false when key missing and default is false" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_bool(obj, "flag", false), false)
}

// ============================================================================
// extract_int Tests
// ============================================================================

///|
test "extract_int: returns int value when key exists" {
  let obj : Map[String, Json] = { "count": Json::number(42.0) }
  assert_eq!(extract_int(obj, "count", 0), 42)
}

///|
test "extract_int: returns default when key missing" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_int(obj, "count", 99), 99)
}

///|
test "extract_int: returns default when value is not a number" {
  let obj : Map[String, Json] = { "count": "twelve" }
  assert_eq!(extract_int(obj, "count", 0), 0)
}

///|
test "extract_int: returns default when value is boolean" {
  let obj : Map[String, Json] = { "count": Json::boolean(true) }
  assert_eq!(extract_int(obj, "count", 5), 5)
}

///|
test "extract_int: returns zero for zero value" {
  let obj : Map[String, Json] = { "count": Json::number(0.0) }
  assert_eq!(extract_int(obj, "count", 99), 0)
}

// ============================================================================
// extract_int_opt Tests
// ============================================================================

///|
test "extract_int_opt: returns Some when key exists with number" {
  let obj : Map[String, Json] = { "port": Json::number(8080.0) }
  assert_eq!(extract_int_opt(obj, "port"), Some(8080))
}

///|
test "extract_int_opt: returns None when key missing" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_int_opt(obj, "port"), None)
}

///|
test "extract_int_opt: returns None when value is not a number" {
  let obj : Map[String, Json] = { "port": "8080" }
  assert_eq!(extract_int_opt(obj, "port"), None)
}

///|
test "extract_int_opt: returns None for null value" {
  let obj : Map[String, Json] = { "port": Json::null() }
  assert_eq!(extract_int_opt(obj, "port"), None)
}

// ============================================================================
// extract_array Tests
// ============================================================================

///|
test "extract_array: returns array when key exists" {
  let arr : Array[Json] = ["a", "b", "c"]
  let obj : Map[String, Json] = { "items": Json::array(arr) }
  let result = extract_array(obj, "items")
  assert_eq!(result.length(), 3)
}

///|
test "extract_array: returns empty array when key missing" {
  let obj : Map[String, Json] = {}
  let result = extract_array(obj, "items")
  assert_eq!(result.length(), 0)
}

///|
test "extract_array: returns empty array when value is not an array" {
  let obj : Map[String, Json] = { "items": "not-an-array" }
  let result = extract_array(obj, "items")
  assert_eq!(result.length(), 0)
}

///|
test "extract_array: returns empty array when value is a number" {
  let obj : Map[String, Json] = { "items": Json::number(1.0) }
  let result = extract_array(obj, "items")
  assert_eq!(result.length(), 0)
}

// ============================================================================
// extract_object Tests
// ============================================================================

///|
test "extract_object: returns Some map when key exists with object" {
  let inner : Map[String, Json] = { "x": "y" }
  let obj : Map[String, Json] = { "nested": Json::object(inner) }
  let result = extract_object(obj, "nested")
  assert_true!(result is Some(_))
  match result {
    Some(m) => assert_eq!(extract_string(m, "x", ""), "y")
    None => fail("expected Some")
  }
}

///|
test "extract_object: returns None when key missing" {
  let obj : Map[String, Json] = {}
  assert_eq!(extract_object(obj, "nested"), None)
}

///|
test "extract_object: returns None when value is not an object" {
  let obj : Map[String, Json] = { "nested": "string-not-object" }
  assert_eq!(extract_object(obj, "nested"), None)
}

///|
test "extract_object: returns None when value is an array" {
  let obj : Map[String, Json] = { "nested": Json::array([]) }
  assert_eq!(extract_object(obj, "nested"), None)
}

// ============================================================================
// parse_string_array Tests
// ============================================================================

///|
test "parse_string_array: extracts all strings from array" {
  let arr : Array[Json] = ["foo", "bar", "baz"]
  let result = parse_string_array(arr)
  assert_eq!(result, ["foo", "bar", "baz"])
}

///|
test "parse_string_array: skips non-string elements" {
  let arr : Array[Json] = [
    "hello",
    Json::number(42.0),
    "world",
    Json::boolean(true),
  ]
  let result = parse_string_array(arr)
  assert_eq!(result, ["hello", "world"])
}

///|
test "parse_string_array: returns empty array for empty input" {
  let arr : Array[Json] = []
  let result = parse_string_array(arr)
  assert_eq!(result.length(), 0)
}

///|
test "parse_string_array: returns empty array when all elements are non-strings" {
  let arr : Array[Json] = [Json::number(1.0), Json::boolean(true), Json::null()]
  let result = parse_string_array(arr)
  assert_eq!(result.length(), 0)
}

///|
test "parse_string_array: preserves order of string elements" {
  let arr : Array[Json] = ["c", "a", "b"]
  let result = parse_string_array(arr)
  assert_eq!(result[0], "c")
  assert_eq!(result[1], "a")
  assert_eq!(result[2], "b")
}

// ============================================================================
// extract_string_array Tests
// ============================================================================

///|
test "extract_string_array: returns string array when key exists" {
  let arr : Array[Json] = ["one", "two", "three"]
  let obj : Map[String, Json] = { "tags": Json::array(arr) }
  let result = extract_string_array(obj, "tags")
  assert_eq!(result, ["one", "two", "three"])
}

///|
test "extract_string_array: returns empty array when key missing" {
  let obj : Map[String, Json] = {}
  let result = extract_string_array(obj, "tags")
  assert_eq!(result.length(), 0)
}

///|
test "extract_string_array: returns empty array when value is not an array" {
  let obj : Map[String, Json] = { "tags": "not-an-array" }
  let result = extract_string_array(obj, "tags")
  assert_eq!(result.length(), 0)
}

///|
test "extract_string_array: skips non-string elements in array" {
  let arr : Array[Json] = ["valid", Json::number(1.0), "also-valid"]
  let obj : Map[String, Json] = { "tags": Json::array(arr) }
  let result = extract_string_array(obj, "tags")
  assert_eq!(result, ["valid", "also-valid"])
}

///|
test "extract_string_array: returns empty array for empty array value" {
  let obj : Map[String, Json] = { "tags": Json::array([]) }
  let result = extract_string_array(obj, "tags")
  assert_eq!(result.length(), 0)
}
