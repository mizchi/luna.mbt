// Benchmarks for HTML/Attribute/JS escaping functions
// Run with: moon bench --target js src/core/render

// =============================================================================
// Test Data
// =============================================================================

///|
/// Short string with no special characters (fast path)
let short_safe : String = "Hello World"

///|
/// Short string with special characters (slow path)
let short_escape : String = "Hello <World> & \"Friends\""

///|
/// Medium length string without special chars
let medium_safe : String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

///|
/// Medium string with scattered special chars
let medium_escape : String = "Lorem ipsum <dolor> sit amet, consectetur & adipiscing \"elit\". Sed do eiusmod tempor 'incididunt' ut labore & dolore magna <aliqua>."

///|
/// Long string - typical HTML content
let long_safe : String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."

///|
/// Long string with special chars at end (worst case for fast path check)
let long_escape_end : String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. <script>"

///|
/// Heavily escaped string (many special chars)
let heavy_escape : String = "<div class=\"container\" data-value='test'>Hello & goodbye</div><script>alert('xss')</script>"

///|
/// JSON-like string (common in SSR)
let json_string : String = "{\"count\":42,\"name\":\"test\",\"items\":[1,2,3],\"active\":true}"

///|
/// JSON with script injection attempt
let json_with_script : String = "{\"count\":0,\"html\":\"<script>alert(1)</script>\"}"

// =============================================================================
// HTML Escape Benchmarks
// =============================================================================

///|
test "escape_html: short_safe (fast path)" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(short_safe)) })
}

///|
test "escape_html: short_escape (slow path)" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(short_escape)) })
}

///|
test "escape_html: medium_safe" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(medium_safe)) })
}

///|
test "escape_html: medium_escape" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(medium_escape)) })
}

///|
test "escape_html: long_safe" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(long_safe)) })
}

///|
test "escape_html: long_escape_end" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(long_escape_end)) })
}

///|
test "escape_html: heavy_escape" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_html(heavy_escape)) })
}

// =============================================================================
// Attribute Escape Benchmarks
// =============================================================================

///|
test "escape_attr: short_safe (fast path)" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_attr(short_safe)) })
}

///|
test "escape_attr: short_escape" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_attr(short_escape)) })
}

///|
test "escape_attr: json_string" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_attr(json_string)) })
}

///|
test "escape_attr: medium_safe" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_attr(medium_safe)) })
}

///|
test "escape_attr: heavy_escape" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_attr(heavy_escape)) })
}

// =============================================================================
// JS String Escape Benchmarks
// =============================================================================

///|
test "escape_js_string: short_safe" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_js_string(short_safe)) })
}

///|
test "escape_js_string: json_string" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_js_string(json_string)) })
}

///|
test "escape_js_string: json_with_script" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_js_string(json_with_script)) })
}

///|
test "escape_js_string: heavy_escape" (b : @bench.T) {
  b.bench(fn() { b.keep(escape_js_string(heavy_escape)) })
}

// =============================================================================
// StringBuilder vs String Return Comparison
// =============================================================================

///|
test "escape_html_to vs escape_html: medium_escape" (b : @bench.T) {
  let sb = StringBuilder::new(size_hint=256)
  b.bench(name="escape_html_to", fn() {
    sb.reset()
    escape_html_to(sb, medium_escape)
    b.keep(sb.to_string())
  })
  b.bench(name="escape_html", fn() { b.keep(escape_html(medium_escape)) })
}

///|
test "escape_attr_to vs escape_attr: json_string" (b : @bench.T) {
  let sb = StringBuilder::new(size_hint=128)
  b.bench(name="escape_attr_to", fn() {
    sb.reset()
    escape_attr_to(sb, json_string)
    b.keep(sb.to_string())
  })
  b.bench(name="escape_attr", fn() { b.keep(escape_attr(json_string)) })
}

// =============================================================================
// Void Element Check Benchmarks
// =============================================================================

///|
test "is_void_element: common tags" (b : @bench.T) {
  b.bench(name="div (false)", fn() { b.keep(is_void_element("div")) })
  b.bench(name="span (false)", fn() { b.keep(is_void_element("span")) })
  b.bench(name="img (true)", fn() { b.keep(is_void_element("img")) })
  b.bench(name="br (true)", fn() { b.keep(is_void_element("br")) })
  b.bench(name="input (true)", fn() { b.keep(is_void_element("input")) })
  b.bench(name="meta (true)", fn() { b.keep(is_void_element("meta")) })
}

// =============================================================================
// Fast Path Check Benchmarks
// =============================================================================

///|
test "needs_html_escape check" (b : @bench.T) {
  b.bench(name="short_safe", fn() { b.keep(needs_html_escape(short_safe)) })
  b.bench(name="medium_safe", fn() { b.keep(needs_html_escape(medium_safe)) })
  b.bench(name="long_safe", fn() { b.keep(needs_html_escape(long_safe)) })
  b.bench(name="long_escape_end", fn() {
    b.keep(needs_html_escape(long_escape_end))
  })
}

///|
test "needs_attr_escape check" (b : @bench.T) {
  b.bench(name="short_safe", fn() { b.keep(needs_attr_escape(short_safe)) })
  b.bench(name="json_string", fn() { b.keep(needs_attr_escape(json_string)) })
  b.bench(name="heavy_escape", fn() { b.keep(needs_attr_escape(heavy_escape)) })
}
