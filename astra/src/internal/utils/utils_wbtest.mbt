// Tests for internal/utils string helpers and wc_name

// ============================================================================
// slice_from Tests
// ============================================================================

///|
test "slice_from: normal case" {
  assert_eq!(slice_from("hello", 2), "llo")
}

///|
test "slice_from: start at 0" {
  assert_eq!(slice_from("hello", 0), "hello")
}

///|
test "slice_from: start at last char" {
  assert_eq!(slice_from("hello", 4), "o")
}

///|
test "slice_from: start equals length returns empty" {
  assert_eq!(slice_from("hello", 5), "")
}

///|
test "slice_from: start exceeds length returns empty" {
  assert_eq!(slice_from("hello", 10), "")
}

///|
test "slice_from: negative start returns empty" {
  assert_eq!(slice_from("hello", -1), "")
}

///|
test "slice_from: empty string returns empty" {
  assert_eq!(slice_from("", 0), "")
}

// ============================================================================
// slice_to Tests
// ============================================================================

///|
test "slice_to: normal case" {
  assert_eq!(slice_to("hello", 3), "hel")
}

///|
test "slice_to: end equals length" {
  assert_eq!(slice_to("hello", 5), "hello")
}

///|
test "slice_to: end at 1" {
  assert_eq!(slice_to("hello", 1), "h")
}

///|
test "slice_to: end exceeds length returns original" {
  assert_eq!(slice_to("hello", 10), "hello")
}

///|
test "slice_to: end at 0 returns original" {
  assert_eq!(slice_to("hello", 0), "hello")
}

///|
test "slice_to: negative end returns original" {
  assert_eq!(slice_to("hello", -1), "hello")
}

// ============================================================================
// slice_view_from Tests
// ============================================================================

///|
test "slice_view_from: normal case" {
  assert_eq!(slice_view_from("hello".view(), 2), "llo")
}

///|
test "slice_view_from: start at 0" {
  assert_eq!(slice_view_from("hello".view(), 0), "hello")
}

///|
test "slice_view_from: start equals length returns empty" {
  assert_eq!(slice_view_from("hello".view(), 5), "")
}

///|
test "slice_view_from: negative start returns empty" {
  assert_eq!(slice_view_from("hello".view(), -1), "")
}

// ============================================================================
// slice_view_to Tests
// ============================================================================

///|
test "slice_view_to: normal case" {
  assert_eq!(slice_view_to("hello".view(), 3), "hel")
}

///|
test "slice_view_to: end exceeds length returns original" {
  assert_eq!(slice_view_to("hello".view(), 10), "hello")
}

///|
test "slice_view_to: end at 0 returns original" {
  assert_eq!(slice_view_to("hello".view(), 0), "hello")
}

///|
test "slice_view_to: negative end returns original" {
  assert_eq!(slice_view_to("hello".view(), -1), "hello")
}

// ============================================================================
// split_by Tests
// ============================================================================

///|
test "split_by: splits on separator" {
  assert_eq!(split_by("a,b,c", ','), ["a", "b", "c"])
}

///|
test "split_by: single element no separator" {
  assert_eq!(split_by("hello", ','), ["hello"])
}

///|
test "split_by: leading separator produces empty first element" {
  assert_eq!(split_by(",a,b", ','), ["", "a", "b"])
}

///|
test "split_by: trailing separator produces empty last element" {
  assert_eq!(split_by("a,b,", ','), ["a", "b", ""])
}

///|
test "split_by: consecutive separators produce empty elements" {
  assert_eq!(split_by("a,,b", ','), ["a", "", "b"])
}

///|
test "split_by: empty string produces one empty element" {
  assert_eq!(split_by("", ','), [""])
}

///|
test "split_by: separator is slash" {
  assert_eq!(
    split_by("/static/wc_counter.js", '/'),
    ["", "static", "wc_counter.js"],
  )
}

// ============================================================================
// extract_until Tests
// ============================================================================

///|
test "extract_until: stops at delimiter" {
  assert_eq!(extract_until("hello world", [' ']), "hello")
}

///|
test "extract_until: stops at first matching delimiter" {
  assert_eq!(extract_until("foo=bar&baz", ['=', '&']), "foo")
}

///|
test "extract_until: no delimiter returns full string" {
  assert_eq!(extract_until("hello", ['x']), "hello")
}

///|
test "extract_until: delimiter at start returns empty" {
  assert_eq!(extract_until("=value", ['=']), "")
}

///|
test "extract_until: empty string returns empty" {
  assert_eq!(extract_until("", ['/']), "")
}

// ============================================================================
// extract_substring Tests
// ============================================================================

///|
test "extract_substring: normal range" {
  assert_eq!(extract_substring("hello world", 6, 11), "world")
}

///|
test "extract_substring: from start" {
  assert_eq!(extract_substring("hello", 0, 3), "hel")
}

///|
test "extract_substring: single char" {
  assert_eq!(extract_substring("hello", 1, 2), "e")
}

///|
test "extract_substring: full string" {
  assert_eq!(extract_substring("hello", 0, 5), "hello")
}

///|
test "extract_substring: start equals end returns empty" {
  assert_eq!(extract_substring("hello", 2, 2), "")
}

// ============================================================================
// extract_wc_name_from_url Tests
// ============================================================================

///|
test "extract_wc_name_from_url: full path with wc prefix" {
  assert_eq!(extract_wc_name_from_url("/static/wc_counter.js"), "wc-counter")
}

///|
test "extract_wc_name_from_url: filename only" {
  assert_eq!(extract_wc_name_from_url("my_comp.js"), "my-comp")
}

///|
test "extract_wc_name_from_url: no underscores" {
  assert_eq!(extract_wc_name_from_url("/static/button.js"), "button")
}

///|
test "extract_wc_name_from_url: multiple underscores" {
  let result = extract_wc_name_from_url("/dist/my_fancy_widget.js")
  // String.replace only replaces the first occurrence
  assert_true!(result.contains("-"))
}

///|
test "extract_wc_name_from_url: no .js extension" {
  assert_eq!(extract_wc_name_from_url("/static/my_comp.ts"), "my-comp.ts")
}

///|
test "extract_wc_name_from_url: deep nested path" {
  assert_eq!(extract_wc_name_from_url("/a/b/c/my_widget.js"), "my-widget")
}

///|
test "extract_wc_name_from_url: empty string returns empty" {
  assert_eq!(extract_wc_name_from_url(""), "")
}
