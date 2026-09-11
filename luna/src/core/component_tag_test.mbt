///|
test "component tag names support plain Sol component filenames" {
  assert_eq(component_tag_name("/static/counter.js"), "luna-counter")
  assert_eq(component_tag_name("/static/contact_form.js"), "contact-form")
  assert_eq(component_tag_name("/static/wc_counter.js"), "wc-counter")
}

///|
test "component tag names ignore query strings and normalize invalid names" {
  assert_eq(component_tag_name("/static/Counter.js?v=1#module"), "luna-counter")
  assert_eq(component_tag_name("/static/123.js"), "luna-123")
  assert_eq(component_tag_name("/static/font-face.js"), "luna-font-face")
}
