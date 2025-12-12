///| Stream SSR - Streaming server-side rendering
///|
///| Provides chunked HTML output for faster Time-To-First-Byte (TTFB)

///|
/// Stream writer callback - receives chunks as they're ready
pub struct StreamWriter ((String) -> Unit)

///|
/// Render a node to a stream, calling writer for each chunk
pub fn render_to_stream(node : @kaguya.Node, writer : StreamWriter) -> Unit {
  render_node_to_stream(node, writer)
}

///|
fn render_node_to_stream(node : @kaguya.Node, writer : StreamWriter) -> Unit {
  let write = writer.0
  match node {
    Text(content) => write(escape_html(content))
    DynamicText(getter) => write(escape_html(getter()))
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
      render_attrs_to_sb(sb, elem.attrs)
      if is_void_element(tag) {
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
    Show(condition=cond, child=child_fn) =>
      if cond() {
        render_node_to_stream(child_fn(), writer)
      } else {
        write("<!--show-->")
      }
    For(render=render_fn) =>
      for item in render_fn() {
        render_node_to_stream(item, writer)
      }
    Component(render=render_fn) => render_node_to_stream(render_fn(), writer)
  }
}

///|
/// Suspense boundary for streaming - renders fallback immediately,
/// then streams content when ready
pub struct Suspense {
  id : Int
  fallback : @kaguya.Node
  content : async () -> @kaguya.Node
}

///|
/// Create a suspense boundary
pub fn suspense(
  id : Int,
  fallback~ : @kaguya.Node,
  content~ : async () -> @kaguya.Node
) -> Suspense {
  { id, fallback, content }
}

///|
/// Render with suspense boundaries - streams shell immediately,
/// then streams resolved content with replacement scripts
pub async fn render_with_suspense(
  shell : @kaguya.Node,
  suspenses : Array[Suspense],
  writer : StreamWriter
) -> Unit {
  let write = writer.0
  // 1. Render shell with suspense placeholders
  render_node_to_stream(shell, writer)

  // 2. Start streaming script for replacements
  write("<script>function $RC(id,html){var e=document.getElementById('S:'+id);if(e){var t=document.createElement('template');t.innerHTML=html;e.replaceWith(t.content);}}</script>")

  // 3. Resolve each suspense and stream replacement
  for s in suspenses {
    let content = (s.content)()
    let html = @ssr_core.render_to_string(content)
    let escaped = escape_js_string(html)
    write("<script>$RC(" + s.id.to_string() + ",\"" + escaped + "\")</script>")
  }
}

///|
/// Render suspense fallback as placeholder
pub fn render_suspense_placeholder(s : Suspense, writer : StreamWriter) -> Unit {
  let write = writer.0
  write("<div id=\"S:" + s.id.to_string() + "\">")
  render_node_to_stream(s.fallback, writer)
  write("</div>")
}

///|
/// Helper: escape HTML special characters
fn escape_html(s : String) -> String {
  let sb = StringBuilder::new()
  for char in s {
    match char {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(char)
    }
  }
  sb.to_string()
}

///|
/// Helper: escape JS string for embedding in script
fn escape_js_string(s : String) -> String {
  let sb = StringBuilder::new()
  for char in s {
    match char {
      '\\' => sb.write_string("\\\\")
      '"' => sb.write_string("\\\"")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      '<' => sb.write_string("\\u003c") // Prevent </script> injection
      '>' => sb.write_string("\\u003e")
      _ => sb.write_char(char)
    }
  }
  sb.to_string()
}

///|
/// Helper: check void elements
fn is_void_element(tag : String) -> Bool {
  match tag {
    "br" | "hr" | "img" | "input" | "meta" | "link" | "area" | "base" | "col" |
    "embed" | "param" | "source" | "track" | "wbr" => true
    _ => false
  }
}

///|
/// Helper: render attributes to StringBuilder
fn render_attrs_to_sb(sb : StringBuilder, attrs : Array[(String, @kaguya.Attr)]) -> Unit {
  for attr in attrs {
    let (name, value) = attr
    match value {
      VStatic(s) =>
        if s != "__remove__" {
          if s == "" {
            sb.write_char(' ')
            sb.write_string(name)
          } else {
            sb.write_char(' ')
            sb.write_string(name)
            sb.write_string("=\"")
            sb.write_string(escape_html(s))
            sb.write_char('"')
          }
        }
      VDynamic(getter) => {
        let s = getter()
        if s != "__remove__" && s != "" {
          sb.write_char(' ')
          sb.write_string(name)
          sb.write_string("=\"")
          sb.write_string(escape_html(s))
          sb.write_char('"')
        }
      }
      VHandler(_) => () // Skip handlers
      VAction(action_name) => {
        // Render action as data-action attribute for hydration
        let event_name = if name.has_prefix("on") {
          name.substring(start=2)
        } else {
          name
        }
        sb.write_string(" data-action-")
        sb.write_string(event_name)
        sb.write_string("=\"")
        sb.write_string(escape_html(action_name))
        sb.write_char('"')
      }
    }
  }
}

///|
/// Create a ReadableStream for HTTP response (Node.js/Web Streams API)
extern "js" fn js_create_readable_stream(
  start : ((String) -> Unit) -> Unit
) -> @js.Any =
  #| (start) => new ReadableStream({
  #|   start(controller) {
  #|     start((chunk) => {
  #|       controller.enqueue(new TextEncoder().encode(chunk));
  #|     });
  #|   }
  #| })

///|
/// Render to a ReadableStream for streaming HTTP response
pub fn render_to_readable_stream(node : @kaguya.Node) -> @js.Any {
  js_create_readable_stream(fn(enqueue) {
    render_to_stream(node, StreamWriter(fn(chunk) { enqueue(chunk) }))
  })
}

///|
/// Async render to stream with suspense support
pub async fn render_to_readable_stream_with_suspense(
  shell : @kaguya.Node,
  suspenses : Array[Suspense]
) -> @js.Any {
  let chunks : Array[String] = []

  // Collect all chunks
  render_with_suspense(shell, suspenses, StreamWriter(fn(chunk) { chunks.push(chunk) }))

  // Create stream from collected chunks
  js_create_readable_stream(fn(enqueue) {
    for chunk in chunks {
      enqueue(chunk)
    }
  })
}
