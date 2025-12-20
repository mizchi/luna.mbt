// SSR - Server-Side Rendering for VNode
// Pure MoonBit - works on all targets (js, wasm-gc, native)
//

///|
/// SSR result with HTML and preload URLs collected from islands
pub struct SSRResult {
  html : String
  preload_urls : Array[String]
}

///|
/// Render a VNode to HTML string
/// - preload: Whether to collect preload URLs from islands (default: false)
pub fn[E] render_to_string(
  node : @luna.Node[E],
  preload? : Bool = false,
) -> SSRResult {
  let sb = StringBuilder::new(size_hint=256)
  if preload {
    let urls : Array[String] = []
    render_and_collect_urls(sb, node, urls)
    { html: sb.to_string(), preload_urls: urls }
  } else {
    render_to_sb(sb, node)
    { html: sb.to_string(), preload_urls: [] }
  }
}

///|
/// Generate modulepreload link tags from collected URLs
pub fn generate_preload_tags(urls : Array[String]) -> String {
  if urls.is_empty() {
    return ""
  }
  let sb = StringBuilder::new(size_hint=64 * urls.length())
  for url in urls {
    sb.write_string("  <link rel=\"modulepreload\" href=\"")
    sb.write_string(url)
    sb.write_string("\">\n")
  }
  sb.to_string()
}

///|
/// Minify CSS by removing unnecessary whitespace and newlines
/// - Removes newlines
/// - Collapses multiple spaces to one
/// - Removes spaces around { } : ; ,
fn minify_css(css : String) -> String {
  let sb = StringBuilder::new(size_hint=css.length())
  let mut prev_char : Char = ' '
  let mut in_space = false
  for c in css {
    match c {
      '\n' | '\r' | '\t' =>
        // Convert to space, will be handled by space collapsing
        if not(in_space) {
          in_space = true
        }
      ' ' => if not(in_space) { in_space = true }
      '{' | '}' | ':' | ';' | ',' => {
        // Remove space before these characters
        in_space = false
        sb.write_char(c)
        prev_char = c
      }
      _ => {
        // Add single space if we had spaces and prev char doesn't make it unnecessary
        if in_space &&
          prev_char != '{' &&
          prev_char != '}' &&
          prev_char != ':' &&
          prev_char != ';' &&
          prev_char != ',' &&
          prev_char != ' ' {
          sb.write_char(' ')
        }
        in_space = false
        sb.write_char(c)
        prev_char = c
      }
    }
  }
  sb.to_string()
}

///|
/// Simple hash function for CSS string (for dedup ID)
/// Uses same algorithm as use_style() in DOM module for consistency
fn hash_css(css : String) -> String {
  let mut hash : UInt = 5381
  for c in css {
    hash = (hash << 5) + hash + c.to_uint()
  }
  hash.to_string()
}

///|
/// Write style tag with hash ID for deduplication
/// CSS is minified before output. Hash is computed from minified CSS.
fn write_style_tag(sb : StringBuilder, styles : String) -> Unit {
  if styles.length() > 0 {
    let minified = minify_css(styles)
    let hash = hash_css(minified)
    sb.write_string("<style id=\"style-")
    sb.write_string(hash)
    sb.write_string("\">")
    sb.write_string(minified)
    sb.write_string("</style>")
  }
}

