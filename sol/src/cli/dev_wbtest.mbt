///|
test "is_cloudflare_runtime_project_with_fs detects cloudflare runtime" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/sol.config.json",
    (
      #|{
      #|  "runtime": "cloudflare"
      #|}
    ),
  )
  assert_true(is_cloudflare_runtime_project_with_fs(fs, "/project"))
}

///|
test "is_cloudflare_runtime_project_with_fs ignores node runtime" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/sol.config.json",
    (
      #|{
      #|  "runtime": "node"
      #|}
    ),
  )
  assert_false(is_cloudflare_runtime_project_with_fs(fs, "/project"))
}

///|
test "ensure_cloudflare_dev_files_with_fs writes fallback wrangler config" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  let config_path = ensure_cloudflare_dev_files_with_fs(fs, "/project")
  assert_eq(config_path, ".sol/dev/wrangler.toml")
  let worker = mem.readFileSync("/project/.sol/dev/worker.entry.mjs")
  let wrangler = mem.readFileSync("/project/.sol/dev/wrangler.toml")
  assert_true(worker.contains("import solApp from \"./server/main.js\""))
  assert_true(worker.contains("solApp.fetch(request, env, ctx)"))
  assert_true(wrangler.contains("main = \"worker.entry.mjs\""))
  assert_true(wrangler.contains("compatibility_date = \"2025-01-01\""))
}

///|
test "ensure_cloudflare_dev_files_with_fs prefers user wrangler.dev.toml" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project", recursive=true)
  mem.writeFileSync(
    "/project/wrangler.dev.toml", "main = \"worker.entry.dev.mjs\"\n",
  )
  let config_path = ensure_cloudflare_dev_files_with_fs(fs, "/project")
  assert_eq(config_path, "wrangler.dev.toml")
  assert_false(mem.existsSync("/project/.sol/dev/worker.entry.mjs"))
}

///|
test "should_enable_sol_dev: only `dev` mode flips SOL_DEV on" {
  assert_true(should_enable_sol_dev("dev"))
  assert_false(should_enable_sol_dev("prod"))
  // Defensive: any unknown mode is treated as non-dev so we never leak
  // the HMR <script> into a prod-ish bundle.
  assert_false(should_enable_sol_dev(""))
  assert_false(should_enable_sol_dev("preview"))
}
