// Asset URL → body lookup. Used by the astra middleware to serve static
// assets (the bundled island loader, Sol's default CSS, the Shiki theme,
// the GitHub-markdown stylesheet) directly from request paths instead of
// requiring a prior `copy_static_assets` build step.
//
// The set of paths recognised here mirrors what `copy_static_assets`
// writes to disk under `<output_dir>/assets/`, so a hot middleware fetch
// and a static-build dump produce equivalent bytes for the same URL.

///|
/// A single asset response: the bytes to write back and the MIME type the
/// middleware should advertise via `Content-Type`. Body is `String` because
/// every recognised asset today is a UTF-8 text resource (JS / CSS).
pub(all) struct Asset {
  body : String
  content_type : String
}

///|
/// Look up a static asset by request path. Returns `None` for paths that
/// are not part of astra's built-in asset surface; callers fall through to
/// regular page dispatch in that case.
///
/// This is the public counterpart to `copy_static_assets` in the render
/// package: serving the same URL via this function and via a static build
/// must yield equivalent bytes for the same SSG config. The `config`
/// argument feeds the theme-aware `get_default_css` so `/assets/style.css`
/// matches what `copy_static_assets` writes for the same `SsgConfig`.
///
/// PARITY-NOTE: build-time CSS-utility extraction (`extract_css_utilities`
/// in `astra/src/render/css_processor.mbt`) is not run here -- it requires
/// a filesystem scan + child_process invocation of an external `extract.js`
/// node script that's only available during a full `copy_static_assets_async`
/// run. The middleware-served CSS therefore omits the auto-extracted utility
/// classes. Closing that gap requires either caching the last build's utility
/// CSS at `Middleware::create_async` time or wiring the extractor into the
/// asset path; tracked in `astra/docs/parity-notes.md`.
///
/// Theme variable overrides (`build_theme_overrides_css`) ARE applied here
/// so the served CSS includes the same `:root{--primary-color:...}`
/// declaration that `build_combined_css` injects in the static dump path.
/// CSS minification is still NOT applied (build path runs `minify_css` for
/// non-dev builds); the served body is the unminified text. Both are noted
/// in parity-notes.
pub fn lookup_asset(
  path : String,
  config : @astra.SsgConfig,
  minify~ : Bool = false,
) -> Asset? {
  match path {
    "/assets/loader.js" =>
      Some({ body: get_island_loader_js(), content_type: js_content_type() })
    "/assets/style.css" =>
      Some({
        body: build_style_css_body(config, minify~),
        content_type: css_content_type(),
      })
    "/assets/markdown.css" | "/assets/github-markdown.css" => {
      let raw = get_github_markdown_css()
      let body = if minify { @css_kit.minify_css(raw) } else { raw }
      Some({ body, content_type: css_content_type() })
    }
    "/assets/shiki.css" => {
      let raw = @shiki.generate_shiki_css()
      let body = if minify { @css_kit.minify_css(raw) } else { raw }
      Some({ body, content_type: css_content_type() })
    }
    _ => None
  }
}

///|
/// Compose the body served at `/assets/style.css`: base default CSS plus
/// a `:root{...}` block when the SsgConfig's `ThemeConfig` declares any
/// overrides. When `minify` is true, run the result through `minify_css`
/// so the served body byte-matches the production static-build output.
/// Mirrors the tail of `build_combined_css` in
/// `astra/render/css_processor.mbt`.
fn build_style_css_body(config : @astra.SsgConfig, minify~ : Bool) -> String {
  let base = get_default_css(config)
  let theme_vars = @css_kit.build_theme_overrides(config.theme)
  let combined = if theme_vars.is_empty() {
    base
  } else {
    "\{base}:root{\{theme_vars}}"
  }
  if minify {
    @css_kit.minify_css(combined)
  } else {
    combined
  }
}

///|
/// URLs every `lookup_asset` recognises. Used by `Middleware::list_urls`
/// so the build crawler can dump assets alongside pages, and by parity
/// tests asserting the dev server and the static dump cover the same
/// surface.
pub fn list_asset_urls() -> Array[String] {
  [
    "/assets/loader.js",
    "/assets/style.css",
    "/assets/github-markdown.css",
    "/assets/shiki.css",
  ]
}

///|
fn js_content_type() -> String {
  "application/javascript; charset=utf-8"
}

///|
fn css_content_type() -> String {
  "text/css; charset=utf-8"
}
