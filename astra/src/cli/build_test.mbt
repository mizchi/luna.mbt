// Integration tests for `build_to_disk`: the in-process crawler that
// drives the same `Middleware` handler used at dev time, captures every
// response via `@testing.invoke`, and writes the bytes to disk.
//
// Pre-requisites: the moon test runner runs from the workspace root, so
// `cwd="astra"` resolves `tests/fixture/docs` against the astra subdir.

///|
async test "build_to_disk dumps every URL from list_urls() into output_dir" {
  let cfg = {
    ..@astra.SsgConfig::default(),
    docs_dir: "tests/fixture/docs",
    output_dir: "tests/fixture/.out",
  }
  let mw = @middleware.create(cfg, cwd="astra")
  let out_dir = "astra/tests/fixture/.out"
  // Best-effort: nuke any previous run so the fixture stays deterministic.
  if @fs.existsSync(out_dir) {
    @fs.rmSync(out_dir, recursive=true, force=true)
  }
  @cli.build_to_disk(mw, out_dir)
  // The fixture's index.md becomes /index.html under any trailing-slash
  // convention (root URL is the one URL where both conventions agree).
  let index_path = "astra/tests/fixture/.out/index.html"
  inspect(@fs.existsSync(index_path), content="true")
  let html = @fs.read_file_as_string(index_path)
  inspect(html.contains("Hello Astra"), content="true")
}

///|
/// Asset URLs from `list_urls()` must round-trip through the crawler too:
/// the static dump and the dev server agree on `/assets/loader.js`, etc.
async test "build_to_disk writes asset URLs alongside pages" {
  let cfg = {
    ..@astra.SsgConfig::default(),
    docs_dir: "tests/fixture/docs",
    output_dir: "tests/fixture/.out",
  }
  let mw = @middleware.create(cfg, cwd="astra")
  let out_dir = "astra/tests/fixture/.out"
  if @fs.existsSync(out_dir) {
    @fs.rmSync(out_dir, recursive=true, force=true)
  }
  @cli.build_to_disk(mw, out_dir)
  // `list_asset_urls` ships at least loader.js; if the crawler skipped it
  // the file would be missing from disk.
  let loader_path = "astra/tests/fixture/.out/assets/loader.js"
  inspect(@fs.existsSync(loader_path), content="true")
}
