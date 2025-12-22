// Tests for file router and path utilities

///|
/// Tests for path utilities (moved to @ssg)
test "parse_numeric_prefix with valid prefix" {
  let (order, name) = @ssg.parse_numeric_prefix("00_guide")
  assert_eq(order, 0)
  assert_eq(name, "guide")
}

///|
test "parse_numeric_prefix with multi-digit prefix" {
  let (order, name) = @ssg.parse_numeric_prefix("123_section")
  assert_eq(order, 123)
  assert_eq(name, "section")
}

///|
test "parse_numeric_prefix without prefix" {
  let (order, name) = @ssg.parse_numeric_prefix("guide")
  assert_eq(order, 2147483647) // Max int for unprefixed
  assert_eq(name, "guide")
}

///|
test "parse_numeric_prefix with only digits" {
  // "123" without underscore should not be treated as prefix
  let (order, name) = @ssg.parse_numeric_prefix("123")
  assert_eq(order, 2147483647)
  assert_eq(name, "123")
}

///|
test "strip_numeric_prefixes single segment" {
  let result = @ssg.strip_numeric_prefixes("00_guide")
  assert_eq(result, "guide")
}

///|
test "strip_numeric_prefixes multiple segments" {
  let result = @ssg.strip_numeric_prefixes("00_guide/01_getting-started.md")
  assert_eq(result, "guide/getting-started.md")
}

///|
test "strip_numeric_prefixes mixed segments" {
  let result = @ssg.strip_numeric_prefixes("00_guide/intro.md")
  assert_eq(result, "guide/intro.md")
}

///|
test "build_sort_key single segment" {
  let key = @ssg.build_sort_key("00_guide")
  assert_eq(key, "00000000_guide")
}

///|
test "build_sort_key multiple segments" {
  let key = @ssg.build_sort_key("00_guide/01_intro.md")
  assert_eq(key, "00000000_guide/00000001_intro.md")
}

///|
test "build_sort_key unprefixed comes last" {
  let key1 = @ssg.build_sort_key("00_guide")
  let key2 = @ssg.build_sort_key("guide") // No prefix
  // Unprefixed should have max int padded, so it sorts after prefixed
  assert_true(key1 < key2)
}

///|
test "file_to_url_path strips prefix" {
  let url = @routes.file_to_url_path("00_guide/01_getting-started.md")
  assert_eq(url, "/guide/getting-started/")
}

///|
test "file_to_url_path with index" {
  let url = @routes.file_to_url_path("00_guide/index.md")
  assert_eq(url, "/guide/")
}

///|
test "file_to_url_path root index" {
  let url = @routes.file_to_url_path("index.md")
  assert_eq(url, "/")
}

///|
test "file_to_url_path without trailing slash" {
  let url = @routes.file_to_url_path(
    "00_guide/01_getting-started.md",
    trailing_slash=false,
  )
  assert_eq(url, "/guide/getting-started")
}

///|
test "file_to_url_path index without trailing slash" {
  let url = @routes.file_to_url_path("00_guide/index.md", trailing_slash=false)
  assert_eq(url, "/guide")
}

///|
test "pad_number basic" {
  assert_eq(@ssg.pad_number(5, 4), "0005")
  assert_eq(@ssg.pad_number(123, 6), "000123")
  assert_eq(@ssg.pad_number(12345678, 8), "12345678")
  assert_eq(@ssg.pad_number(123456789, 8), "123456789") // Longer than width
}

///|
test "string comparison for sort keys" {
  let a = "00000000_index"
  let b = "2147483647_flow"
  // '0' < '2' in ASCII, so "00000000" < "2147483647"
  assert_true(a < b)
}

///|
test "bubble sort strings" {
  let arr = ["2147483647_c", "00000000_a", "00000001_b", "2147483647_d"]
  let result = arr.copy()
  let n = result.length()
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if result[j] > result[j + 1] {
        let temp = result[j]
        result[j] = result[j + 1]
        result[j + 1] = temp
      }
    }
  }
  assert_eq(result[0], "00000000_a")
  assert_eq(result[1], "00000001_b")
  assert_eq(result[2], "2147483647_c")
  assert_eq(result[3], "2147483647_d")
}

///|
test "sort_by strings" {
  let arr = ["2147483647_c", "00000000_a", "00000001_b", "2147483647_d"]
  arr.sort_by(fn(a, b) { a.compare(b) })
  assert_eq(arr[0], "00000000_a")
  assert_eq(arr[1], "00000001_b")
  assert_eq(arr[2], "2147483647_c")
  assert_eq(arr[3], "2147483647_d")
}

///|
test "string compare function" {
  assert_eq("00000000".compare("2147483647"), -1)
  assert_eq("2147483647".compare("00000000"), 1)
  assert_eq("00000000".compare("00000000"), 0)
}

///|
test "sort_pages function" {
  let pages : Array[@astra.PageMeta] = [
    @astra.PageMeta::new(
      "flow_for.md",
      "/flow_for",
      sort_key="2147483647_flow_for.md",
    ),
    @astra.PageMeta::new("00_index.md", "/", sort_key="00000000_index.md"),
    @astra.PageMeta::new(
      "01_basics.md",
      "/basics",
      sort_key="00000001_basics.md",
    ),
  ]
  let sorted = @routes.sort_pages(pages)
  // Should be: index, basics, flow_for
  assert_eq(sorted[0].source_path, "00_index.md")
  assert_eq(sorted[1].source_path, "01_basics.md")
  assert_eq(sorted[2].source_path, "flow_for.md")
}

///|
test "sort_pages with full path keys" {
  // Exact same keys as in the actual build
  let pages : Array[@astra.PageMeta] = [
    @astra.PageMeta::new(
      "tutorial/00_index.md",
      "/tutorial/",
      sort_key="2147483647_tutorial/00000000_index.md",
    ),
    @astra.PageMeta::new(
      "tutorial/01_basics.md",
      "/tutorial/basics",
      sort_key="2147483647_tutorial/00000001_basics.md",
    ),
    @astra.PageMeta::new(
      "tutorial/flow_for.md",
      "/tutorial/flow_for",
      sort_key="2147483647_tutorial/2147483647_flow_for.md",
    ),
  ]
  let sorted = @routes.sort_pages(pages)
  // Should be: index (00000000), basics (00000001), flow_for (2147483647)
  assert_eq(sorted[0].source_path, "tutorial/00_index.md")
  assert_eq(sorted[1].source_path, "tutorial/01_basics.md")
  assert_eq(sorted[2].source_path, "tutorial/flow_for.md")
}

// Note: MoonBit String.compare has a bug where it returns wrong results
// for different-length strings. The compare_strings_lex function in
// file_router.mbt is used as a workaround for sorting.
