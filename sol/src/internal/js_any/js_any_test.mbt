///|
using @test {assert_eq}

///|
test "json_obj creates object from pairs" {
  let obj = @js_any.json_obj([("status", @js.any("ok"))])
  assert_eq(@js_any.object_get_string(obj, "status"), Some("ok"))
}

///|
priv struct StatusPayload {
  status : String
} derive(ToJson, FromJson)

///|
extend StatusPayload with ToJson::{to_json}

///|
test "json_to_any converts ToJson payload objects" {
  let obj = @js_any.json_to_any(StatusPayload::{ status: "ok", }.to_json())
  assert_eq(@js_any.object_get_string(obj, "status"), Some("ok"))
}

///|
test "any_to_json converts JavaScript data back to Json" {
  let obj = @js_any.json_to_any(StatusPayload::{ status: "ok", }.to_json())
  guard @js_any.any_to_json(obj) is Some(json) else { fail("expected JSON") }
  let payload : StatusPayload = @json.from_json(json) catch {
    _ => fail("expected StatusPayload")
  }
  assert_eq(payload.status, "ok")
}
