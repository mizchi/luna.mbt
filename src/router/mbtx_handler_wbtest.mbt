// Whitebox tests for mbtx_handler.mbt

///|
test "MbtxRoute struct creation" {
  let route : MbtxRoute = { path: "/hello", js_path: "/tmp/hello.mjs" }
  assert_eq(route.path, "/hello")
  assert_eq(route.js_path, "/tmp/hello.mjs")
}

///|
test "transform_mbtx_to_esm: basic IIFE" {
  let code = "const helper = 1;\n(() => {\n  console.log(helper);\n})();\n"
  let esm = transform_mbtx_to_esm(code)
  assert_true(esm.contains("export default function render(env)"))
  assert_true(esm.contains("globalThis.__MBTX_ENV__ = env"))
  assert_true(esm.contains("return globalThis.__MBTX_RESPONSE__"))
  assert_true(esm.contains("const helper = 1;"))
  // IIFE markers should be gone
  assert_true(not(esm.contains("(() => {")))
}

///|
test "transform_mbtx_to_esm: preserves helper definitions" {
  let code = "function Foo() {}\nconst bar = 42;\n(() => {\n  Foo();\n})();\n"
  let esm = transform_mbtx_to_esm(code)
  assert_true(esm.contains("function Foo() {}"))
  assert_true(esm.contains("const bar = 42;"))
}

///|
test "transform_mbtx_to_esm: no IIFE returns unchanged" {
  let code = "console.log('hello');"
  let esm = transform_mbtx_to_esm(code)
  assert_eq(esm, code)
}
