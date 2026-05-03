///|
test "HmrMessage::to_json - update includes islands and timestamp" {
  let msg = HmrMessage::Update(islands=["*"], timestamp_ms=1234.0).to_json()
  assert_true(msg.contains("\"type\":\"update\""))
  assert_true(msg.contains("\"islands\":[\"*\"]"))
  assert_true(msg.contains("\"timestamp\":1234"))
}

///|
test "HmrMessage::to_json - full reload" {
  let msg = HmrMessage::FullReload.to_json()
  assert_eq(msg, "{\"type\":\"full-reload\"}")
}

///|
test "HmrMessage::to_json - error message" {
  let msg = HmrMessage::Error(message="bad").to_json()
  assert_true(msg.contains("\"type\":\"error\""))
  assert_true(msg.contains("\"error\":\"bad\""))
}
