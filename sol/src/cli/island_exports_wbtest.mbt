///|
test "read_exports_from_pkg reads modern JS exports with comments and trailing commas" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/client", recursive=true)
  mem.writeFileSync(
    "/client/moon.pkg",
    (
      #|supported_targets = "js"
      #|options(
      #|  link: {
      #|    "wasm-gc": { "exports": ["wasm_only"] },
      #|    "js": {
      #|      // These names drive Island entrypoint generation.
      #|      "exports": ["counter", "contact_form", "wc_counter",],
      #|      "format": "esm",
      #|    },
      #|  },
      #|)
    ),
  )
  assert_eq(read_exports_from_pkg_with_fs(fs, "/client"), [
    "counter", "contact_form", "wc_counter",
  ])
}

///|
test "read_exports_from_pkg prefers moon.pkg over legacy JSON" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/client", recursive=true)
  mem.writeFileSync(
    "/client/moon.pkg", "options(link: { \"js\": { \"exports\": [\"counter\"] } })",
  )
  mem.writeFileSync(
    "/client/moon.pkg.json", "{\"link\":{\"js\":{\"exports\":[\"legacy\"]}}}",
  )
  assert_eq(read_exports_from_pkg_with_fs(fs, "/client"), ["counter"])
}

///|
test "read_exports_from_pkg preserves legacy JSON compatibility" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/client", recursive=true)
  mem.writeFileSync(
    "/client/moon.pkg.json", "{\"link\":{\"js\":{\"exports\":[\"counter\"]}}}",
  )
  assert_eq(read_exports_from_pkg_with_fs(fs, "/client"), ["counter"])
}

///|
test "read_exports_from_pkg tolerates missing and invalid manifests" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/client", recursive=true)
  assert_eq(read_exports_from_pkg_with_fs(fs, "/client"), [])
  mem.writeFileSync("/client/moon.pkg", "options(link: {")
  assert_eq(read_exports_from_pkg_with_fs(fs, "/client"), [])
}
