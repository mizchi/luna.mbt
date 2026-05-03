///|
test "json_obj creates object from pairs" {
  let obj = json_obj([("status", @js.any("ok"))])
  assert_eq(object_get_string(obj, "status"), Some("ok"))
}
