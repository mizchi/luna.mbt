///| Stream SSR - Streaming server-side rendering with Web Streams API

///| Provides chunked HTML output for faster Time-To-First-Byte (TTFB)

///| Uses standard Web Streams API (ReadableStream, WritableStream)

///| VAsync nodes render fallback immediately, then stream resolved content

///|
/// Stream writer callback - receives chunks as they're ready
pub struct StreamWriter((String) -> Unit)

///|
/// Create a StreamWriter from a callback function
pub fn StreamWriter::from_callback(callback : (String) -> Unit) -> StreamWriter {
  StreamWriter(callback)
}

///|
/// Render a node to a stream, calling writer for each chunk
pub fn render_to_stream(node : @luna.Node[Unit], writer : StreamWriter) -> Unit {
  render_node_to_stream(node, writer)
}

///|
fn render_node_to_stream(
  node : @luna.Node[Unit],
  writer : StreamWriter,
) -> Unit {
  let write = writer.0
  match node {
    Text(content) => write(@render.escape_html(content))
    DynamicText(getter) => write(@render.escape_html(getter()))
    Fragment(children) =>
      for child in children {
        render_node_to_stream(child, writer)
      }
    Element(elem) => {
      let tag = elem.tag
      // Open tag
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
        // Children
        for child in elem.children {
          render_node_to_stream(child, writer)
        }
        // Close tag
        write("</" + tag + ">")
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_node_to_stream(child(), writer)
      } else {
        write("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_node_to_stream(item, writer)
      }
    Component(render~) => render_node_to_stream(render(), writer)
    Island(island) => render_island_to_stream(island, writer)
    Async(async_node) =>
      // In stream rendering, render fallback immediately
      // Async resolution happens via Suspense/render_with_suspense
      render_node_to_stream((async_node.fallback)(), writer)
    ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      render_node_to_stream((boundary.children)(), writer) catch {
        err => {
          let reset = fn() { () }
          render_node_to_stream((boundary.fallback)(err, reset), writer) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_node_to_stream((case_.render)(), writer)
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) => render_node_to_stream(fallback_fn(), writer)
        None => write("<!--switch-->")
      }
    }
  }
}

///|
/// Render Island node to stream
fn render_island_to_stream(
  island : @luna.VIsland[Unit],
  writer : StreamWriter,
) -> Unit {
  let write = writer.0
  // Start comment marker
  write(
    "<!--ln:island:" +
    island.id +
    " url=" +
    island.url +
    " trigger=" +
    @luna.trigger_to_string(island.trigger) +
    "-->",
  )
  // Wrapper div with ln:* attributes
  let sb = StringBuilder::new()
  sb.write_string("<div ln:id=\"")
  sb.write_string(island.id)
  sb.write_string("\" ln:url=\"")
  sb.write_string(island.url)
  sb.write_string("\" ln:state=\"")
  @render.escape_attr_to(sb, island.state)
  sb.write_string("\" ln:trigger=\"")
  sb.write_string(@luna.trigger_to_string(island.trigger))
  sb.write_string("\">")
  write(sb.to_string())
  // Render children
  for child in island.children {
    render_node_to_stream(child, writer)
  }
  write("</div>")
  // End comment marker
  write("<!--/ln:island:" + island.id + "-->")
}

///|
/// Create a ReadableStream for HTTP response (Web Streams API)
extern "js" fn js_create_readable_stream(
  start : ((String) -> Unit) -> Unit,
) -> @streams.ReadableStream =
  #| (start) => new ReadableStream({
  #|   start(controller) {
  #|     start((chunk) => {
  #|       controller.enqueue(new TextEncoder().encode(chunk));
  #|     });
  #|   }
  #| })

///|
/// Render to a ReadableStream for streaming HTTP response
pub fn render_to_readable_stream(
  node : @luna.Node[Unit],
) -> @streams.ReadableStream {
  js_create_readable_stream(fn(enqueue) {
    render_to_stream(node, StreamWriter(fn(chunk) { enqueue(chunk) }))
  })
}

// =============================================================================
// Async Streaming Support
// =============================================================================

///|
/// Collected async node for deferred resolution
pub(all) struct AsyncBoundary {
  id : Int
  async_node : @luna.VAsync[Unit]
}

