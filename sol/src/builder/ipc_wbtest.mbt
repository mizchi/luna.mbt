///|
using @test {assert_eq}

///|
test "ParentMessage init parses through opaque IPC message" {
  let msg = ParentMessage::Init("{\"ok\":true}").to_json()
  assert_eq(parse_init_data(msg), Some("{\"ok\":true}"))
  assert_eq(parse_job_id(msg), None)
  assert_false(is_shutdown(msg))
}

///|
test "ParentMessage job parses through opaque IPC message" {
  let msg = ParentMessage::Job(42).to_json()
  assert_eq(parse_init_data(msg), None)
  assert_eq(parse_job_id(msg), Some(42))
  assert_false(is_shutdown(msg))
}

///|
test "ParentMessage shutdown parses through opaque IPC message" {
  let msg = ParentMessage::Shutdown.to_json()
  assert_eq(parse_init_data(msg), None)
  assert_eq(parse_job_id(msg), None)
  assert_true(is_shutdown(msg))
}

///|
test "WorkerMessage done parses through opaque IPC message" {
  let msg = JobResult::{
    job_id: 7,
    output_path: "/docs",
    success: true,
    error: None,
  }.to_json()
  guard WorkerMessage::from_json(msg) is Some(Done(result)) else {
    fail("expected done message")
  }
  assert_eq(result.job_id, 7)
  assert_eq(result.output_path, "/docs")
  assert_true(result.success)
  assert_eq(result.error, None)
}
