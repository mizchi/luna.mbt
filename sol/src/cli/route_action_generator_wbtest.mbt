// Whitebox tests for route_action_generator.mbt

///|
test "extract_param_names_from_path: colon style" {
  let params = extract_param_names_from_path("/blog/:slug")
  assert_eq(params.length(), 1)
  assert_eq(params[0], "slug")
}

///|
test "extract_param_names_from_path: colon regex strips suffix" {
  let params = extract_param_names_from_path("/api/:version{[0-9]+}")
  assert_eq(params.length(), 1)
  assert_eq(params[0], "version")
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
test "extract_param_names_from_path: at-prefixed bracket style" {
  let params = extract_param_names_from_path("/@[user_id]/[page_id]")
  assert_eq(params.length(), 2)
  assert_eq(params[0], "user_id")
  assert_eq(params[1], "page_id")
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
test "path_to_identifier: colon regex strips suffix" {
  assert_eq(path_to_identifier("/api/:version{[0-9]+}"), "api_version")
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
test "generate_route_constants: sanitizes param constant identifiers" {
  let result = generate_route_constants(["/users/[user-id]"])
  assert_true(result.contains("pub let param_user_id : String = \"user-id\""))
}

///|
test "generate_route_param_accessors: empty" {
  assert_eq(generate_route_param_accessors([]), "")
  assert_eq(generate_route_param_accessors(["/about"]), "")
}

///|
test "generate_route_param_accessors: required params struct" {
  let result = generate_route_param_accessors(["/users/:id/posts/:postId"])
  assert_true(result.contains("pub(all) struct RouteUsersIdPostsPostIdParams"))
  assert_true(result.contains("id : String"))
  assert_true(result.contains("postId : String"))
  assert_true(
    result.contains(
      "pub fn params_users_id_posts_postId(props : @router.PageProps) -> Result[RouteUsersIdPostsPostIdParams, @router.ApiResponse]",
    ),
  )
  assert_true(result.contains("@router.require(props, \"id\")"))
  assert_true(result.contains("@router.require(props, \"postId\")"))
}

///|
test "generate_route_param_accessors: optional catch-all is optional" {
  let result = generate_route_param_accessors(["/blog/[[...path]]"])
  assert_true(result.contains("pub(all) struct RouteBlogPathParams"))
  assert_true(result.contains("path : String?"))
  assert_true(result.contains("let path = props.params.get_param(\"path\")"))
}

///|
test "generate_route_param_accessors: sanitizes field names" {
  let result = generate_route_param_accessors(["/users/[user-id]"])
  assert_true(result.contains("user_id : String"))
  assert_true(result.contains("@router.require(props, \"user-id\")"))
}

///|
test "generate_route_param_accessors: colon regex uses normalized param name" {
  let result = generate_route_param_accessors(["/api/:version{[0-9]+}"])
  assert_true(result.contains("pub(all) struct RouteApiVersionParams"))
  assert_true(result.contains("version : String"))
  assert_true(result.contains("@router.require(props, \"version\")"))
}

///|
test "generate_route_param_accessors: at-prefixed bracket params" {
  let result = generate_route_param_accessors(["/@[user_id]/[page_id]"])
  assert_true(result.contains("pub(all) struct RouteUserIdPageIdParams"))
  assert_true(result.contains("user_id : String"))
  assert_true(result.contains("page_id : String"))
  assert_true(result.contains("@router.require(props, \"user_id\")"))
  assert_true(result.contains("@router.require(props, \"page_id\")"))
}

///|
test "generate_route_query_accessors: required and optional query params" {
  let result = generate_route_query_accessors([
    {
      path: "/search",
      query: [{ name: "q", optional: false }, { name: "page", optional: true }],
    },
  ])
  assert_true(result.contains("pub(all) struct RouteSearchQuery"))
  assert_true(result.contains("q : String"))
  assert_true(result.contains("page : String?"))
  assert_true(
    result.contains(
      "pub fn query_search(props : @router.PageProps) -> Result[RouteSearchQuery, @router.ApiResponse]",
    ),
  )
  assert_true(result.contains("props.params.require_query(\"q\")"))
  assert_true(result.contains("props.params.get_query(\"page\")"))
}

///|
test "route_paths_have_params" {
  assert_false(route_paths_have_params(["/", "/about"]))
  assert_true(route_paths_have_params(["/", "/blog/:slug"]))
}

///|
test "generate_action_key_factories: empty" {
  assert_eq(generate_action_key_factories([]), "")
}

///|
test "generate_action_key_factories: generates factory" {
  let result = generate_action_key_factories(["create-user"])
  assert_true(result.contains("pub(all) struct ActionCreateUser {}"))
  assert_true(
    result.contains("pub impl @action.ActionKey for ActionCreateUser with id"),
  )
  assert_true(result.contains("pub fn action_create_user()"))
  assert_true(result.contains("-> ActionCreateUser"))
  assert_true(result.contains("ActionCreateUser::{}"))
  assert_false(result.contains("Action" + "Ref"))
}

// =============================================================================
// Link Builder Tests
// =============================================================================

///|
test "generate_link_builders: empty" {
  assert_eq(generate_link_builders([]), "")
}

///|
test "generate_link_builders: static route" {
  let result = generate_link_builders(["/about"])
  assert_true(result.contains("pub fn link_about() -> String"))
  assert_true(result.contains("\"/about\""))
}

///|
test "generate_link_builders: root route" {
  let result = generate_link_builders(["/"])
  assert_true(result.contains("pub fn link_root() -> String"))
  assert_true(result.contains("\"/\""))
}

///|
test "generate_link_builders: single param" {
  let result = generate_link_builders(["/blog/:slug"])
  assert_true(
    result.contains("pub fn link_blog_slug(slug~ : String) -> String"),
  )
  assert_true(result.contains("\"/blog/\""))
  assert_true(result.contains("slug"))
  assert_true(
    result.contains(
      "pub fn link_blog_slug_params(params : RouteBlogSlugParams) -> String",
    ),
  )
  assert_true(result.contains("link_blog_slug(slug=params.slug)"))
}

///|
test "generate_link_builders: multiple params" {
  let result = generate_link_builders(["/users/:id/posts/:postId"])
  assert_true(
    result.contains(
      "pub fn link_users_id_posts_postId(id~ : String, postId~ : String) -> String",
    ),
  )
  assert_true(
    result.contains(
      "pub fn link_users_id_posts_postId_params(params : RouteUsersIdPostsPostIdParams) -> String",
    ),
  )
  assert_true(
    result.contains(
      "link_users_id_posts_postId(id=params.id, postId=params.postId)",
    ),
  )
}

///|
test "generate_link_builders: catch-all param" {
  let result = generate_link_builders(["/docs/[...slug]"])
  assert_true(
    result.contains("pub fn link_docs_slug(slug~ : String) -> String"),
  )
}

///|
test "generate_link_builders: sanitizes param labels" {
  let result = generate_link_builders(["/users/[user-id]"])
  assert_true(
    result.contains("pub fn link_users_user_id(user_id~ : String) -> String"),
  )
  assert_true(result.contains("\"/users/\" + user_id"))
  assert_true(result.contains("link_users_user_id(user_id=params.user_id)"))
}

///|
test "generate_link_builders: at-prefixed bracket params" {
  let result = generate_link_builders(["/@[user_id]/[page_id]"])
  assert_true(
    result.contains(
      "pub fn link_user_id_page_id(user_id~ : String, page_id~ : String) -> String",
    ),
  )
  assert_true(result.contains("\"/@\" + user_id + \"/\" + page_id"))
  assert_true(
    result.contains(
      "link_user_id_page_id(user_id=params.user_id, page_id=params.page_id)",
    ),
  )
}

///|
test "generate_link_builders: optional catch-all params struct omits segment" {
  let result = generate_link_builders(["/blog/[[...path]]"])
  assert_true(
    result.contains(
      "pub fn link_blog_path_params(params : RouteBlogPathParams) -> String",
    ),
  )
  assert_true(result.contains("Some(path) => link_blog_path(path~)"))
  assert_true(result.contains("None => \"/blog\""))
}

///|
test "generate_link_builders: optional catch-all params struct preserves required prefix params" {
  let result = generate_link_builders(["/docs/:lang/[[...path]]"])
  assert_true(
    result.contains(
      "pub fn link_docs_lang_path_params(params : RouteDocsLangPathParams) -> String",
    ),
  )
  assert_true(
    result.contains(
      "Some(path) => link_docs_lang_path(lang=params.lang, path~)",
    ),
  )
  assert_true(result.contains("None => \"/docs/\" + params.lang"))
}

///|
test "split_path_segments: root" {
  let segs = split_path_segments("/")
  assert_eq(segs.length(), 1)
  assert_eq(segs[0], "/")
}

///|
test "split_path_segments: static path" {
  let segs = split_path_segments("/about")
  assert_eq(segs.length(), 1)
  assert_eq(segs[0], "/about")
}

///|
test "split_path_segments: single param" {
  let segs = split_path_segments("/blog/:slug")
  assert_eq(segs.length(), 2)
  assert_eq(segs[0], "/blog/")
  assert_eq(segs[1], ":slug")
}

///|
test "split_path_segments: multiple params" {
  let segs = split_path_segments("/users/:id/posts/:postId")
  assert_eq(segs.length(), 4)
  assert_eq(segs[0], "/users/")
  assert_eq(segs[1], ":id")
  assert_eq(segs[2], "/posts/")
  assert_eq(segs[3], ":postId")
}

///|
test "split_path_segments: at-prefixed bracket param" {
  let segs = split_path_segments("/@[user_id]/[page_id]")
  assert_eq(segs.length(), 4)
  assert_eq(segs[0], "/@")
  assert_eq(segs[1], "[user_id]")
  assert_eq(segs[2], "/")
  assert_eq(segs[3], "[page_id]")
}

///|
test "classify_segment: static" {
  match classify_segment("blog") {
    StaticSegment(s) => assert_eq(s, "blog")
    _ => panic()
  }
}

///|
test "classify_segment: colon param" {
  match classify_segment(":slug") {
    DynamicSegment(name) => assert_eq(name, "slug")
    _ => panic()
  }
}

///|
test "classify_segment: bracket param" {
  match classify_segment("[id]") {
    DynamicSegment(name) => assert_eq(name, "id")
    _ => panic()
  }
}

///|
test "classify_segment: catch-all" {
  match classify_segment("[...slug]") {
    DynamicSegment(name) => assert_eq(name, "slug")
    _ => panic()
  }
}

///|
test "classify_segment: optional catch-all" {
  match classify_segment("[[...path]]") {
    DynamicSegment(name) => assert_eq(name, "path")
    _ => panic()
  }
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
