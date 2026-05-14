///|
using @test {assert_eq}

///|
test "patch_mars_reschedule_shim_with_fs: debug profile server.js is patched" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cwd = "/app"
  let server_dir = "/app/_build/js/debug/build/__gen__/server"
  let server_js_path = server_dir + "/server.js"
  @env.FileSystem::mkdir_sync(fs, server_dir, true)
  @env.FileSystem::write_file_sync(
    fs, server_js_path, "before moonbitlang$async$internal$event_loop$$reschedule(); after",
  )

  patch_mars_reschedule_shim_with_fs(fs, cwd, "js", "debug")

  let content = @env.FileSystem::read_file_sync(fs, server_js_path)
  assert_false(
    content.contains("moonbitlang$async$internal$event_loop$$reschedule();"),
  )
  assert_true(content.contains("void 0;"))
}

///|
test "patch_mars_reschedule_shim_with_fs: release profile server.js is patched" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cwd = "/app"
  let server_dir = "/app/_build/js/release/build/__gen__/server"
  let server_js_path = server_dir + "/server.js"
  @env.FileSystem::mkdir_sync(fs, server_dir, true)
  @env.FileSystem::write_file_sync(
    fs, server_js_path, "moonbitlang$async$internal$event_loop$$reschedule();",
  )

  patch_mars_reschedule_shim_with_fs(fs, cwd, "js", "release")

  let content = @env.FileSystem::read_file_sync(fs, server_js_path)
  assert_eq(content, "void 0;")
}

///|
test "patch_cloudflare_global_seed_with_fs: generated server.js is patched" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cwd = "/app"
  let server_dir = "/app/_build/js/release/build/__gen__/server"
  let server_js_path = server_dir + "/server.js"
  @env.FileSystem::mkdir_sync(fs, server_dir, true)
  @env.FileSystem::write_file_sync(
    fs, server_js_path, "before const _M0FPB4seed = _M0FPB12random__seed(); after",
  )

  patch_cloudflare_global_seed_with_fs(fs, cwd, "js", "release")

  let content = @env.FileSystem::read_file_sync(fs, server_js_path)
  assert_false(content.contains("_M0FPB12random__seed();"))
  assert_true(content.contains("const _M0FPB4seed = 0;"))
}

///|
test "patch_cloudflare_global_seed_with_fs: user-managed server.js is patched" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let cwd = "/app"
  let server_dir = "/app/_build/js/release/build/server"
  let server_js_path = server_dir + "/server.js"
  @env.FileSystem::mkdir_sync(fs, server_dir, true)
  @env.FileSystem::write_file_sync(
    fs, server_js_path, "const _M0FPB4seed = _M0FPB12random__seed();",
  )

  patch_cloudflare_global_seed_with_fs(fs, cwd, "js", "release")

  let content = @env.FileSystem::read_file_sync(fs, server_js_path)
  assert_true(content.contains("const _M0FPB4seed = 0;"))
}