///|
/// Render a VNode to StringBuilder and collect island URLs
fn[E] render_and_collect_urls(
  sb : StringBuilder,
  node : @luna.Node[E],
  urls : Array[String],
) -> Unit {
  match node {
    Text(content) => escape_html_to(sb, content)
    DynamicText(getter) => escape_html_to(sb, getter())
    Fragment(children) =>
      for child in children {
        render_and_collect_urls(sb, child, urls)
      }
    Element(elem) => {
      let tag = elem.tag
      sb.write_char('<')
      sb.write_string(tag)
      render_attrs_to(sb, elem.attrs)
      if is_void_element(tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        for child in elem.children {
          render_and_collect_urls(sb, child, urls)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_and_collect_urls(sb, child(), urls)
      } else {
        sb.write_string("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_and_collect_urls(sb, item, urls)
      }
    Component(render~) => render_and_collect_urls(sb, render(), urls)
    Island(island) => render_island_and_collect_urls(sb, island, urls)
    WcIsland(wc_island) =>
      render_wc_island_and_collect_urls(sb, wc_island, urls)
    InternalRef(iref) => render_internal_ref_and_collect_urls(sb, iref, urls)
    Async(async_node) =>
      // In sync rendering, render fallback (async content handled by stream renderer)
      render_and_collect_urls(sb, (async_node.fallback)(), urls)
    ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      render_and_collect_urls(sb, (boundary.children)(), urls) catch {
        err => {
          // reset function is a no-op in SSR context
          let reset = fn() { () }
          render_and_collect_urls(sb, (boundary.fallback)(err, reset), urls) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_and_collect_urls(sb, (case_.render)(), urls)
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) => render_and_collect_urls(sb, fallback_fn(), urls)
        None => sb.write_string("<!--switch-->")
      }
    }
  }
}

///|
/// Render Island node and collect its URL
fn[E] render_island_and_collect_urls(
  sb : StringBuilder,
  island : @luna.VIsland[E],
  urls : Array[String],
) -> Unit {
  // Collect URL if not already present
  if not(urls.contains(island.url)) {
    urls.push(island.url)
  }
  render_island_open_to(sb, island)
  for child in island.children {
    render_and_collect_urls(sb, child, urls)
  }
  render_island_close_to(sb, island)
}

///|
/// Render Island wrapper opening (comment + div with attributes)
fn[E] render_island_open_to(
  sb : StringBuilder,
  island : @luna.VIsland[E],
) -> Unit {
  sb.write_string("<!--luna:island:")
  sb.write_string(island.id)
  sb.write_string(" url=")
  sb.write_string(island.url)
  sb.write_string(" trigger=")
  sb.write_string(island.trigger.to_string())
  sb.write_string("-->")
  sb.write_string("<div luna:id=\"")
  sb.write_string(island.id)
  sb.write_string("\" luna:url=\"")
  sb.write_string(island.url)
  sb.write_string("\" luna:state=\"")
  escape_attr_to(sb, island.state)
  sb.write_string("\" luna:client-trigger=\"")
  sb.write_string(island.trigger.to_string())
  sb.write_string("\">")
}

///|
/// Render Island wrapper closing (div + comment)
fn[E] render_island_close_to(
  sb : StringBuilder,
  island : @luna.VIsland[E],
) -> Unit {
  sb.write_string("</div>")
  sb.write_string("<!--/luna:island:")
  sb.write_string(island.id)
  sb.write_string("-->")
}

// ============================================================
// Web Components Island Rendering (Declarative Shadow DOM)
// ============================================================

///|
/// Render WcIsland node with Declarative Shadow DOM
fn[E] render_wc_island_to(
  sb : StringBuilder,
  island : @luna.VWcIsland[E],
) -> Unit {
  // <wc-counter luna:wc-url="..." luna:wc-state="..." luna:wc-trigger="load">
  sb.write_char('<')
  sb.write_string(island.name)

  // Hydration script URL
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, island.url)
  sb.write_char('"')

  // State JSON
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, island.state)
  sb.write_char('"')

  // Only add trigger attribute if not default (load)
  if not(island.trigger is Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(island.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')

  // <template shadowrootmode="open">
  sb.write_string("<template shadowrootmode=\"open\">")

  // <style id="style-{hash}">...</style>
  write_style_tag(sb, island.styles)

  // Render children
  for child in island.children {
    render_to_sb(sb, child)
  }

  // Close template and custom element
  sb.write_string("</template></")
  sb.write_string(island.name)
  sb.write_char('>')
}

///|
/// Render WcIsland node and collect URLs (if any)
fn[E] render_wc_island_and_collect_urls(
  sb : StringBuilder,
  island : @luna.VWcIsland[E],
  urls : Array[String],
) -> Unit {
  // Collect URL if not already present
  if island.url.length() > 0 && not(urls.contains(island.url)) {
    urls.push(island.url)
  }

  // <wc-counter luna:wc-url="..." luna:wc-state="..." luna:wc-trigger="load">
  sb.write_char('<')
  sb.write_string(island.name)

  // Hydration script URL
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, island.url)
  sb.write_char('"')

  // State JSON
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, island.state)
  sb.write_char('"')
  if not(island.trigger is Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(island.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  write_style_tag(sb, island.styles)
  for child in island.children {
    render_and_collect_urls(sb, child, urls)
  }
  sb.write_string("</template></")
  sb.write_string(island.name)
  sb.write_char('>')
}

///|
/// Render WcIsland node with hydration markers
fn[E] render_wc_island_with_id_to(
  sb : StringBuilder,
  island : @luna.VWcIsland[E],
  id_counter : Ref[Int],
) -> Unit {
  let id = id_counter.val
  id_counter.val = id + 1

  // WcIsland comment marker for hydration
  sb.write_string("<!--wc:")
  sb.write_object(id)
  sb.write_string("-->")
  sb.write_char('<')
  sb.write_string(island.name)

  // Hydration script URL
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, island.url)
  sb.write_char('"')

  // State JSON
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, island.state)
  sb.write_char('"')
  if not(island.trigger is Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(island.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  write_style_tag(sb, island.styles)
  for child in island.children {
    render_with_id_to(sb, child, id_counter)
  }
  sb.write_string("</template></")
  sb.write_string(island.name)
  sb.write_char('>')
  sb.write_string("<!--/wc-->")
}

// ============================================================
// InternalRef Rendering (ComponentRef[T] based)
// ============================================================

///|
/// Render InternalRef node (dispatches to Island or WcIsland based on wc flag)
fn[E] render_internal_ref_to(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
) -> Unit {
  if iref.wc {
    render_internal_ref_wc_to(sb, iref)
  } else {
    render_internal_ref_island_to(sb, iref)
  }
}

///|
/// Render InternalRef as regular Island
fn[E] render_internal_ref_island_to(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
) -> Unit {
  // Generate a unique ID from URL (simplified - in real usage, generate proper ID)
  let id = iref.url.replace(old="/", new="_").replace(old=".", new="_")
  sb.write_string("<!--luna:island:")
  sb.write_string(id)
  sb.write_string(" url=")
  sb.write_string(iref.url)
  sb.write_string(" trigger=")
  sb.write_string(iref.trigger.to_string())
  sb.write_string("-->")
  sb.write_string("<div luna:id=\"")
  sb.write_string(id)
  sb.write_string("\" luna:url=\"")
  sb.write_string(iref.url)
  sb.write_string("\" luna:state=\"")
  escape_attr_to(sb, iref.state)
  sb.write_string("\" luna:client-trigger=\"")
  sb.write_string(iref.trigger.to_string())
  sb.write_string("\">")
  for child in iref.children {
    render_to_sb(sb, child)
  }
  sb.write_string("</div>")
  sb.write_string("<!--/luna:island:")
  sb.write_string(id)
  sb.write_string("-->")
}

///|
/// Render InternalRef as WcIsland (Web Components)
fn[E] render_internal_ref_wc_to(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
) -> Unit {
  // Extract custom element name from URL (e.g., /static/wc_counter.js -> wc-counter)
  let name = @utils.extract_wc_name_from_url(iref.url)
  sb.write_char('<')
  sb.write_string(name)
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, iref.url)
  sb.write_char('"')
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, iref.state)
  sb.write_char('"')
  if not(iref.trigger is @luna.Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(iref.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  write_style_tag(sb, iref.styles)
  for child in iref.children {
    render_to_sb(sb, child)
  }
  sb.write_string("</template></")
  sb.write_string(name)
  sb.write_char('>')
}

///|
/// Render InternalRef and collect URLs
fn[E] render_internal_ref_and_collect_urls(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
  urls : Array[String],
) -> Unit {
  // Collect URL if not already present
  if iref.url.length() > 0 && not(urls.contains(iref.url)) {
    urls.push(iref.url)
  }
  if iref.wc {
    render_internal_ref_wc_and_collect_urls(sb, iref, urls)
  } else {
    render_internal_ref_island_and_collect_urls(sb, iref, urls)
  }
}

///|
/// Render InternalRef as Island and collect URLs
fn[E] render_internal_ref_island_and_collect_urls(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
  urls : Array[String],
) -> Unit {
  let id = iref.url.replace(old="/", new="_").replace(old=".", new="_")
  sb.write_string("<!--luna:island:")
  sb.write_string(id)
  sb.write_string(" url=")
  sb.write_string(iref.url)
  sb.write_string(" trigger=")
  sb.write_string(iref.trigger.to_string())
  sb.write_string("-->")
  sb.write_string("<div luna:id=\"")
  sb.write_string(id)
  sb.write_string("\" luna:url=\"")
  sb.write_string(iref.url)
  sb.write_string("\" luna:state=\"")
  escape_attr_to(sb, iref.state)
  sb.write_string("\" luna:client-trigger=\"")
  sb.write_string(iref.trigger.to_string())
  sb.write_string("\">")
  for child in iref.children {
    render_and_collect_urls(sb, child, urls)
  }
  sb.write_string("</div>")
  sb.write_string("<!--/luna:island:")
  sb.write_string(id)
  sb.write_string("-->")
}

///|
/// Render InternalRef as WcIsland and collect URLs
fn[E] render_internal_ref_wc_and_collect_urls(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
  urls : Array[String],
) -> Unit {
  let name = @utils.extract_wc_name_from_url(iref.url)
  sb.write_char('<')
  sb.write_string(name)
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, iref.url)
  sb.write_char('"')
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, iref.state)
  sb.write_char('"')
  if not(iref.trigger is @luna.Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(iref.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  write_style_tag(sb, iref.styles)
  for child in iref.children {
    render_and_collect_urls(sb, child, urls)
  }
  sb.write_string("</template></")
  sb.write_string(name)
  sb.write_char('>')
}

///|
/// Render InternalRef with hydration markers
fn[E] render_internal_ref_with_id_to(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
  id_counter : Ref[Int],
) -> Unit {
  if iref.wc {
    render_internal_ref_wc_with_id_to(sb, iref, id_counter)
  } else {
    render_internal_ref_island_with_id_to(sb, iref, id_counter)
  }
}

///|
/// Render InternalRef as Island with hydration markers
fn[E] render_internal_ref_island_with_id_to(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
  id_counter : Ref[Int],
) -> Unit {
  let id = id_counter.val
  id_counter.val = id + 1
  let island_id = iref.url.replace(old="/", new="_").replace(old=".", new="_")
  sb.write_string("<!--i:")
  sb.write_object(id)
  sb.write_string("-->")
  sb.write_string("<!--luna:island:")
  sb.write_string(island_id)
  sb.write_string(" url=")
  sb.write_string(iref.url)
  sb.write_string(" trigger=")
  sb.write_string(iref.trigger.to_string())
  sb.write_string("-->")
  sb.write_string("<div luna:id=\"")
  sb.write_string(island_id)
  sb.write_string("\" luna:url=\"")
  sb.write_string(iref.url)
  sb.write_string("\" luna:state=\"")
  escape_attr_to(sb, iref.state)
  sb.write_string("\" luna:client-trigger=\"")
  sb.write_string(iref.trigger.to_string())
  sb.write_string("\">")
  for child in iref.children {
    render_with_id_to(sb, child, id_counter)
  }
  sb.write_string("</div>")
  sb.write_string("<!--/luna:island:")
  sb.write_string(island_id)
  sb.write_string("-->")
  sb.write_string("<!--/i-->")
}

///|
/// Render InternalRef as WcIsland with hydration markers
fn[E] render_internal_ref_wc_with_id_to(
  sb : StringBuilder,
  iref : @luna.VInternalRef[E],
  id_counter : Ref[Int],
) -> Unit {
  let id = id_counter.val
  id_counter.val = id + 1
  let name = @utils.extract_wc_name_from_url(iref.url)
  sb.write_string("<!--wc:")
  sb.write_object(id)
  sb.write_string("-->")
  sb.write_char('<')
  sb.write_string(name)
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, iref.url)
  sb.write_char('"')
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, iref.state)
  sb.write_char('"')
  if not(iref.trigger is @luna.Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(iref.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  write_style_tag(sb, iref.styles)
  for child in iref.children {
    render_with_id_to(sb, child, id_counter)
  }
  sb.write_string("</template></")
  sb.write_string(name)
  sb.write_char('>')
  sb.write_string("<!--/wc-->")
}

///|
/// Render attributes to StringBuilder
pub fn[E] render_attrs_to(
  sb : StringBuilder,
  attrs : Array[(String, @luna.Attr[E])],
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      VStatic(s) => render_attr_value(sb, name, s)
      VDynamic(getter) => render_attr_value(sb, name, getter())
      VHandler(_) => () // Event handlers are not rendered in SSR
      VAction(action_name) => {
        // Render action as data-action attribute for hydration
        // onclick -> data-action-click="increment"
        let event_name = if name.has_prefix("on") {
          name[2:].to_string() catch {
            _ => name
          }
        } else {
          name
        }
        sb.write_string(" data-action-")
        sb.write_string(event_name)
        sb.write_string("=\"")
        escape_attr_to(sb, action_name)
        sb.write_char('"')
      }
    }
  }
}

