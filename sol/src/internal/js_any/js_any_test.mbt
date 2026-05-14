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
} derive(ToJson, FromJson)

///|
test "json_to_any converts ToJson payload objects" {
  let obj = json_to_any(StatusPayload::{ status: "ok" }.to_json())
  assert_eq(object_get_string(obj, "status"), Some("ok"))
}

///|
test "any_to_json converts JavaScript data back to Json" {
  let obj = json_to_any(StatusPayload::{ status: "ok" }.to_json())
  guard any_to_json(obj) is Some(json) else { fail("expected JSON") }
  let payload : StatusPayload = @json.from_json(json) catch {
    _ => fail("expected StatusPayload")
  }
  assert_eq(payload.status, "ok")
}
