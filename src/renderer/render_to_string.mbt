///| SSR - Server-Side Rendering for VNode

///| Pure MoonBit implementation with no external dependencies

///| Uses shared escape utilities from escape.mbt

///|
/// Render a VNode to HTML string
pub fn[E] render_to_string(node : @luna.Node[E]) -> String {
  let sb = StringBuilder::new(size_hint=256)
  render_to_sb(sb, node)
  sb.to_string()
}

///|
/// SSR result with preload URLs collected from islands
pub struct SSRResult {
  html : String
  preload_urls : Array[String]
}

///|
/// Render a VNode to HTML string and collect preload URLs from islands
pub fn[E] render_with_preloads(node : @luna.Node[E]) -> SSRResult {
  render_with_options(node)
}

///|
/// Render a VNode to HTML string with options
/// - preload: Whether to collect preload URLs from islands (default: true)
/// - hydration: Whether to include hydration markers (default: true, reserved for future use)
pub fn[E] render_with_options(
  node : @luna.Node[E],
  preload? : Bool = true,
  hydration? : Bool = true,
) -> SSRResult {
  let _ = hydration // Reserved for future use
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
    Show(condition=cond, child=child_fn) =>
      if cond() {
        render_and_collect_urls(sb, child_fn(), urls)
      } else {
        sb.write_string("<!--show-->")
      }
    For(render=render_fn) =>
      for item in render_fn() {
        render_and_collect_urls(sb, item, urls)
      }
    Component(render=render_fn) =>
      render_and_collect_urls(sb, render_fn(), urls)
    Island(island) => render_island_and_collect_urls(sb, island, urls)
    Async(async_node) =>
      // In sync rendering, render fallback (async content handled by stream renderer)
      render_and_collect_urls(sb, (async_node.fallback)(), urls)
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

// Note: is_void_element, escape_html_to, escape_attr_to are defined in escape.mbt

///|
/// Render Island wrapper opening (comment + div with attributes)
fn[E] render_island_open_to(sb : StringBuilder, island : @luna.VIsland[E]) -> Unit {
  sb.write_string("<!--ln:island:")
  sb.write_string(island.id)
  sb.write_string(" url=")
  sb.write_string(island.url)
  sb.write_string(" trigger=")
  sb.write_string(@luna.trigger_to_string(island.trigger))
  sb.write_string("-->")
  sb.write_string("<div ln:id=\"")
  sb.write_string(island.id)
  sb.write_string("\" ln:url=\"")
  sb.write_string(island.url)
  sb.write_string("\" ln:state=\"")
  escape_attr_to(sb, island.state)
  sb.write_string("\" ln:trigger=\"")
  sb.write_string(@luna.trigger_to_string(island.trigger))
  sb.write_string("\">")
}

///|
/// Render Island wrapper closing (div + comment)
fn[E] render_island_close_to(sb : StringBuilder, island : @luna.VIsland[E]) -> Unit {
  sb.write_string("</div>")
  sb.write_string("<!--/ln:island:")
  sb.write_string(island.id)
  sb.write_string("-->")
}

///|
/// Render attributes to StringBuilder
fn[E] render_attrs_to(
  sb : StringBuilder,
  attrs : Array[(String, @luna.Attr[E])],
) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      VStatic(s) =>
        if s != "__remove__" {
          if s == "" {
            // Boolean attribute (like disabled)
            sb.write_char(' ')
            sb.write_string(name)
          } else {
            sb.write_char(' ')
            sb.write_string(name)
            sb.write_string("=\"")
            escape_attr_to(sb, s)
            sb.write_char('"')
          }
        }
      VDynamic(getter) => {
        let s = getter()
        if s != "__remove__" {
          if s == "" {
            sb.write_char(' ')
            sb.write_string(name)
          } else {
            sb.write_char(' ')
            sb.write_string(name)
            sb.write_string("=\"")
            escape_attr_to(sb, s)
            sb.write_char('"')
          }
        }
      }
      VHandler(_) =>
        // Event handlers are not rendered in SSR
        ()
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
    Show(condition=cond, child=child_fn) =>
      if cond() {
        render_to_sb(sb, child_fn())
      } else {
        sb.write_string("<!--show-->")
      }
    For(render=render_fn) =>
      for item in render_fn() {
        render_to_sb(sb, item)
      }
    Component(render=render_fn) => render_to_sb(sb, render_fn())
    Island(island) => render_island_to(sb, island)
    Async(async_node) =>
      // In sync rendering, render fallback (async content handled by stream renderer)
      render_to_sb(sb, (async_node.fallback)())
  }
}

///|
/// Render Island node with ln:* attributes for hydration
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
        sb.write_string(" data-hk=\"")
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
    Show(condition=cond, child=child_fn) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--s:")
      sb.write_object(id)
      sb.write_string("-->")
      if cond() {
        render_with_id_to(sb, child_fn(), id_counter)
      }
      sb.write_string("<!--/s-->")
    }
    For(render=render_fn) => {
      let id = id_counter.val
      id_counter.val = id + 1
      sb.write_string("<!--f:")
      sb.write_object(id)
      sb.write_string("-->")
      for item in render_fn() {
        render_with_id_to(sb, item, id_counter)
      }
      sb.write_string("<!--/f-->")
    }
    Component(render=render_fn) =>
      render_with_id_to(sb, render_fn(), id_counter)
    Island(island) => render_island_with_id_to(sb, island, id_counter)
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
  }
}

///|
/// Render Island node with ln:* attributes and hydration markers
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
