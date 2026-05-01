// Tests for Cloudflare Pages _routes.json generation

///|
test "extract_dynamic_route_patterns - no dynamic routes" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new("index.md", "/", sort_key="index.md"),
    @ssg.PageMeta::new("about.md", "/about/", sort_key="about.md"),
  ]
  let patterns = extract_dynamic_route_patterns(pages)
  inspect(patterns.length(), content="0")
}

///|
test "extract_dynamic_route_patterns - single dynamic route" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new(
      "posts/_id_.md?id=hello",
      "/posts/hello/",
      sort_key="posts/hello",
    ),
    @ssg.PageMeta::new(
      "posts/_id_.md?id=world",
      "/posts/world/",
      sort_key="posts/world",
    ),
  ]
  let patterns = extract_dynamic_route_patterns(pages)
  inspect(patterns.length(), content="1")
  assert_true(patterns.contains("/posts/*"))
}

///|
test "extract_dynamic_route_patterns - multiple dynamic routes" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new(
      "posts/_id_.md?id=hello",
      "/posts/hello/",
      sort_key="posts/hello",
    ),
    @ssg.PageMeta::new(
      "docs/_slug_.md?slug=intro",
      "/docs/intro/",
      sort_key="docs/intro",
    ),
  ]
  let patterns = extract_dynamic_route_patterns(pages)
  inspect(patterns.length(), content="2")
  assert_true(patterns.contains("/posts/*"))
  assert_true(patterns.contains("/docs/*"))
}

///|
test "extract_dynamic_route_patterns - root level dynamic route" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new("_slug_.md?slug=page1", "/page1/", sort_key="page1"),
    @ssg.PageMeta::new("_slug_.md?slug=page2", "/page2/", sort_key="page2"),
  ]
  let patterns = extract_dynamic_route_patterns(pages)
  inspect(patterns.length(), content="1")
  assert_true(patterns.contains("/*"))
}

///|
test "extract_dynamic_route_patterns - mixed static and dynamic" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new("index.md", "/", sort_key="index.md"),
    @ssg.PageMeta::new("posts/index.md", "/posts/", sort_key="posts/index.md"),
    @ssg.PageMeta::new(
      "posts/_id_.md?id=first",
      "/posts/first/",
      sort_key="posts/first",
    ),
    @ssg.PageMeta::new(
      "posts/_id_.md?id=second",
      "/posts/second/",
      sort_key="posts/second",
    ),
    @ssg.PageMeta::new("about.md", "/about/", sort_key="about.md"),
  ]
  let patterns = extract_dynamic_route_patterns(pages)
  inspect(patterns.length(), content="1")
  assert_true(patterns.contains("/posts/*"))
}

///|
test "generate_routes_json - includes dynamic patterns" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new(
      "posts/_id_.md?id=hello",
      "/posts/hello/",
      sort_key="posts/hello",
    ),
  ]
  let json = generate_routes_json(pages)
  // Should include the dynamic pattern
  assert_true(json.contains("\"/posts/*\""))
  // Should also exclude the static path
  assert_true(json.contains("\"/posts/hello/*\""))
}

///|
test "generate_routes_json - no dynamic routes has empty include" {
  let pages : Array[@ssg.PageMeta] = [
    @ssg.PageMeta::new("index.md", "/", sort_key="index.md"),
  ]
  let json = generate_routes_json(pages)
  // Include should be empty
  assert_true(json.contains("\"include\": []"))
}