///|
/// Render a single attribute value
pub fn render_attr_value(sb : StringBuilder, name : String, s : String) -> Unit {
  match s {
    "__remove__" => () // Special marker to skip attribute
    "" => {
      // Boolean attribute (like disabled)
      sb.write_char(' ')
      sb.write_string(name)
    }
    _ => {
      sb.write_char(' ')
      sb.write_string(name)
      sb.write_string("=\"")
      escape_attr_to(sb, s)
      sb.write_char('"')
    }
  }
}

///|
/// Render a VNode to StringBuilder
fn[E] render_to_sb(sb : StringBuilder, node : @luna.Node[E]) -> Unit {
  match node {
    Text(content) => escape_html_to(sb, content)
    DynamicText(getter) => escape_html_to(sb, getter())
    Fragment(children) =>
      for child in children {
        render_to_sb(sb, child)
      }
    Element(elem) => {
      let tag = elem.tag
      sb.write_char('<')
      sb.write_string(tag)
      render_attrs_to(sb, elem.attrs)
      if is_void_element(tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        for child in elem.children {
          render_to_sb(sb, child)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_to_sb(sb, child())
      } else {
        sb.write_string("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_to_sb(sb, item)
      }
    Component(render~) => render_to_sb(sb, render())
    Island(island) => render_island_to(sb, island)
    WcIsland(wc_island) => render_wc_island_to(sb, wc_island)
    InternalRef(iref) => render_internal_ref_to(sb, iref)
    Async(async_node) =>
      // In sync rendering, render fallback (async content handled by stream renderer)
      render_to_sb(sb, (async_node.fallback)())
    ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      render_to_sb(sb, (boundary.children)()) catch {
        err => {
          let reset = fn() { () }
          render_to_sb(sb, (boundary.fallback)(err, reset)) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_to_sb(sb, (case_.render)())
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) => render_to_sb(sb, fallback_fn())
        None => sb.write_string("<!--switch-->")
      }
    }
  }
}

///|
/// Render Island node with luna:* attributes for hydration
fn[E] render_island_to(sb : StringBuilder, island : @luna.VIsland[E]) -> Unit {
  render_island_open_to(sb, island)
  for child in island.children {
    render_to_sb(sb, child)
  }
  render_island_close_to(sb, island)
}

///|
/// Render with data-ssr-id markers for hydration
pub fn[E] render_to_string_with_hydration(node : @luna.Node[E]) -> String {
  let sb = StringBuilder::new(size_hint=256)
  let id_counter = { val: 0 }
  render_with_id_to(sb, node, id_counter)
  sb.to_string()
}

///|
/// Internal: Render with hydration markers to StringBuilder
fn[E] render_with_id_to(
  sb : StringBuilder,
  node : @luna.Node[E],
  id_counter : Ref[Int],
) -> Unit {
  match node {
    Text(content) => escape_html_to(sb, content)
    DynamicText(getter) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--t:")
      sb.write_object(id)
      sb.write_string("-->")
      escape_html_to(sb, getter())
      sb.write_string("<!--/t-->")
    }
    Fragment(children) =>
      for child in children {
        render_with_id_to(sb, child, id_counter)
      }
    Element(elem) => {
      let tag = elem.tag
      let id = id_counter.val
      id_counter.val = id + 1

      // Check if element has dynamic attributes or handlers
      let needs_hydration = has_dynamic_content(elem.attrs)
      sb.write_char('<')
      sb.write_string(tag)
      render_attrs_to(sb, elem.attrs)
      if needs_hydration {
        sb.write_string(" sol:hk=\"")
        sb.write_object(id)
        sb.write_char('"')
      }
      if is_void_element(tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        for child in elem.children {
          render_with_id_to(sb, child, id_counter)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    Show(condition~, child~) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--s:")
      sb.write_object(id)
      sb.write_string("-->")
      if condition() {
        render_with_id_to(sb, child(), id_counter)
      }
      sb.write_string("<!--/s-->")
    }
    For(render~) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--f:")
      sb.write_object(id)
      sb.write_string("-->")
      for item in render() {
        render_with_id_to(sb, item, id_counter)
      }
      sb.write_string("<!--/f-->")
    }
    Component(render~) => render_with_id_to(sb, render(), id_counter)
    Island(island) => render_island_with_id_to(sb, island, id_counter)
    WcIsland(wc_island) =>
      render_wc_island_with_id_to(sb, wc_island, id_counter)
    InternalRef(iref) => render_internal_ref_with_id_to(sb, iref, id_counter)
    Async(async_node) => {
      // Render with async marker for potential hydration
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--a:")
      sb.write_object(id)
      sb.write_string("-->")
      render_with_id_to(sb, (async_node.fallback)(), id_counter)
      sb.write_string("<!--/a-->")
    }
    ErrorBoundary(boundary) => {
      // ErrorBoundary with hydration marker
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--eb:")
      sb.write_object(id)
      sb.write_string("-->")
      render_with_id_to(sb, (boundary.children)(), id_counter) catch {
        err => {
          let reset = fn() { () }
          render_with_id_to(sb, (boundary.fallback)(err, reset), id_counter) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
      sb.write_string("<!--/eb-->")
    }
    Switch(switch_node) => {
      // Switch with hydration marker
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--sw:")
      sb.write_object(id)
      sb.write_string("-->")
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_with_id_to(sb, (case_.render)(), id_counter)
          sb.write_string("<!--/sw-->")
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) => render_with_id_to(sb, fallback_fn(), id_counter)
        None => ()
      }
      sb.write_string("<!--/sw-->")
    }
  }
}

///|
/// Render Island node with luna:* attributes and hydration markers
fn[E] render_island_with_id_to(
  sb : StringBuilder,
  island : @luna.VIsland[E],
  id_counter : Ref[Int],
) -> Unit {
  render_island_open_to(sb, island)
  for child in island.children {
    render_with_id_to(sb, child, id_counter)
  }
  render_island_close_to(sb, island)
}

///|
/// Check if element has dynamic content that needs hydration
fn[E] has_dynamic_content(attrs : Array[(String, @luna.Attr[E])]) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VAction(_) => return true
      _ => ()
    }
  }
  false
}
