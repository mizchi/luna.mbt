// File router internal tests

///|
test "normalize_dynamic_param_value - trims slashes for catch-all" {
  let value = normalize_dynamic_param_value("/docs/guide/", is_catch_all=true)
  assert_eq(value, "docs/guide")
}

///|
test "normalize_dynamic_param_value - keeps value for non catch-all" {
  let value = normalize_dynamic_param_value("hello-world", is_catch_all=false)
  assert_eq(value, "hello-world")
}

///|
test "build_dynamic_page_relative - catch-all empty uses parent path" {
  let path = build_dynamic_page_relative("docs", "", is_catch_all=true)
  assert_eq(path, "docs")
}

///|
test "build_dynamic_page_relative - catch-all nested keeps segments" {
  let path = build_dynamic_page_relative(
    "docs",
    "guide/intro",
    is_catch_all=true,
  )
  assert_eq(path, "docs/guide/intro")
}

///|
test "resolve_dynamic_param_value - catch-all allows missing param" {
  let params : Map[String, String] = {}
  let value = resolve_dynamic_param_value(params, "slug", is_catch_all=true)
  assert_eq(value, Some(""))
}

///|
test "resolve_dynamic_param_value - non catch-all skips missing param" {
  let params : Map[String, String] = {}
  let value = resolve_dynamic_param_value(params, "id", is_catch_all=false)
  assert_eq(value, None)
}

///|
test "build_source_with_dynamic_param - encodes catch-all slash" {
  let source = build_source_with_dynamic_params(
    "docs/_...slug_.md",
    "slug",
    "guide/intro",
    {},
  )
  assert_eq(source, "docs/_...slug_.md?slug=guide%2Fintro")
}

///|
test "build_source_with_dynamic_params - appends extra params as query" {
  let params : Map[String, String] = { "lang": "ja", "sort": "desc&asc" }
  let source = build_source_with_dynamic_params(
    "docs/_...slug_.md", "slug", "guide/intro", params,
  )
  assert_eq(
    source, "docs/_...slug_.md?slug=guide%2Fintro&lang=ja&sort=desc%26asc",
  )
}
