// Canonical theme-override builder shared by `astra/render` (static-build
// path) and `astra/assets` (middleware request path). Caller is responsible
// for wrapping the result in `:root{...}`.

///|
/// Build CSS variable overrides from a `ThemeConfig`. Returns an empty
/// string when no theme variables are configured.
pub fn build_theme_overrides(theme : @astra.ThemeConfig) -> String {
  let vars = StringBuilder::new()
  if theme.primary_color is Some(v) {
    vars.write_string("--primary-color:\{v};")
  }
  if theme.secondary_color is Some(v) {
    vars.write_string("--secondary-color:\{v};")
  }
  if theme.accent_color is Some(v) {
    vars.write_string("--accent-color:\{v};")
  }
  if theme.success_color is Some(v) {
    vars.write_string("--success-color:\{v};")
  }
  if theme.warning_color is Some(v) {
    vars.write_string("--warning-color:\{v};")
  }
  if theme.error_color is Some(v) {
    vars.write_string("--error-color:\{v};")
  }
  if theme.text_color is Some(v) {
    vars.write_string("--text-color:\{v};")
  }
  if theme.text_muted_color is Some(v) {
    vars.write_string("--text-muted:\{v};")
  }
  if theme.heading_color is Some(v) {
    vars.write_string("--heading-color:\{v};")
  }
  if theme.link_color is Some(v) {
    vars.write_string("--link-color:\{v};")
  }
  if theme.link_hover_color is Some(v) {
    vars.write_string("--link-hover-color:\{v};")
  }
  if theme.background_color is Some(v) {
    vars.write_string("--bg-color:\{v};")
  }
  if theme.surface_color is Some(v) {
    vars.write_string("--surface-color:\{v};")
  }
  if theme.sidebar_bg_color is Some(v) {
    vars.write_string("--sidebar-bg:\{v};")
  }
  if theme.input_bg_color is Some(v) {
    vars.write_string("--input-bg:\{v};")
  }
  if theme.code_bg_color is Some(v) {
    vars.write_string("--code-bg:\{v};")
  }
  if theme.border_color is Some(v) {
    vars.write_string("--border-color:\{v};")
  }
  if theme.focus_ring_color is Some(v) {
    vars.write_string("--focus-ring-color:\{v};")
  }
  vars.to_string()
}
