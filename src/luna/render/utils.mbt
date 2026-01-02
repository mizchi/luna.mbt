// Internal utilities for render package (inlined to avoid cross-package dependencies)

///|
/// Extract Web Component name from URL (e.g., /static/wc_counter.js -> wc-counter)
fn extract_wc_name_from_url(url : String) -> String {
  // Extract filename without extension
  let parts = url.split("/").collect()
  let filename_view = if parts.length() > 0 {
    parts[parts.length() - 1]
  } else {
    "".view()
  }
  let filename = filename_view.to_string()
  let name = if filename.has_suffix(".js") && filename.length() > 3 {
    filename[:filename.length() - 3].to_string() catch {
      _ => filename
    }
  } else {
    filename
  }
  // Convert underscores to hyphens for custom element name
  name.replace(old="_", new="-")
}
