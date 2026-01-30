// Sol Fragment Response
//
// Handles X-Sol-Fragment requests for CSR navigation.
// Returns HTML with <template data-sol-outlet="..."> elements
// that can be swapped by sol-nav.js on the client.

// ============================================================================
// Fragment Header Detection
// ============================================================================

///|
/// Check if request has X-Sol-Fragment header
/// Uses raw_header to access custom headers not in Mars's common headers list
pub fn has_fragment_header(c : Ctx) -> Bool {
  c.raw_header("X-Sol-Fragment") == Some("true")
}

// ============================================================================
// Fragment Response Generation
// ============================================================================

///|
/// Extract outlets from rendered HTML and wrap in templates
/// This function takes the full page HTML and extracts elements
/// with data-sol-outlet attributes, wrapping each in a template.
pub fn[E] render_fragment_response(
  node : @luna.Node[E, String],
  title : String,
  hydration : Bool,
) -> String {
  // Render the page content
  let body_html = if hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }

  // For now, we wrap the entire content as the "main" outlet
  // In the future, we can parse the HTML to extract specific outlets
  let buf = StringBuilder::new()

  // Main content outlet
  buf.write_string("<template data-sol-outlet=\"main\">")
  buf.write_string(body_html)
  buf.write_string("</template>")

  // Title
  buf.write_string("<template data-sol-title>")
  buf.write_string(escape_html(title))
  buf.write_string("</template>")
  buf.to_string()
}

///|
/// Send fragment response with appropriate headers
pub async fn send_fragment_response(c : Ctx, html : String) -> Unit {
  c.set_header("X-Sol-Fragment-Response", "true")
  c.html(html)
}

// ============================================================================
// Helpers
// ============================================================================

///|
/// Escape HTML entities in title
fn escape_html(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    match ch {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(ch)
    }
  }
  buf.to_string()
}
