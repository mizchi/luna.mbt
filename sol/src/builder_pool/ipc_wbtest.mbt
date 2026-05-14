///|
using @test {assert_eq}

///|
test "WorkerInitData parses from typed Json" {
  let json : Json = {
    "configJson": "{}",
    "pagesJson": "[]",
    "sidebarJson": "[]",
    "cwd": "/tmp/site",
  }
  guard WorkerInitData::from_json(json) is Some(data) else {
    fail("expected worker init data")
  }
  assert_eq(data.config_json, "{}")
  assert_eq(data.pages_json, "[]")
  assert_eq(data.sidebar_json, "[]")
  assert_eq(data.cwd, "/tmp/site")
}

///|
test "WorkerInitData rejects non-object Json" {
  match WorkerInitData::from_json(Json::array([])) {
    None => ()
    Some(_) => fail("expected parse failure")
  }
}

///|
test "PageJobResult serializes through builder IPC message" {
  let msg = PageJobResult::{
    page_index: 3,
    url_path: "/guide",
    success: true,
    error: None,
  }.to_json()
  guard @builder.WorkerMessage::from_json(msg) is Some(Done(result)) else {
    fail("expected done message")
  }
  assert_eq(result.job_id, 3)
  assert_eq(result.output_path, "/guide")
  assert_true(result.success)
}
