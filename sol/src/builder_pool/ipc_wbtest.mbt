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
test "WorkerInitData serializes to parseable typed Json" {
  let data = WorkerInitData::{
    config_json: "{\"title\":\"Docs\"}",
    pages_json: "[\"/guide\"]",
    sidebar_json: "[]",
    cwd: "/tmp/site",
  }
  let json : Json = @json.parse(data.to_json_string()) catch { _ => panic() }
  guard WorkerInitData::from_json(json) is Some(parsed) else {
    fail("expected worker init data")
  }
  assert_eq(parsed.config_json, "{\"title\":\"Docs\"}")
  assert_eq(parsed.pages_json, "[\"/guide\"]")
  assert_eq(parsed.sidebar_json, "[]")
  assert_eq(parsed.cwd, "/tmp/site")
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

///|
test "PageJobResult preserves error through builder IPC message" {
  let msg = PageJobResult::{
    page_index: 4,
    url_path: "/guide/bad",
    success: false,
    error: Some("render failed"),
  }.to_json()
  guard @builder.WorkerMessage::from_json(msg) is Some(Done(result)) else {
    fail("expected done message")
  }
  assert_eq(result.job_id, 4)
  assert_eq(result.output_path, "/guide/bad")
  assert_false(result.success)
  assert_eq(result.error, Some("render failed"))
}
