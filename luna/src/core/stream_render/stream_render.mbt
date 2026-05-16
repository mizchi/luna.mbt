// Portable Stream SSR - Streaming server-side rendering via callback writer
// No JS dependencies. Works on native, wasm-gc, and JS targets.
// For Web Streams API (ReadableStream), use luna/js/stream_renderer instead.

///|
/// Stream writer callback - receives chunks as they're ready
pub struct StreamWriter((String) -> Unit)

///|
pub fn StreamWriter::from_callback(callback : (String) -> Unit) -> StreamWriter {
  StreamWriter(callback)
}

// =============================================================================
// Core Stream Rendering
// =============================================================================

///|
/// Render a node to a stream, calling writer for each chunk
pub fn render_to_stream(
  node : @luna.Node[Unit, String],
  writer : StreamWriter,
) -> Unit {
  let island_ids = new_island_id_allocator()
  render_node_to_stream(node, writer, island_ids)
}

///|
fn render_node_to_stream(
  node : @luna.Node[Unit, String],
  writer : StreamWriter,
  island_ids : IslandIdAllocator,
) -> Unit {
  let write = writer.0
  match node {
    Text(content) => write(@render.escape_html(content))
    DynamicText(getter) => write(@render.escape_html(getter()))
    RawHtml(html) => write(html)
    Fragment(children) =>
      for child in children {
        render_node_to_stream(child, writer, island_ids)
      }
    Element(elem) => {
      let tag = elem.tag
      let sb = StringBuilder::new()
      sb.write_char('<')
      sb.write_string(tag)
      @render.render_attrs_to(sb, elem.attrs)
      if @render.is_void_element(tag) {
        sb.write_string(" />")
        write(sb.to_string())
      } else {
        sb.write_char('>')
        write(sb.to_string())
        for child in elem.children {
          render_node_to_stream(child, writer, island_ids)
        }
        write("</" + tag + ">")
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_node_to_stream(child(), writer, island_ids)
      } else {
        write("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_node_to_stream(item, writer, island_ids)
      }
    Component(render~) => render_node_to_stream(render(), writer, island_ids)
    WcIsland(wc_island) =>
      render_wc_island_to_stream(wc_island, writer, island_ids)
    InternalRef(iref) => render_internal_ref_to_stream(iref, writer, island_ids)
    Async(async_node) =>
      render_node_to_stream((async_node.fallback)(), writer, island_ids)
    ErrorBoundary(boundary) =>
      render_node_to_stream((boundary.children)(), writer, island_ids) catch {
        err => {
          let reset = fn() { () }
          render_node_to_stream(
            (boundary.fallback)(err, reset),
            writer,
            island_ids,
          ) catch {
            _ => ()
          }
        }
      }
    Switch(switch_node) => {
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_node_to_stream((case_.render)(), writer, island_ids)
          return
        }
      }
      match switch_node.fallback {
        Some(fallback_fn) =>
          render_node_to_stream(fallback_fn(), writer, island_ids)
        None => write("<!--switch-->")
      }
    }
  }
}

// =============================================================================
// Island Rendering
// =============================================================================

