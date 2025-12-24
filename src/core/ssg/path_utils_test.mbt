// Unit tests for path_utils.mbt

// =============================================================================
// String Slice Helpers
// =============================================================================

///|
test "slice_from - basic" {
  inspect(slice_from("hello", 2), content="llo")
  inspect(slice_from("hello", 0), content="hello")
  inspect(slice_from("hello", 5), content="")
}

///|
test "slice_from - edge cases" {
  inspect(slice_from("hello", -1), content="")
  inspect(slice_from("hello", 10), content="")
  inspect(slice_from("", 0), content="")
}

///|
test "slice_to - basic" {
  inspect(slice_to("hello", 3), content="hel")
  inspect(slice_to("hello", 5), content="hello")
  inspect(slice_to("hello", 0), content="hello")
}

///|
test "slice_to - edge cases" {
  inspect(slice_to("hello", -1), content="hello")
  inspect(slice_to("hello", 10), content="hello")
  inspect(slice_to("", 0), content="")
}

///|
test "slice_view_from - basic" {
  let s : StringView = "hello"
  inspect(slice_view_from(s, 2), content="llo")
  inspect(slice_view_from(s, 0), content="hello")
}

///|
test "slice_view_to - basic" {
  let s : StringView = "hello"
  inspect(slice_view_to(s, 3), content="hel")
  inspect(slice_view_to(s, 5), content="hello")
}

// =============================================================================
// Integer Parsing
// =============================================================================

///|
test "parse_int_simple - basic" {
  inspect(parse_int_simple("123"), content="123")
  inspect(parse_int_simple("0"), content="0")
  inspect(parse_int_simple("42"), content="42")
}

///|
test "parse_int_simple - leading zeros" {
  inspect(parse_int_simple("007"), content="7")
  inspect(parse_int_simple("00123"), content="123")
}

// =============================================================================
// URL Path Conversion
// =============================================================================

///|
test "url_to_output_path - root" {
  inspect(url_to_output_path("/"), content="index.html")
}

///|
test "url_to_output_path - with trailing slash" {
  inspect(url_to_output_path("/guide/intro/"), content="guide/intro/index.html")
}

///|
test "url_to_output_path - without trailing slash" {
  inspect(url_to_output_path("/guide/intro"), content="guide/intro/index.html")
}

///|
test "url_to_output_path - deep path" {
  inspect(
    url_to_output_path("/docs/api/reference/"),
    content="docs/api/reference/index.html",
  )
}

///|
test "file_to_url_path - html extension" {
  inspect(file_to_url_path("custom.html"), content="/custom/")
  inspect(
    file_to_url_path("guide/advanced.html", trailing_slash=false),
    content="/guide/advanced",
  )
}

///|
test "file_to_url_path - html index" {
  inspect(file_to_url_path("docs/index.html"), content="/docs/")
}

// =============================================================================
// String Comparison
// =============================================================================

///|
test "compare_strings_lex - basic" {
  inspect(compare_strings_lex("abc", "abd"), content="-1")
  inspect(compare_strings_lex("abd", "abc"), content="1")
  inspect(compare_strings_lex("abc", "abc"), content="0")
}

///|
test "compare_strings_lex - different lengths" {
  inspect(compare_strings_lex("ab", "abc"), content="-1")
  inspect(compare_strings_lex("abc", "ab"), content="1")
}

///|
test "compare_strings_lex - prefix sorting" {
  inspect(compare_strings_lex("00000000_a", "00000001_b"), content="-1")
  inspect(compare_strings_lex("00000001_a", "2147483647_b"), content="-1")
}

// =============================================================================
// String Utilities
// =============================================================================

///|
test "capitalize_first - basic" {
  inspect(capitalize_first("hello"), content="Hello")
  inspect(capitalize_first("HELLO"), content="HELLO")
  inspect(capitalize_first("hello world"), content="Hello world")
}

///|
test "capitalize_first - edge cases" {
  inspect(capitalize_first(""), content="")
  inspect(capitalize_first("a"), content="A")
  inspect(capitalize_first("123abc"), content="123abc")
}

///|
test "get_dir_name - basic" {
  inspect(get_dir_name("path/to/file.md"), content="file.md")
  inspect(get_dir_name("file.md"), content="file.md")
}

///|
test "get_url_dir - basic" {
  // Returns path up to last slash (parent including current segment)
  inspect(get_url_dir("/guide/intro/"), content="/guide/intro")
  inspect(get_url_dir("/guide/"), content="/guide")
  inspect(get_url_dir("/file"), content="/")
}

///|
test "get_url_dir - root" {
  inspect(get_url_dir("/"), content="/")
}

// =============================================================================
// String Split and Extract
// =============================================================================

///|
test "split_by - basic" {
  let result = split_by("a,b,c", ',')
  inspect(result.length(), content="3")
  inspect(result[0], content="a")
  inspect(result[1], content="b")
  inspect(result[2], content="c")
}

///|
test "split_by - no separator" {
  let result = split_by("abc", ',')
  inspect(result.length(), content="1")
  inspect(result[0], content="abc")
}

///|
test "split_by - empty parts" {
  let result = split_by("a,,c", ',')
  inspect(result.length(), content="3")
  inspect(result[0], content="a")
  inspect(result[1], content="")
  inspect(result[2], content="c")
}

///|
test "extract_until - basic" {
  inspect(extract_until("hello?world", ['?']), content="hello")
  inspect(extract_until("hello#world", ['#', '?']), content="hello")
}

///|
test "extract_until - no delimiter" {
  inspect(extract_until("hello", ['?']), content="hello")
}

///|
test "extract_substring - basic" {
  inspect(extract_substring("hello world", 0, 5), content="hello")
  inspect(extract_substring("hello world", 6, 11), content="world")
}

///|
test "extract_substring - partial" {
  inspect(extract_substring("hello", 2, 4), content="ll")
}

///|
test "extract_wc_name_from_url - basic" {
  inspect(
    extract_wc_name_from_url("/static/wc_counter.js"),
    content="wc-counter",
  )
  inspect(
    extract_wc_name_from_url("/assets/my_component.js"),
    content="my-component",
  )
}

///|
test "extract_wc_name_from_url - no extension" {
  inspect(extract_wc_name_from_url("/static/component"), content="component")
}

///|
test "extract_wc_name_from_url - underscore to hyphen" {
  // Note: String.replace only replaces first occurrence
  inspect(extract_wc_name_from_url("/wc_counter.js"), content="wc-counter")
}
