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
pub fn[E, A : Show] render_to_string(
  node : @core.Node[E, A],
  preload? : Bool = false,
) -> SSRResult {
  let sb = StringBuilder::new(size_hint=256)
  if preload {
    let urls : Array[String] = []
    let seen : Map[String, Bool] = {}
    let island_ids = new_island_id_allocator()
    render_and_collect_urls(sb, node, urls, seen, island_ids)
    { html: sb.to_string(), preload_urls: urls }
  } else {
    let island_ids = new_island_id_allocator()
    render_to_sb(sb, node, island_ids)
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
    escape_attr_to(sb, url)
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
  let mut in_string : Char? = None
  let mut escaped = false
  for c in css {
    match in_string {
      Some(quote) => {
        sb.write_char(c)
        prev_char = c
        if escaped {
          escaped = false
        } else if c == '\\' {
          escaped = true
        } else if c == quote {
          in_string = None
        }
      }
      None =>
        match c {
          '"' | '\'' => {
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
            in_string = Some(c)
            escaped = false
          }
          '\n' | '\r' | '\t' =>
            // Convert to space, will be handled by space collapsing
            if !in_space {
              in_space = true
            }
          ' ' => if !in_space { in_space = true }
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
fn[E, A : Show] render_and_collect_urls(
  sb : StringBuilder,
  node : @core.Node[E, A],
  urls : Array[String],
  seen : Map[String, Bool],
  island_ids : IslandIdAllocator,
) -> Unit {
  match node {
    Text(content) => escape_html_to(sb, content)
    DynamicText(getter) => escape_html_to(sb, getter())
    RawHtml(html) => sb.write_string(html)
    Fragment(children) =>
      for child in children {
        render_and_collect_urls(sb, child, urls, seen, island_ids)
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
          render_and_collect_urls(sb, child, urls, seen, island_ids)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_and_collect_urls(sb, child(), urls, seen, island_ids)
      } else {
        sb.write_string("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_and_collect_urls(sb, item, urls, seen, island_ids)
      }
    Component(render~) =>
      render_and_collect_urls(sb, render(), urls, seen, island_ids)
    WcIsland(wc_island) =>
      render_wc_island_and_collect_urls(sb, wc_island, urls, seen, island_ids)
    InternalRef(iref) =>
      render_internal_ref_and_collect_urls(sb, iref, urls, seen, island_ids)
    Async(async_node) =>
      // In sync rendering, render fallback (async content handled by stream renderer)
      render_and_collect_urls(
        sb,
        (async_node.fallback)(),
        urls,
        seen,
        island_ids,
      )
    ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      render_and_collect_urls(sb, (boundary.children)(), urls, seen, island_ids) catch {
        err => {
          // reset function is a no-op in SSR context
          let reset = fn() { () }
          render_and_collect_urls(
            sb,
            (boundary.fallback)(err, reset),
            urls,
            seen,
            island_ids,
          ) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_and_collect_urls(sb, (case_.render)(), urls, seen, island_ids)
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) =>
          render_and_collect_urls(sb, fallback_fn(), urls, seen, island_ids)
        None => sb.write_string("<!--switch-->")
      }
    }
  }
}

///|
/// Placeholder allocator threaded through SSR helpers. Kept opaque so future
/// id-allocation work can land without resigning every helper.
priv struct IslandIdAllocator {}

///|
fn new_island_id_allocator() -> IslandIdAllocator {
  IslandIdAllocator::{  }
}

///|
fn collect_unique_url(
  url : String,
  urls : Array[String],
  seen : Map[String, Bool],
) -> Unit {
  if seen.get(url) is None {
    seen.set(url, true)
    urls.push(url)
  }
}

///|
fn collect_unique_url_if_non_empty(
  url : String,
  urls : Array[String],
  seen : Map[String, Bool],
) -> Unit {
  if url.length() > 0 {
    collect_unique_url(url, urls, seen)
  }
}

///|
/// Write Island wrapper opening (comment + div with attributes)
// ============================================================
// Web Components Island Rendering (Declarative Shadow DOM)
// ============================================================

///|
/// Write WC opening tag with luna:wc-* attributes
fn write_wc_open_tag(
  sb : StringBuilder,
  name : String,
  url : String,
  state : String,
  trigger : @core.TriggerType,
  styles : String,
) -> Unit {
  let trigger_str = trigger.to_string()
  sb.write_char('<')
  sb.write_string(name)
  sb.write_string(" luna:wc-url=\"")
  escape_attr_to(sb, url)
  sb.write_char('"')
  sb.write_string(" luna:wc-state=\"")
  escape_attr_to(sb, state)
  sb.write_char('"')
  if !(trigger is Load) {
    sb.write_string(" luna:wc-trigger=\"")
    escape_attr_to(sb, trigger_str)
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  write_style_tag(sb, styles)
}

///|
/// Write WC closing tag
fn write_wc_close_tag(sb : StringBuilder, name : String) -> Unit {
  sb.write_string("</template></")
  sb.write_string(name)
  sb.write_char('>')
}

///|
/// Render WcIsland node with Declarative Shadow DOM
fn[E, A : Show] render_wc_island_to(
  sb : StringBuilder,
  island : @core.VWcIsland[E, A],
  island_ids : IslandIdAllocator,
) -> Unit {
  write_wc_open_tag(
    sb,
    island.name,
    island.url,
    island.state,
    island.trigger,
    island.styles,
  )
  for child in island.children {
    render_to_sb(sb, child, island_ids)
  }
  write_wc_close_tag(sb, island.name)
}

///|
/// Render WcIsland node and collect URLs (if any)
fn[E, A : Show] render_wc_island_and_collect_urls(
  sb : StringBuilder,
  island : @core.VWcIsland[E, A],
  urls : Array[String],
  seen : Map[String, Bool],
  island_ids : IslandIdAllocator,
) -> Unit {
  collect_unique_url_if_non_empty(island.url, urls, seen)
  write_wc_open_tag(
    sb,
    island.name,
    island.url,
    island.state,
    island.trigger,
    island.styles,
  )
  for child in island.children {
    render_and_collect_urls(sb, child, urls, seen, island_ids)
  }
  write_wc_close_tag(sb, island.name)
}

///|
/// Render WcIsland node with hydration markers
fn[E, A : Show] render_wc_island_with_id_to(
  sb : StringBuilder,
  island : @core.VWcIsland[E, A],
  id_counter : Ref[Int],
  island_ids : IslandIdAllocator,
) -> Unit {
  let id = id_counter.val
  id_counter.val = id + 1
  sb.write_string("<!--wc:")
  sb.write_object(id)
  sb.write_string("-->")
  write_wc_open_tag(
    sb,
    island.name,
    island.url,
    island.state,
    island.trigger,
    island.styles,
  )
  for child in island.children {
    render_with_id_to(sb, child, id_counter, island_ids)
  }
  write_wc_close_tag(sb, island.name)
  sb.write_string("<!--/wc-->")
}

// ============================================================
// InternalRef Rendering (ComponentRef[T] based)
// ============================================================

///|
/// Render InternalRef node as Web Components island
fn[E, A : Show] render_internal_ref_to(
  sb : StringBuilder,
  iref : @core.VInternalRef[E, A],
  island_ids : IslandIdAllocator,
) -> Unit {
  let name = extract_wc_name_from_url(iref.url)
  write_wc_open_tag(sb, name, iref.url, iref.state, iref.trigger, iref.styles)
  for child in iref.children {
    render_to_sb(sb, child, island_ids)
  }
  write_wc_close_tag(sb, name)
}

///|
/// Render InternalRef and collect URLs
fn[E, A : Show] render_internal_ref_and_collect_urls(
  sb : StringBuilder,
  iref : @core.VInternalRef[E, A],
  urls : Array[String],
  seen : Map[String, Bool],
  island_ids : IslandIdAllocator,
) -> Unit {
  collect_unique_url_if_non_empty(iref.url, urls, seen)
  let name = extract_wc_name_from_url(iref.url)
  write_wc_open_tag(sb, name, iref.url, iref.state, iref.trigger, iref.styles)
  for child in iref.children {
    render_and_collect_urls(sb, child, urls, seen, island_ids)
  }
  write_wc_close_tag(sb, name)
}

///|
/// Render InternalRef with hydration markers as Web Components island
fn[E, A : Show] render_internal_ref_with_id_to(
  sb : StringBuilder,
  iref : @core.VInternalRef[E, A],
  id_counter : Ref[Int],
  island_ids : IslandIdAllocator,
) -> Unit {
  let id = id_counter.val
  id_counter.val = id + 1
  let name = extract_wc_name_from_url(iref.url)
  sb.write_string("<!--i:")
  sb.write_object(id)
  sb.write_string("-->")
  write_wc_open_tag(sb, name, iref.url, iref.state, iref.trigger, iref.styles)
  for child in iref.children {
    render_with_id_to(sb, child, id_counter, island_ids)
  }
  write_wc_close_tag(sb, name)
  sb.write_string("<!--/i-->")
}

///|
/// Render attributes to StringBuilder
pub fn[E, A : Show] render_attrs_to(
  sb : StringBuilder,
  attrs : Array[(String, @core.Attr[E, A])],
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      VStatic(s) => render_attr_value(sb, name, s.to_string())
      VDynamic(getter) => render_attr_value(sb, name, getter().to_string())
      VHandler(_) => () // Event handlers are not rendered in SSR
      VAction(action_name) => {
        // Render action as data-action attribute for hydration
        // onclick -> data-action-click="increment"
        let event_name = if name.has_prefix("on") {
          name[2:].to_owned()
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
fn[E, A : Show] render_to_sb(
  sb : StringBuilder,
  node : @core.Node[E, A],
  island_ids : IslandIdAllocator,
) -> Unit {
  match node {
    Text(content) => escape_html_to(sb, content)
    DynamicText(getter) => escape_html_to(sb, getter())
    RawHtml(html) => sb.write_string(html)
    Fragment(children) =>
      for child in children {
        render_to_sb(sb, child, island_ids)
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
          render_to_sb(sb, child, island_ids)
        }
        sb.write_string("</")
        sb.write_string(tag)
        sb.write_char('>')
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_to_sb(sb, child(), island_ids)
      } else {
        sb.write_string("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_to_sb(sb, item, island_ids)
      }
    Component(render~) => render_to_sb(sb, render(), island_ids)
    WcIsland(wc_island) => render_wc_island_to(sb, wc_island, island_ids)
    InternalRef(iref) => render_internal_ref_to(sb, iref, island_ids)
    Async(async_node) =>
      // In sync rendering, render fallback (async content handled by stream renderer)
      render_to_sb(sb, (async_node.fallback)(), island_ids)
    ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      render_to_sb(sb, (boundary.children)(), island_ids) catch {
        err => {
          let reset = fn() { () }
          render_to_sb(sb, (boundary.fallback)(err, reset), island_ids) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_to_sb(sb, (case_.render)(), island_ids)
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) => render_to_sb(sb, fallback_fn(), island_ids)
        None => sb.write_string("<!--switch-->")
      }
    }
  }
}

///|
/// Render with data-ssr-id markers for hydration
pub fn[E, A : Show] render_to_string_with_hydration(
  node : @core.Node[E, A],
) -> String {
  let sb = StringBuilder::new(size_hint=256)
  let id_counter = Ref(0)
  let island_ids = new_island_id_allocator()
  render_with_id_to(sb, node, id_counter, island_ids)
  sb.to_string()
}

///|
/// Internal: Render with hydration markers to StringBuilder
fn[E, A : Show] render_with_id_to(
  sb : StringBuilder,
  node : @core.Node[E, A],
  id_counter : Ref[Int],
  island_ids : IslandIdAllocator,
) -> Unit {
  match node {
    Text(content) => escape_html_to(sb, content)
    RawHtml(html) => sb.write_string(html)
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
        render_with_id_to(sb, child, id_counter, island_ids)
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
          render_with_id_to(sb, child, id_counter, island_ids)
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
        render_with_id_to(sb, child(), id_counter, island_ids)
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
        sb.write_string("<!--fi:")
        sb.write_object(id)
        sb.write_string("-->")
        render_with_id_to(sb, item, id_counter, island_ids)
        sb.write_string("<!--/fi:")
        sb.write_object(id)
        sb.write_string("-->")
      }
      sb.write_string("<!--/f-->")
    }
    Component(render~) =>
      render_with_id_to(sb, render(), id_counter, island_ids)
    WcIsland(wc_island) =>
      render_wc_island_with_id_to(sb, wc_island, id_counter, island_ids)
    InternalRef(iref) =>
      render_internal_ref_with_id_to(sb, iref, id_counter, island_ids)
    Async(async_node) => {
      // Render with async marker for potential hydration
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--a:")
      sb.write_object(id)
      sb.write_string("-->")
      render_with_id_to(sb, (async_node.fallback)(), id_counter, island_ids)
      sb.write_string("<!--/a-->")
    }
    ErrorBoundary(boundary) => {
      // ErrorBoundary with hydration marker
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--eb:")
      sb.write_object(id)
      sb.write_string("-->")
      render_with_id_to(sb, (boundary.children)(), id_counter, island_ids) catch {
        err => {
          let reset = fn() { () }
          render_with_id_to(
            sb,
            (boundary.fallback)(err, reset),
            id_counter,
            island_ids,
          ) catch {
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
          render_with_id_to(sb, (case_.render)(), id_counter, island_ids)
          sb.write_string("<!--/sw-->")
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) =>
          render_with_id_to(sb, fallback_fn(), id_counter, island_ids)
        None => ()
      }
      sb.write_string("<!--/sw-->")
    }
  }
}

///|
/// Check if element has dynamic content that needs hydration
fn[E, A : Show] has_dynamic_content(
  attrs : Array[(String, @core.Attr[E, A])],
) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VAction(_) => return true
      _ => ()
    }
  }
  false
}
