///|
using @test {assert_eq}

///|
test "json_obj creates object from pairs" {
  let obj = json_obj([("status", @js.any("ok"))])
  assert_eq(object_get_string(obj, "status"), Some("ok"))
}

///|
priv struct StatusPayload {
  status : String
} derive(ToJson)

///|
test "json_to_any converts ToJson payload objects" {
  let obj = json_to_any(StatusPayload::{ status: "ok" }.to_json())
  assert_eq(object_get_string(obj, "status"), Some("ok"))
}
