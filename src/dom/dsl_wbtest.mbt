// Whitebox tests for Element DSL - Attr variants
//

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
  // Test AttrString variant Show via to_attr_value
  let str_val : Attr = AttrString("hello")
  match str_val.to_attr_value() {
    Static(s) => assert_eq(s, "hello")
    _ => assert_true(false)
  }

  // Test AttrBool variant Show via to_attr_value
  let bool_val : Attr = AttrBool(true)
  match bool_val.to_attr_value() {
    Static(s) => assert_eq(s, "true")
    _ => assert_true(false)
  }

  // Test AttrInt variant Show via to_attr_value
  let int_val : Attr = AttrInt(100)
  match int_val.to_attr_value() {
    Static(s) => assert_eq(s, "100")
    _ => assert_true(false)
  }

  // Test AttrNumber variant Show via to_attr_value
  let double_val : Attr = AttrNumber(2.5)
  match double_val.to_attr_value() {
    Static(s) => assert_true(s.contains("2.5"))
    _ => assert_true(false)
  }
}
