// route_params internal tests

///|
test "has_query_string - true when path contains query" {
  assert_true(has_query_string("/search?q=test"))
  assert_true(has_query_string("/docs?page=2&lang=ja"))
}

///|
test "has_query_string - false when path has no query" {
  assert_false(has_query_string("/"))
  assert_false(has_query_string("/search"))
}
