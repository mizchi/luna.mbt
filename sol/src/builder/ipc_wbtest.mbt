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

///|
test "WorkerMessage done preserves error field through opaque IPC message" {
  let msg = JobResult::{
    job_id: 8,
    output_path: "/docs/bad",
    success: false,
    error: Some("render failed"),
  }.to_json()
  guard WorkerMessage::from_json(msg) is Some(Done(result)) else {
    fail("expected done message")
  }
  assert_eq(result.job_id, 8)
  assert_eq(result.output_path, "/docs/bad")
  assert_false(result.success)
  assert_eq(result.error, Some("render failed"))
}

///|
test "WorkerMessage ready parses through opaque IPC message" {
  let raw = @core.new_object()
  raw["type"] = @core.any("ready")
  guard WorkerMessage::from_json(IpcMessage::from_raw(raw)) is Some(Ready) else {
    fail("expected ready message")
  }
}

///|
test "WorkerMessage error parses through opaque IPC message" {
  let raw = @core.new_object()
  raw["type"] = @core.any("error")
  raw["message"] = @core.any("worker failed")
  guard WorkerMessage::from_json(IpcMessage::from_raw(raw))
    is Some(Error(message)) else {
    fail("expected error message")
  }
  assert_eq(message, "worker failed")
}
