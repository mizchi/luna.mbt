// Internal utilities for dom/client package (inlined to avoid cross-package dependencies)

///|
/// Extract Web Component name from URL (e.g., /static/wc_counter.js -> wc-counter)
fn extract_wc_name_from_url(url : String) -> String {
  @core.component_tag_name(url)
}
