///| Whitebox tests for Element DSL - Attr variants

///|
test "Attr AttrString variant to_attr_value" {
  let val : Attr = AttrString("test-value")
  let attr_val = val.to_attr_value()
  assert_true(attr_val is Static("test-value"))
}

///|
test "Attr AttrBool variant to_attr_value true" {
  let val : Attr = AttrBool(true)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "true")
    _ => assert_true(false)
  }
}

///|
test "Attr AttrBool variant to_attr_value false" {
  let val : Attr = AttrBool(false)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "false")
    _ => assert_true(false)
  }
}

///|
test "Attr AttrInt variant to_attr_value" {
  let val : Attr = AttrInt(42)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "42")
    _ => assert_true(false)
  }
}

///|
test "Attr AttrInt variant to_attr_value negative" {
  let val : Attr = AttrInt(-123)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "-123")
    _ => assert_true(false)
  }
}

///|
test "Attr AttrNumber variant to_attr_value" {
  let val : Attr = AttrNumber(3.14)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) =>
      // Double string representation may vary
      assert_true(s.contains("3.14"))
    _ => assert_true(false)
  }
}

///|
test "Attr Show implementation" {
  // Test AttrString variant Show
  let str_val : Attr = AttrString("hello")
  assert_eq(str_val.to_string(), "hello")

  // Test AttrBool variant Show
  let bool_val : Attr = AttrBool(true)
  assert_eq(bool_val.to_string(), "true")

  // Test AttrInt variant Show
  let int_val : Attr = AttrInt(100)
  assert_eq(int_val.to_string(), "100")

  // Test AttrNumber variant Show
  let double_val : Attr = AttrNumber(2.5)
  assert_true(double_val.to_string().contains("2.5"))
}
