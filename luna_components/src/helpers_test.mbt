///|
test "auto_id generates unique IDs" {
  // Reset counter for clean test
  @luna_components.reset_id_counter()
  let id1 = @luna_components.auto_id("tab")
  let id2 = @luna_components.auto_id("tab")
  let id3 = @luna_components.auto_id("panel")
  assert_true(id1 != id2)
  assert_true(id2 != id3)
  assert_eq(id1, "tab-1")
  assert_eq(id2, "tab-2")
  assert_eq(id3, "panel-3")
}

///|
test "bool_to_aria converts correctly" {
  assert_eq(@luna_components.bool_to_aria(true), "true")
  assert_eq(@luna_components.bool_to_aria(false), "false")
}

///|
test "KeyCode::from_string parses keys" {
  assert_eq(@luna_components.KeyCode::from_string("Enter"), Some(Enter))
  assert_eq(@luna_components.KeyCode::from_string(" "), Some(Space))
  assert_eq(@luna_components.KeyCode::from_string("ArrowUp"), Some(ArrowUp))
  assert_eq(@luna_components.KeyCode::from_string("ArrowDown"), Some(ArrowDown))
  assert_eq(@luna_components.KeyCode::from_string("ArrowLeft"), Some(ArrowLeft))
  assert_eq(
    @luna_components.KeyCode::from_string("ArrowRight"),
    Some(ArrowRight),
  )
  assert_eq(@luna_components.KeyCode::from_string("Home"), Some(Home))
  assert_eq(@luna_components.KeyCode::from_string("End"), Some(End))
  assert_eq(@luna_components.KeyCode::from_string("Tab"), Some(Tab))
  assert_eq(@luna_components.KeyCode::from_string("Escape"), Some(Escape))
  assert_eq(@luna_components.KeyCode::from_string("unknown"), None)
}

///|
test "key_matches works correctly" {
  assert_true(@luna_components.key_matches("Enter", Enter))
  assert_true(@luna_components.key_matches(" ", Space))
  assert_true(@luna_components.key_matches("ArrowUp", ArrowUp))
  assert_false(@luna_components.key_matches("Enter", Space))
  assert_false(@luna_components.key_matches("ArrowLeft", ArrowRight))
}

///|
test "is_toggle_key identifies Space and Enter" {
  assert_true(@luna_components.is_toggle_key(" "))
  assert_true(@luna_components.is_toggle_key("Enter"))
  assert_false(@luna_components.is_toggle_key("Escape"))
  assert_false(@luna_components.is_toggle_key("ArrowUp"))
}

///|
test "is_arrow_key identifies all arrow keys" {
  assert_true(@luna_components.is_arrow_key("ArrowUp"))
  assert_true(@luna_components.is_arrow_key("ArrowDown"))
  assert_true(@luna_components.is_arrow_key("ArrowLeft"))
  assert_true(@luna_components.is_arrow_key("ArrowRight"))
  assert_false(@luna_components.is_arrow_key("Enter"))
  assert_false(@luna_components.is_arrow_key("Home"))
}

///|
test "is_horizontal_arrow identifies left/right" {
  assert_true(@luna_components.is_horizontal_arrow("ArrowLeft"))
  assert_true(@luna_components.is_horizontal_arrow("ArrowRight"))
  assert_false(@luna_components.is_horizontal_arrow("ArrowUp"))
  assert_false(@luna_components.is_horizontal_arrow("ArrowDown"))
}

///|
test "is_vertical_arrow identifies up/down" {
  assert_true(@luna_components.is_vertical_arrow("ArrowUp"))
  assert_true(@luna_components.is_vertical_arrow("ArrowDown"))
  assert_false(@luna_components.is_vertical_arrow("ArrowLeft"))
  assert_false(@luna_components.is_vertical_arrow("ArrowRight"))
}

///|
test "arrow_direction returns correct values" {
  assert_eq(@luna_components.arrow_direction("ArrowUp"), -1)
  assert_eq(@luna_components.arrow_direction("ArrowLeft"), -1)
  assert_eq(@luna_components.arrow_direction("ArrowDown"), 1)
  assert_eq(@luna_components.arrow_direction("ArrowRight"), 1)
  assert_eq(@luna_components.arrow_direction("Enter"), 0)
}

///|
test "wrap_index wraps around" {
  assert_eq(@luna_components.wrap_index(0, -1, 3), 2) // 0 - 1 = -1 -> wraps to 2
  assert_eq(@luna_components.wrap_index(2, 1, 3), 0) // 2 + 1 = 3 -> wraps to 0
  assert_eq(@luna_components.wrap_index(1, 1, 3), 2) // normal increment
  assert_eq(@luna_components.wrap_index(1, -1, 3), 0) // normal decrement
}

///|
test "clamp_index clamps to bounds" {
  assert_eq(@luna_components.clamp_index(0, -1, 3), 0) // stays at 0
  assert_eq(@luna_components.clamp_index(2, 1, 3), 2) // stays at 2 (max)
  assert_eq(@luna_components.clamp_index(1, 1, 3), 2) // normal increment
  assert_eq(@luna_components.clamp_index(1, -1, 3), 0) // normal decrement
}
