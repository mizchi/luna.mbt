// Internal tests for URL rewriting in generated HTML.
// `assert_eq` is already brought in by page_generator_wbtest.mbt; the whole
// package shares one toplevel scope, so it must not be imported twice.

///|
/// `transform_url_path` strips numeric directory prefixes and normalises the
/// trailing slash. Neither belongs to a `#fragment` or `?query`, so the tail
/// has to be split off first — otherwise `/00_guide#intro` came back as
/// `/guide#intro/` and the browser looked for a fragment named `intro/`.
test "transform_url_path leaves the fragment alone" {
  assert_eq(transform_url_path("/00_guide", true), "/guide/")
  assert_eq(transform_url_path("/00_guide/", true), "/guide/")
  assert_eq(transform_url_path("/00_guide#intro", true), "/guide/#intro")
  assert_eq(transform_url_path("/00_guide/#intro", true), "/guide/#intro")
  assert_eq(transform_url_path("/01_luna/03_api#top", true), "/luna/api/#top")
  assert_eq(transform_url_path("/00_guide?q=1", true), "/guide/?q=1")
}

///|
/// A dot in the fragment is not a file extension: only the path decides
/// whether the trailing slash is skipped.
test "transform_url_path tells a file apart from a dotted fragment" {
  assert_eq(transform_url_path("/assets/logo.svg", true), "/assets/logo.svg")
  assert_eq(
    transform_url_path("/assets/logo.svg#icon", true),
    "/assets/logo.svg#icon",
  )
  assert_eq(transform_url_path("/00_guide#v1.0", true), "/guide/#v1.0")
}

///|
/// With trailingSlash off, the fragment still rides along untouched.
test "transform_url_path keeps the fragment with trailingSlash off" {
  assert_eq(transform_url_path("/00_guide#intro", false), "/guide#intro")
}

///|
/// External and protocol-relative URLs are never rewritten.
test "transform_url_path skips external URLs" {
  assert_eq(
    transform_url_path("https://example.com/00_x#y", true),
    "https://example.com/00_x#y",
  )
  assert_eq(transform_url_path("//cdn.example.com/x", true), "//cdn.example.com/x")
  assert_eq(transform_url_path("#anchor-only", true), "#anchor-only")
}
