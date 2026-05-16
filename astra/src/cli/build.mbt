// `build_to_disk`: the in-process crawler that produces astra's static
// dump. Walks `mw.list_urls()`, asks the middleware to render each URL
// directly via `Middleware::render_url` (no Mars `Server`, no
// `@testing.invoke`, no localhost listener), and writes the rendered
// body to disk under the requested `output_dir`.
//
// PARITY-NOTE: every asset astra serves today is UTF-8 text (JS / CSS),
// so writing `RenderedResponse.body : String` round-trips correctly. If
// a future asset type is introduced (binary fonts, raster images), the
// middleware needs to expose a `body_bytes : Bytes` channel and this
// crawler must select per URL. The plan flagged that extension; T9's
// asset surface keeps it deferred until then.

///|
/// Walk every URL the middleware can serve, render each one in-process,
/// and write the rendered body to `<output_dir>/<url-to-disk-path>`.
pub fn build_to_disk(mw : @middleware.Middleware, output_dir : String) -> Unit {
  ensure_dir(output_dir)
  // Page-vs-asset routing comes from the middleware's own asset surface,
  // not a dot-in-segment heuristic: a page URL like `/release/v1.0/`
  // legitimately contains a dot but must still resolve to
  // `release/v1.0/index.html`, never a flat `release/v1.0` file.
  let asset_urls = mw.asset_urls()
  for url in mw.list_urls() {
    let res = mw.render_url(url)
    let target = @path.join2(output_dir, url_to_disk_path(url, asset_urls))
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
/// and treats every URL in `asset_urls` as a direct file path -- e.g.
/// `/assets/loader.js` -> `assets/loader.js`. Membership is checked
/// rather than guessed from the URL shape, so a page URL like
/// `/release/v1.0/` is routed through `url_to_output_path` even though
/// its last segment contains a dot.
fn url_to_disk_path(url : String, asset_urls : Array[String]) -> String {
  if asset_urls.contains(url) {
    // Asset URL: drop the leading `/` and use the URL as-is.
    if url.has_prefix("/") {
      url[1:].to_owned()
    } else {
      url
    }
  } else {
    @astra.url_to_output_path(url)
  }
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
