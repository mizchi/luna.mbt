// Canonical CSS minifier shared by `astra/render` (static-build path) and
// `astra/assets` (middleware request path). Lives under `internal/` so it
// stays private to `mizchi/astra`.

///|
/// Strip comments and collapse whitespace. Idempotent; safe to apply to
/// already-minified input.
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
