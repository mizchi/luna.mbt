// `build_to_disk`: the in-process crawler that produces astra's static
// dump. The same `Middleware` value the dev server mounts on a Mars
// `Server` is reused here -- we walk `mw.list_urls()`, dispatch each URL
// through `@testing.invoke` (a real `Server::to_handler()` call, no
// localhost listener), and write the captured body to disk under the
// requested `output_dir`.
//
// PARITY-NOTE: every asset astra serves today is UTF-8 text (JS / CSS),
// so capturing `InvokeResult.body : String` round-trips correctly. If a
// future asset type is introduced (binary fonts, raster images), the
// invoker side has to expose a `body_bytes : Bytes` channel and this
// crawler must select per URL. The plan flagged that extension; T9's
// asset surface keeps it deferred until then.

///|
/// Walk every URL the middleware can serve, dispatch each through the
/// in-process handler, and write the captured response body to
/// `<output_dir>/<url-to-disk-path>`.
///
/// Async because `@testing.invoke` is async (it awaits the Mars handler's
/// returned Promise). Surfaces handler errors through the regular `Error`
/// channel so callers can decide whether to abort or continue.
pub async fn build_to_disk(
  mw : @middleware.Middleware,
  output_dir : String,
) -> Unit {
  ensure_dir(output_dir)
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  for url in mw.list_urls() {
    let res = @testing.invoke(app, path=url)
    let target = @path.join2(output_dir, url_to_disk_path(url))
    ensure_parent_dir(target)
    @fs.writeFileSync(target, @core.any(res.body)) catch {
      _ => ()
    }
  }
}

///|
/// Convert a request URL into a relative disk path under `output_dir`.
///
/// Mirrors `@astra.url_to_output_path` for page URLs (so `/`,
/// `/guide/`, `/guide/intro/` all turn into the right `index.html`),
/// and treats asset URLs (anything with an extension other than
/// `.html` after the last `/`) as direct file paths -- e.g.
/// `/assets/loader.js` -> `assets/loader.js`. The dispatch checks the
/// asset surface first so a page URL that happens to look extensioned
/// would never reach `build_to_disk` as an asset.
fn url_to_disk_path(url : String) -> String {
  if has_file_extension(url) {
    // Asset URL: drop the leading `/` and use the URL as-is.
    if url.has_prefix("/") {
      url[1:].to_string()
    } else {
      url
    }
  } else {
    @astra.url_to_output_path(url)
  }
}

///|
/// True when the last path segment contains a `.` (i.e. has a file
/// extension that is not part of the parent directory name). Empty
/// strings and bare slashes return `false`.
fn has_file_extension(url : String) -> Bool {
  // Walk once: each `/` resets the segment-dot tracker, so the final
  // value reflects whether the last segment contained a dot.
  let mut seen_dot_in_segment = false
  for ch in url {
    if ch == '/' {
      seen_dot_in_segment = false
    } else if ch == '.' {
      seen_dot_in_segment = true
    }
  }
  seen_dot_in_segment
}

///|
/// Recursively ensure the directory `path` exists, mirroring `mkdir -p`.
fn ensure_dir(path : String) -> Unit {
  if @fs.existsSync(path) {
    return
  }
  @fs.mkdirSync(path, recursive=true) catch {
    _ => ()
  }
}

///|
/// Ensure the parent directory of a target file exists.
fn ensure_parent_dir(target : String) -> Unit {
  let parent = @path.dirname(target)
  if parent == "" || parent == "." || parent == "/" {
    return
  }
  ensure_dir(parent)
}

