// Integration tests for `build_to_disk`: the in-process crawler that
// drives the same `Middleware` handler used at dev time, captures every
// response via `@testing.invoke`, and writes the bytes to disk.
//
// Pre-requisites: the moon test runner runs this package from the astra
// module root, so `cwd="."` resolves `tests/fixture/docs` against astra/.

///|
async test "build_to_disk dumps every URL from list_urls() into output_dir" {
  let cfg = {
    ..@astra.SsgConfig::default(),
    docs_dir: "tests/fixture/docs",
    output_dir: "tests/fixture/.out/pages",
  }
  let mw = @middleware.create(cfg, cwd=".")
  let out_dir = "tests/fixture/.out/pages"
  // Best-effort: nuke any previous run so the fixture stays deterministic.
  if @fs.existsSync(out_dir) {
    @fs.rmSync(out_dir, recursive=true, force=true)
  }
  @cli.build_to_disk(mw, out_dir)
  // The fixture's index.md becomes /index.html under any trailing-slash
  // convention (root URL is the one URL where both conventions agree).
  let index_path = "tests/fixture/.out/pages/index.html"
  inspect(@fs.existsSync(index_path), content="true")
  let html = @fs.read_file_as_string(index_path)
  inspect(html.contains("Hello Astra"), content="true")
}

///|
/// Asset URLs from `list_urls()` must round-trip through the crawler too:
/// the static dump and the dev server agree on `/assets/style.css`, etc.
async test "build_to_disk writes asset URLs alongside pages" {
  let cfg = {
    ..@astra.SsgConfig::default(),
    docs_dir: "tests/fixture/docs",
    output_dir: "tests/fixture/.out/assets",
  }
  let mw = @middleware.create(cfg, cwd=".")
  let out_dir = "tests/fixture/.out/assets"
  if @fs.existsSync(out_dir) {
    @fs.rmSync(out_dir, recursive=true, force=true)
  }
  @cli.build_to_disk(mw, out_dir)
  // `list_asset_urls` ships at least style.css; if the crawler skipped it
  // the file would be missing from disk.
  let style_path = "tests/fixture/.out/assets/assets/style.css"
  inspect(@fs.existsSync(style_path), content="true")
}

///|
/// Page URLs whose last segment contains a dot (`/release/v1.0/`) must
/// still be written through `url_to_output_path` -- as
/// `release/v1.0/index.html`, not as a flat `release/v1.0` file. The
/// previous `has_file_extension` heuristic misclassified such URLs as
/// assets; the fix routes by membership in `mw.asset_urls()` instead.
async test "build_to_disk routes page URLs with a dot to <dir>/index.html" {
  let cfg = {
    ..@astra.SsgConfig::default(),
    docs_dir: "tests/fixture/docs",
    output_dir: "tests/fixture/.out/dotted-page",
  }
  let mw = @middleware.create(cfg, cwd=".")
  let out_dir = "tests/fixture/.out/dotted-page"
  if @fs.existsSync(out_dir) {
    @fs.rmSync(out_dir, recursive=true, force=true)
  }
  @cli.build_to_disk(mw, out_dir)
  // Correct page output: nested index.html.
  let page_index = "tests/fixture/.out/dotted-page/release/v1.0/index.html"
  inspect(@fs.existsSync(page_index), content="true")
  // The flat-file misclassification path would create `release/v1.0` as
  // a regular file. Assert it's a directory instead, so a regression
  // back to the dot-heuristic trips this test.
  let target = "tests/fixture/.out/dotted-page/release/v1.0"
  let stat_is_dir = @fs.statSync(target).isDirectory() catch { _ => false }
  inspect(stat_is_dir, content="true")
}