///|
fn render_wc_island_to_stream(
  wc_island : @luna.VWcIsland[Unit, String],
  writer : StreamWriter,
  island_ids : IslandIdAllocator,
) -> Unit {
  let write = writer.0
  let sb = StringBuilder::new()
  sb.write_char('<')
  sb.write_string(wc_island.name)
  sb.write_string(" data-state=\"")
  @render.escape_attr_to(sb, wc_island.state)
  sb.write_char('"')
  if !(wc_island.trigger is Load) {
    sb.write_string(" data-trigger=\"")
    sb.write_string(wc_island.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  if wc_island.styles.length() > 0 {
    sb.write_string("<style>")
    sb.write_string(wc_island.styles)
    sb.write_string("</style>")
  }
  write(sb.to_string())
  for child in wc_island.children {
    render_node_to_stream(child, writer, island_ids)
  }
  write("</template></" + wc_island.name + ">")
}

///|
fn render_internal_ref_to_stream(
  iref : @luna.VInternalRef[Unit, String],
  writer : StreamWriter,
  island_ids : IslandIdAllocator,
) -> Unit {
  let write = writer.0
  let name = extract_wc_name_from_url(iref.url)
  let sb = StringBuilder::new()
  sb.write_char('<')
  sb.write_string(name)
  sb.write_string(" luna:wc-url=\"")
  @render.escape_attr_to(sb, iref.url)
  sb.write_char('"')
  sb.write_string(" luna:wc-state=\"")
  @render.escape_attr_to(sb, iref.state)
  sb.write_char('"')
  if !(iref.trigger is @core.Load) {
    sb.write_string(" luna:wc-trigger=\"")
    sb.write_string(iref.trigger.to_string())
    sb.write_char('"')
  }
  sb.write_char('>')
  sb.write_string("<template shadowrootmode=\"open\">")
  if iref.styles.length() > 0 {
    sb.write_string("<style>")
    sb.write_string(iref.styles)
    sb.write_string("</style>")
  }
  write(sb.to_string())
  for child in iref.children {
    render_node_to_stream(child, writer, island_ids)
  }
  write("</template></" + name + ">")
}

// =============================================================================
// Async Streaming Support
// =============================================================================

///|
pub(all) struct AsyncBoundary {
  id : Int
  async_node : @luna.VAsync[Unit, String]
}

///|
/// Render to stream collecting async boundaries for deferred resolution
pub fn render_to_stream_collecting_async(
  node : @luna.Node[Unit, String],
  writer : StreamWriter,
) -> Array[AsyncBoundary] {
  let island_ids = new_island_id_allocator()
  render_to_stream_collecting_async_with_ids(node, writer, island_ids)
}

///|
fn render_to_stream_collecting_async_with_ids(
  node : @luna.Node[Unit, String],
  writer : StreamWriter,
  island_ids : IslandIdAllocator,
) -> Array[AsyncBoundary] {
  let boundaries : Array[AsyncBoundary] = []
  let id_counter : Ref[Int] = Ref(0)
  render_node_collecting_async(node, writer, boundaries, id_counter, island_ids)
  boundaries
}

///|
fn render_node_collecting_async(
  node : @luna.Node[Unit, String],
  writer : StreamWriter,
  boundaries : Array[AsyncBoundary],
  id_counter : Ref[Int],
  island_ids : IslandIdAllocator,
) -> Unit {
  let write = writer.0
  match node {
    Text(content) => write(@render.escape_html(content))
    DynamicText(getter) => write(@render.escape_html(getter()))
    RawHtml(html) => write(html)
    Fragment(children) =>
      for child in children {
        render_node_collecting_async(
          child, writer, boundaries, id_counter, island_ids,
        )
      }
    Element(elem) => {
      let tag = elem.tag
      let sb = StringBuilder::new()
      sb.write_char('<')
      sb.write_string(tag)
      @render.render_attrs_to(sb, elem.attrs)
      if @render.is_void_element(tag) {
        sb.write_string(" />")
        write(sb.to_string())
      } else {
        sb.write_char('>')
        write(sb.to_string())
        for child in elem.children {
          render_node_collecting_async(
            child, writer, boundaries, id_counter, island_ids,
          )
        }
        write("</" + tag + ">")
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_node_collecting_async(
          child(),
          writer,
          boundaries,
          id_counter,
          island_ids,
        )
      } else {
        write("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_node_collecting_async(
          item, writer, boundaries, id_counter, island_ids,
        )
      }
    Component(render~) =>
      render_node_collecting_async(
        render(),
        writer,
        boundaries,
        id_counter,
        island_ids,
      )
    WcIsland(wc_island) =>
      render_wc_island_to_stream(wc_island, writer, island_ids)
    InternalRef(iref) => render_internal_ref_to_stream(iref, writer, island_ids)
    Async(async_node) => {
      let id = id_counter.val
      id_counter.val = id + 1
      write("<div id=\"A:")
      write(id.to_string())
      write("\">")
      render_node_collecting_async(
        (async_node.fallback)(),
        writer,
        boundaries,
        id_counter,
        island_ids,
      )
      write("</div>")
      boundaries.push({ id, async_node })
    }
    ErrorBoundary(boundary) =>
      render_node_collecting_async(
        (boundary.children)(),
        writer,
        boundaries,
        id_counter,
        island_ids,
      ) catch {
        err => {
          let reset = fn() { () }
          render_node_collecting_async(
            (boundary.fallback)(err, reset),
            writer,
            boundaries,
            id_counter,
            island_ids,
          ) catch {
            _ => ()
          }
        }
      }
    Switch(switch_node) => {
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_node_collecting_async(
            (case_.render)(),
            writer,
            boundaries,
            id_counter,
            island_ids,
          )
          return
        }
      }
      match switch_node.fallback {
        Some(fallback_fn) =>
          render_node_collecting_async(
            fallback_fn(),
            writer,
            boundaries,
            id_counter,
            island_ids,
          )
        None => write("<!--switch-->")
      }
    }
  }
}

///|
/// Stream resolved async content using template element
pub fn stream_async_replacement(
  id : Int,
  writer : StreamWriter,
  render_content : (StreamWriter) -> Unit,
) -> Unit {
  let write = writer.0
  let id_str = id.to_string()
  write("<template id=\"T:")
  write(id_str)
  write("\">")
  render_content(writer)
  write("</template>")
  write("<script>")
  write("(function(){var t=document.getElementById('T:")
  write(id_str)
  write("'),p=document.getElementById('A:")
  write(id_str)
  write("');if(t&&p){p.replaceWith(t.content);t.remove();}})()")
  write("</script>")
}

///|
/// Render to stream with async resolution
pub async fn render_to_stream_with_async(
  node : @luna.Node[Unit, String],
  writer : StreamWriter,
) -> Unit {
  let island_ids = new_island_id_allocator()
  let boundaries = render_to_stream_collecting_async_with_ids(
    node, writer, island_ids,
  )
  for boundary in boundaries {
    try {
      let content = (boundary.async_node.render)()
      stream_async_replacement(boundary.id, writer, fn(w) {
        render_node_to_stream(content, w, island_ids)
      })
    } catch {
      err => {
        let error_content = match boundary.async_node.on_error {
          Some(handler) => handler(err)
          None => (boundary.async_node.fallback)()
        }
        stream_async_replacement(boundary.id, writer, fn(w) {
          render_node_to_stream(error_content, w, island_ids)
        })
      }
    }
  }
}

// =============================================================================
// Utilities
// =============================================================================

///|
fn extract_wc_name_from_url(url : String) -> String {
  let parts = url.split("/").collect()
  let filename_view = if parts.length() > 0 {
    parts[parts.length() - 1]
  } else {
    "".view()
  }
  let filename = filename_view.to_owned()
  let name = if filename.has_suffix(".js") && filename.length() > 3 {
    filename[:filename.length() - 3].to_owned()
  } else {
    filename
  }
  name.replace(old="_", new="-")
}

///|
/// Placeholder allocator threaded through stream renderer. Kept opaque so
/// future id-allocation work can land without resigning every helper.
priv struct IslandIdAllocator {}

///|
fn new_island_id_allocator() -> IslandIdAllocator {
  IslandIdAllocator::{  }
}