///|
/// Render to stream with async boundaries
/// - Renders shell with fallbacks immediately (fast TTFB)
/// - Collects async boundaries for later resolution
/// - Returns boundaries for streaming resolution
pub fn render_to_stream_collecting_async(
  node : @luna.Node[Unit],
  writer : StreamWriter,
) -> Array[AsyncBoundary] {
  let boundaries : Array[AsyncBoundary] = []
  let id_counter : Ref[Int] = Ref::new(0)
  render_node_collecting_async(node, writer, boundaries, id_counter)
  boundaries
}

///|
fn render_node_collecting_async(
  node : @luna.Node[Unit],
  writer : StreamWriter,
  boundaries : Array[AsyncBoundary],
  id_counter : Ref[Int],
) -> Unit {
  let write = writer.0
  match node {
    Text(content) => write(@render.escape_html(content))
    DynamicText(getter) => write(@render.escape_html(getter()))
    Fragment(children) =>
      for child in children {
        render_node_collecting_async(child, writer, boundaries, id_counter)
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
          render_node_collecting_async(child, writer, boundaries, id_counter)
        }
        write("</" + tag + ">")
      }
    }
    Show(condition~, child~) =>
      if condition() {
        render_node_collecting_async(child(), writer, boundaries, id_counter)
      } else {
        write("<!--show-->")
      }
    For(render~) =>
      for item in render() {
        render_node_collecting_async(item, writer, boundaries, id_counter)
      }
    Component(render~) =>
      render_node_collecting_async(render(), writer, boundaries, id_counter)
    Island(island) => render_island_to_stream(island, writer)
    Async(async_node) => {
      let id = id_counter.val
      id_counter.val = id + 1
      // Render placeholder with ID for later replacement
      write("<div id=\"A:")
      write(id.to_string())
      write("\">")
      render_node_collecting_async(
        (async_node.fallback)(),
        writer,
        boundaries,
        id_counter,
      )
      write("</div>")
      // Collect for later resolution
      boundaries.push({ id, async_node })
    }
    ErrorBoundary(boundary) =>
      // ErrorBoundary: try rendering children, catch errors and render fallback
      render_node_collecting_async(
        (boundary.children)(),
        writer,
        boundaries,
        id_counter,
      ) catch {
        err => {
          let reset = fn() { () }
          render_node_collecting_async(
            (boundary.fallback)(err, reset),
            writer,
            boundaries,
            id_counter,
          ) catch {
            _ => () // Ignore errors in fallback
          }
        }
      }
    Switch(switch_node) => {
      // Find first matching case and render it
      for case_ in switch_node.cases {
        if (case_.when)() {
          render_node_collecting_async(
            (case_.render)(),
            writer,
            boundaries,
            id_counter,
          )
          return
        }
      }
      // No case matched, render fallback if present
      match switch_node.fallback {
        Some(fallback_fn) =>
          render_node_collecting_async(
            fallback_fn(),
            writer,
            boundaries,
            id_counter,
          )
        None => write("<!--switch-->")
      }
    }
  }
}

///|
/// Stream resolved async content using template element
/// This approach:
/// 1. Writes HTML directly into <template> (no escaping needed)
/// 2. Uses inline script to replace placeholder
/// 3. Removes template after replacement
pub fn stream_async_replacement(
  id : Int,
  writer : StreamWriter,
  render_content : (StreamWriter) -> Unit,
) -> Unit {
  let write = writer.0
  let id_str = id.to_string()
  // Write template with resolved content
  write("<template id=\"T:")
  write(id_str)
  write("\">")
  render_content(writer)
  write("</template>")
  // Inline replacement script
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
/// 1. Render shell with fallbacks (fast TTFB)
/// 2. Resolve each async boundary and stream replacement using <template>
pub async fn render_to_stream_with_async(
  node : @luna.Node[Unit],
  writer : StreamWriter,
) -> Unit {
  // 1. Render shell collecting async boundaries
  let boundaries = render_to_stream_collecting_async(node, writer)

  // 2. Resolve each async boundary and stream replacement
  for boundary in boundaries {
    try {
      let content = (boundary.async_node.render)()
      stream_async_replacement(boundary.id, writer, fn(w) {
        render_node_to_stream(content, w)
      })
    } catch {
      err => {
        // Use on_error handler if provided, otherwise render fallback
        let error_content = match boundary.async_node.on_error {
          Some(handler) => handler(err)
          None => (boundary.async_node.fallback)()
        }
        stream_async_replacement(boundary.id, writer, fn(w) {
          render_node_to_stream(error_content, w)
        })
      }
    }
  }
}
