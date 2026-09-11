///|
test "parse_routes_file: formatted route calls preserve typed paths" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs
  .memfs()
  .writeFileSync(
    "/routes.mbt",
    (
      #|@sol.route(
      #|  "/@[user_id]",
      #|  user_profile,
      #|  title="User Profile",
      #|  revalidate=Some(60),
      #|)
      #|@sol.route(
      #|  "/@[user_id]/[page_id]",
      #|  user_page,
      #|)
      #|@sol.api_get(
      #|  "/api/items/[id]", get_item,
      #|)
      #|@sol.api_post(
      #|  "/api/items", create_item,
      #|)
      #|@sol.api_put(
      #|  "/api/items/[id]", update_item,
      #|)
      #|@sol.api_delete(
      #|  "/api/items/[id]", delete_item,
      #|)
      #|@sol.api_patch(
      #|  "/api/items/[id]", patch_item,
      #|)
    ),
  )
  let info = parse_routes_file_with_fs(fs, "/routes.mbt")
  assert_eq(info.route_paths, [
    "/@[user_id]", "/@[user_id]/[page_id]", "/api/items/[id]", "/api/items",
  ])
}

///|
test "parse_routes_file: dynamic paths do not capture later string arguments" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs
  .memfs()
  .writeFileSync(
    "/routes.mbt",
    (
      #|@sol.route(
      #|  dynamic_path, handler, title="Not a route",
      #|)
      #|@sol.route("/literal", handler)
    ),
  )
  assert_eq(parse_routes_file_with_fs(fs, "/routes.mbt").route_paths, [
    "/literal",
  ])
}
