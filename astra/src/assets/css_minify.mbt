// Tiny CSS minifier mirrored from `astra/render/css_processor.mbt`'s
// private `minify_css`. Lifted into `assets` so the middleware-served
// `/assets/style.css` (and shiki.css, github-markdown.css) goes through
// the same shrink pass that `copy_static_assets` applies for production
// builds.
//
// Kept here rather than imported from `render` because `render` already
// depends on `assets` -- a back-edge would create a cycle. The function
// is intentionally a verbatim copy; tests for the canonical version live
// in `astra/render/`.

///|
/// Strip comments and collapse whitespace. Idempotent; safe to apply to
/// already-minified input. Keeps the implementation byte-equivalent to
/// `build_combined_css`'s minified output so middleware vs. static-build
/// parity holds at the byte level.
pub fn minify_css(css : String) -> String {
  let no_comments = remove_css_comments(css)
  no_comments
  .replace_all(old="\n", new=" ")
  .replace_all(old="\r", new="")
  .replace_all(old="\t", new=" ")
  .replace_all(old="  ", new=" ")
  .replace_all(old="  ", new=" ")
  .replace_all(old="  ", new=" ")
  .replace_all(old="  ", new=" ")
  .replace_all(old=" {", new="{")
  .replace_all(old="{ ", new="{")
  .replace_all(old=" }", new="}")
  .replace_all(old="} ", new="}")
  .replace_all(old=" :", new=":")
  .replace_all(old=": ", new=":")
  .replace_all(old=" ;", new=";")
  .replace_all(old="; ", new=";")
}

///|
/// Remove CSS comments `/* ... */`. Used by `minify_css`.
fn remove_css_comments(css : String) -> String {
  let result = StringBuilder::new()
  let chars = css.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    if i + 1 < len && chars[i] == '/' && chars[i + 1] == '*' {
      i = i + 2
      while i + 1 < len && !(chars[i] == '*' && chars[i + 1] == '/') {
        i = i + 1
      }
      i = i + 2
    } else {
      result.write_char(chars[i])
      i = i + 1
    }
  }
  result.to_string()
}
