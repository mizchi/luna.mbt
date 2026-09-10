// White-box tests for internal link resolution.
// `resolve_href` and `normalize_href` are package-private, so these live in a
// wbtest file rather than transformer_test.mbt.

///|
/// A `#fragment` is not part of the path: normalising must not move the
/// trailing slash past it, or the browser looks for a fragment named `intro/`.
test "normalize_href keeps the trailing slash before the fragment" {
  inspect(normalize_href("/guide"), content="/guide/")
  inspect(normalize_href("/guide/"), content="/guide/")
  inspect(normalize_href("/guide#intro"), content="/guide/#intro")
  inspect(normalize_href("/guide/#intro"), content="/guide/#intro")
  inspect(normalize_href("/guide?q=1"), content="/guide/?q=1")
  // a real file keeps its extension and gains no slash
  inspect(normalize_href("/logo.svg#icon"), content="/logo.svg#icon")
  // a dot inside the fragment must not be mistaken for a file extension
  inspect(normalize_href("/guide#v1.0"), content="/guide/#v1.0")
}

///|
/// `available_urls` holds page URLs without fragments, so an anchored link on
/// a localised page has to be looked up by path — otherwise the lookup misses
/// and the link silently falls back to the default locale.
test "resolve_href keeps the locale prefix on an anchored link" {
  let urls = ["/luna/api/signals/", "/ja/luna/api/signals/"]
  inspect(
    resolve_href("./signals", "/ja/luna/api/", true, "/ja", urls),
    content="/ja/luna/api/signals/",
  )
  inspect(
    resolve_href("./signals#batch", "/ja/luna/api/", true, "/ja", urls),
    content="/ja/luna/api/signals/#batch",
  )
}

///|
/// When the localised page really is missing, an anchored link still falls
/// back to the default locale — and keeps its fragment.
test "resolve_href falls back to the default locale with the fragment intact" {
  let urls = ["/luna/api/signals/"]
  inspect(
    resolve_href("./signals#batch", "/ja/luna/api/", true, "/ja", urls),
    content="/luna/api/signals/#batch",
  )
}
