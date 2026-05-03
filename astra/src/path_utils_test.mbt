// Unit tests for path_utils.mbt
// Note: String slice helpers are tested in internal/utils

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

// Note: String split/extract helpers are tested in internal/utils

// =============================================================================
// Locale Suffix Extraction
// =============================================================================

///|
test "extract_locale_suffix - with locale" {
  let locales = ["en", "ja", "fr"]
  inspect(
    extract_locale_suffix("intro.ja.md", locales),
    content="Some((\"ja\", \"intro.md\"))",
  )
  inspect(
    extract_locale_suffix("intro.fr.md", locales),
    content="Some((\"fr\", \"intro.md\"))",
  )
}

///|
test "extract_locale_suffix - without locale" {
  let locales = ["en", "ja", "fr"]
  inspect(extract_locale_suffix("intro.md", locales), content="None")
}

///|
test "extract_locale_suffix - invalid locale" {
  let locales = ["en", "ja"]
  inspect(extract_locale_suffix("intro.de.md", locales), content="None")
}

///|
test "extract_locale_suffix - different extensions" {
  let locales = ["en", "ja"]
  inspect(
    extract_locale_suffix("page.ja.mdx", locales),
    content="Some((\"ja\", \"page.mdx\"))",
  )
  inspect(
    extract_locale_suffix("page.ja.html", locales),
    content="Some((\"ja\", \"page.html\"))",
  )
}

///|
test "extract_locale_suffix - index files" {
  let locales = ["en", "ja"]
  inspect(
    extract_locale_suffix("index.ja.md", locales),
    content="Some((\"ja\", \"index.md\"))",
  )
}

///|
test "get_filename - basic" {
  inspect(get_filename("guide/intro.ja.md"), content="intro.ja.md")
  inspect(get_filename("intro.md"), content="intro.md")
  inspect(get_filename("a/b/c/file.md"), content="file.md")
}

///|
test "replace_filename - basic" {
  inspect(
    replace_filename("guide/intro.ja.md", "intro.md"),
    content="guide/intro.md",
  )
  inspect(replace_filename("intro.ja.md", "intro.md"), content="intro.md")
  inspect(
    replace_filename("a/b/c/file.ja.md", "file.md"),
    content="a/b/c/file.md",
  )
}
