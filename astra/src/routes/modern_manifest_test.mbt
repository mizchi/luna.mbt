///|
test "component scanners recognize current and legacy package manifests" {
  for manifest_name in ["moon.pkg", "moon.pkg.json"] {
    assert_true(is_moonbit_component(manifest_name))
    let fs = @fs_adapter.MemFSAdapter::new()
    fs.memfs().mkdirSync("/project/pages/counter/client", recursive=true)
    fs.memfs().writeFileSync("/project/pages/counter/" + manifest_name, "")
    let routes = scan_pages_dir(fs, "pages", "/project")
    assert_eq(routes.routes.length(), 1)
    guard routes.routes[0] is Component(entry) else {
      fail("expected a component route")
    }
    assert_eq(entry.path, "/counter")
    let pages = scan_docs_dir_with_fs(fs, "pages", "/project")
    assert_eq(pages.length(), 1)
    assert_eq(pages[0].url_path, "/counter/")
  }
}

///|
test "modern documentation packages keep their markdown pages" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/guide", recursive=true)
  fs.memfs().writeFileSync("/project/docs/guide/moon.pkg", "")
  fs
  .memfs()
  .writeFileSync("/project/docs/guide/start.mbt.md", "# Getting started")
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  assert_eq(pages.length(), 1)
  assert_eq(pages[0].url_path, "/guide/start/")
}
