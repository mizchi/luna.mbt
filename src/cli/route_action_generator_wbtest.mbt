// Whitebox tests for route_action_generator.mbt

///|
test "extract_param_names_from_path: colon style" {
  let params = extract_param_names_from_path("/blog/:slug")
  assert_eq(params.length(), 1)
  assert_eq(params[0], "slug")
}

///|
test "extract_param_names_from_path: multiple params" {
  let params = extract_param_names_from_path("/users/:id/posts/:postId")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "id")
  assert_eq(params[1], "postId")
}

///|
test "extract_param_names_from_path: bracket style" {
  let params = extract_param_names_from_path("/users/[id]")
  assert_eq(params.length(), 1)
  assert_eq(params[0], "id")
}

///|
test "extract_param_names_from_path: catch-all" {
  let params = extract_param_names_from_path("/docs/[...slug]")
  assert_eq(params.length(), 1)
  assert_eq(params[0], "slug")
}

///|
test "extract_param_names_from_path: optional catch-all" {
  let params = extract_param_names_from_path("/blog/[[...path]]")
  assert_eq(params.length(), 1)
  assert_eq(params[0], "path")
}

///|
test "extract_param_names_from_path: no params" {
  let params = extract_param_names_from_path("/about")
  assert_eq(params.length(), 0)
}

///|
test "path_to_identifier: root" {
  assert_eq(path_to_identifier("/"), "root")
}

///|
test "path_to_identifier: simple path" {
  assert_eq(path_to_identifier("/blog"), "blog")
}

///|
test "path_to_identifier: with colon param" {
  assert_eq(path_to_identifier("/blog/:slug"), "blog_slug")
}

///|
test "path_to_identifier: with bracket param" {
  assert_eq(path_to_identifier("/users/[id]"), "users_id")
}

///|
test "path_to_identifier: nested path" {
  assert_eq(path_to_identifier("/api/users/:id"), "api_users_id")
}

///|
test "path_to_identifier: hyphenated segments" {
  assert_eq(path_to_identifier("/my-page/sub-path"), "my_page_sub_path")
}

///|
test "action_id_to_fn_name: simple" {
  assert_eq(action_id_to_fn_name("submit"), "action_submit")
}

///|
test "action_id_to_fn_name: with hyphens" {
  assert_eq(action_id_to_fn_name("create-user"), "action_create_user")
}

///|
test "generate_route_constants: empty" {
  assert_eq(generate_route_constants([]), "")
}

///|
test "generate_route_constants: generates constants" {
  let result = generate_route_constants(["/", "/blog/:slug"])
  assert_true(result.contains("pub let route_root : String = \"/\""))
  assert_true(
    result.contains("pub let route_blog_slug : String = \"/blog/:slug\""),
  )
  assert_true(result.contains("pub let param_slug : String = \"slug\""))
}

///|
test "generate_action_ref_factories: empty" {
  assert_eq(generate_action_ref_factories([]), "")
}

///|
test "generate_action_ref_factories: generates factory" {
  let result = generate_action_ref_factories(["create-user"])
  assert_true(result.contains("pub fn action_create_user()"))
  assert_true(result.contains("@action.ActionRef"))
  assert_true(result.contains("id: \"create-user\""))
  assert_true(result.contains("base_path: \"/_action\""))
}

///|
test "locale_code_to_variant: simple" {
  assert_eq(locale_code_to_variant("en"), "En")
  assert_eq(locale_code_to_variant("ja"), "Ja")
}

///|
test "locale_code_to_variant: with hyphen" {
  assert_eq(locale_code_to_variant("zh-CN"), "ZhCN")
}
