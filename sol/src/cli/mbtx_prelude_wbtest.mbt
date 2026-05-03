// Whitebox tests for mbtx_prelude.mbt

///|
test "mbtx_prelude: contains expected API functions" {
  let prelude = mbtx_prelude()
  assert_true(prelude.contains("fn param("))
  assert_true(prelude.contains("fn query("))
  assert_true(prelude.contains("fn request_method("))
  assert_true(prelude.contains("fn request_path("))
  assert_true(prelude.contains("fn html("))
  assert_true(prelude.contains("fn json_response("))
  assert_true(prelude.contains("fn text("))
}

///|
test "inject_mbtx_prelude: prepends to user code" {
  let user = "fn main { html(200, \"hello\") }\n"
  let result = inject_mbtx_prelude(user)
  assert_true(result.contains("[sol:mbtx-prelude]"))
  assert_true(result.contains("fn main { html(200, \"hello\") }"))
  // Prelude comes before user code
  let prelude_end = result.find("[sol:mbtx-prelude-end]").unwrap()
  let main_pos = result.find("fn main").unwrap()
  assert_true(prelude_end < main_pos)
}
