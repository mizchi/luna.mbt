///| Whitebox tests for Element DSL - AttrVal variants

///|
test "AttrVal String variant to_attr_value" {
  let val : AttrVal = String("test-value")
  let attr_val = val.to_attr_value()
  assert_true(attr_val is Static("test-value"))
}

///|
test "AttrVal Bool variant to_attr_value true" {
  let val : AttrVal = Bool(true)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "true")
    _ => assert_true(false)
  }
}

///|
test "AttrVal Bool variant to_attr_value false" {
  let val : AttrVal = Bool(false)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "false")
    _ => assert_true(false)
  }
}

///|
test "AttrVal Int variant to_attr_value" {
  let val : AttrVal = Int(42)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "42")
    _ => assert_true(false)
  }
}

///|
test "AttrVal Int variant to_attr_value negative" {
  let val : AttrVal = Int(-123)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) => assert_eq(s, "-123")
    _ => assert_true(false)
  }
}

///|
test "AttrVal Double variant to_attr_value" {
  let val : AttrVal = Double(3.14)
  let attr_val = val.to_attr_value()
  match attr_val {
    Static(s) =>
      // Double string representation may vary
      assert_true(s.contains("3.14"))
    _ => assert_true(false)
  }
}

///|
test "AttrVal Show implementation" {
  // Test String variant Show
  let str_val : AttrVal = String("hello")
  assert_eq(str_val.to_string(), "hello")

  // Test Bool variant Show
  let bool_val : AttrVal = Bool(true)
  assert_eq(bool_val.to_string(), "true")

  // Test Int variant Show
  let int_val : AttrVal = Int(100)
  assert_eq(int_val.to_string(), "100")

  // Test Double variant Show
  let double_val : AttrVal = Double(2.5)
  assert_true(double_val.to_string().contains("2.5"))
}
