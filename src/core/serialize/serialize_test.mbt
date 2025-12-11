///| Tests for serialize module

test "StateValue constructors and accessors" {
  // Null
  let null_val = null()
  assert_true(null_val.is_null())

  // Bool
  let bool_val = bool(true)
  assert_eq(bool_val.as_bool(), Some(true))

  // Int
  let int_val = int(42)
  assert_eq(int_val.as_int(), Some(42))

  // Number (Double)
  let num_val = number(3.14)
  assert_eq(num_val.as_number(), Some(3.14))

  // String
  let str_val = str("hello")
  assert_eq(str_val.as_string(), Some("hello"))

  // Array
  let arr_val = arr([int(1), int(2), int(3)])
  let arr_result = arr_val.as_array()
  assert_true(arr_result is Some(_))
}

test "to_json basic types" {
  assert_eq(to_json(null()), "null")
  assert_eq(to_json(bool(true)), "true")
  assert_eq(to_json(bool(false)), "false")
  assert_eq(to_json(int(42)), "42")
  assert_eq(to_json(int(-123)), "-123")
  assert_eq(to_json(str("hello")), "\"hello\"")
}

test "to_json arrays" {
  let arr_val = arr([int(1), int(2), int(3)])
  assert_eq(to_json(arr_val), "[1,2,3]")

  let empty_arr = arr([])
  assert_eq(to_json(empty_arr), "[]")

  let nested = arr([arr([int(1)]), arr([int(2)])])
  assert_eq(to_json(nested), "[[1],[2]]")
}

test "to_json escapes strings" {
  assert_eq(to_json(str("hello\nworld")), "\"hello\\nworld\"")
  assert_eq(to_json(str("quote: \"")), "\"quote: \\\"\"")
  assert_eq(to_json(str("backslash: \\")), "\"backslash: \\\\\"")
}

test "from_json basic types" {
  assert_eq(from_json("null"), Some(null()))
  assert_eq(from_json("true"), Some(bool(true)))
  assert_eq(from_json("false"), Some(bool(false)))
  assert_eq(from_json("42"), Some(int(42)))
  assert_eq(from_json("-123"), Some(int(-123)))
  assert_eq(from_json("\"hello\""), Some(str("hello")))
}

test "from_json arrays" {
  let result = from_json("[1,2,3]")
  assert_true(result is Some(_))
  match result {
    Some(v) =>
      match v.as_array() {
        Some(arr_inner) => {
          assert_eq(arr_inner.length(), 3)
          assert_eq(arr_inner[0], int(1))
          assert_eq(arr_inner[1], int(2))
          assert_eq(arr_inner[2], int(3))
        }
        None => fail("Expected array")
      }
    None => fail("Expected some value")
  }
}

test "from_json empty array" {
  let result = from_json("[]")
  match result {
    Some(v) =>
      match v.as_array() {
        Some(arr_inner) => assert_eq(arr_inner.length(), 0)
        None => fail("Expected empty array")
      }
    None => fail("Expected some value")
  }
}

test "array_from_json" {
  let result = array_from_json("[1, \"hello\", true]")
  assert_true(result is Some(_))
  match result {
    Some(arr_inner) => {
      assert_eq(arr_inner.length(), 3)
      assert_eq(arr_inner[0], int(1))
      assert_eq(arr_inner[1], str("hello"))
      assert_eq(arr_inner[2], bool(true))
    }
    None => fail("Expected array")
  }
}

test "from_json invalid input" {
  assert_eq(from_json("invalid"), None)
  assert_eq(from_json("{\"key\": 1}"), None) // Objects not supported
}

test "roundtrip" {
  let values : Array[StateValue] = [
    null(),
    bool(true),
    bool(false),
    int(42),
    int(-100),
    str("hello world"),
    arr([int(1), str("two"), bool(true)]),
  ]

  for value in values {
    let json_str = to_json(value)
    let parsed = from_json(json_str)
    assert_eq(parsed, Some(value))
  }
}
