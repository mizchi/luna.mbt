// Whitebox tests for mbtx_chunk_split.mbt

///|
test "split_mbtx_chunks: single entry returns ESM as-is" {
  let entries = [
    MbtxEntry::{
      id: "hello",
      code: "function shared() {}\n(() => {\n  shared();\n})();\n",
    },
  ]
  let result = split_mbtx_chunks(entries)
  assert_eq(result.shared_code, "")
  assert_eq(result.entries.length(), 1)
  assert_true(result.entries[0].code.contains("export default function render"))
}

///|
test "split_mbtx_chunks: extracts shared declarations" {
  let shared_fn = "function _M0shared(x) {\n  return x + 1;\n}"
  let code1 = shared_fn +
    "\nconst _M0unique1 = 1;\n(() => {\n  _M0shared(1);\n})();\n"
  let code2 = shared_fn +
    "\nconst _M0unique2 = 2;\n(() => {\n  _M0shared(2);\n})();\n"
  let entries = [
    MbtxEntry::{ id: "a", code: code1 },
    MbtxEntry::{ id: "b", code: code2 },
  ]
  let result = split_mbtx_chunks(entries)
  // Shared code should contain the shared function
  assert_true(result.shared_code.contains("export function _M0shared"))
  // Each entry should import from shared
  for entry in result.entries {
    assert_true(entry.code.contains("import {"))
    assert_true(entry.code.contains("_M0shared"))
    assert_true(entry.code.contains("export default function render"))
  }
  // Entry-specific declarations should remain
  assert_true(result.entries[0].code.contains("_M0unique1"))
  assert_true(result.entries[1].code.contains("_M0unique2"))
}

///|
test "split_mbtx_chunks: no shared declarations" {
  let entries = [
    MbtxEntry::{ id: "a", code: "const _M0a = 1;\n(() => {\n  _M0a;\n})();\n" },
    MbtxEntry::{ id: "b", code: "const _M0b = 2;\n(() => {\n  _M0b;\n})();\n" },
  ]
  let result = split_mbtx_chunks(entries)
  assert_eq(result.shared_code, "")
}
