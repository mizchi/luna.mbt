// Runtime internal tests

///|
test "select_bootstrap_mode - adapter on non-node uses export-only path" {
  let mode = select_bootstrap_mode(is_adapter=true, is_node=false)
  assert_true(mode is RuntimeBootstrapMode::AdapterExportOnly)
}

///|
test "select_bootstrap_mode - adapter on node initializes fs" {
  let mode = select_bootstrap_mode(is_adapter=true, is_node=true)
  assert_true(mode is RuntimeBootstrapMode::InitFsAndMaybeServe)
}

///|
test "select_bootstrap_mode - standalone on node initializes fs" {
  let mode = select_bootstrap_mode(is_adapter=false, is_node=true)
  assert_true(mode is RuntimeBootstrapMode::InitFsAndMaybeServe)
}
