// Runtime streaming helpers

// Streaming SSR Support
// ============================================================================

///|
/// Render a page with streaming SSR and async boundaries (VAsync nodes)
/// Returns a ReadableStream for HTTP response
/// VAsync nodes in the tree will be rendered with fallback first,
/// then resolved content will be streamed as replacement scripts
pub fn render_streaming_page(
  shell : @luna.Node[Unit, String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> @http.Response {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)

  // Build header HTML
  let header_html = @page_shell.render_streaming_header(
    title_str, head_str, loader,
  )

  // Build footer HTML
  let footer_html = @page_shell.render_streaming_footer()

  // Create streaming response with async resolution
  let stream = create_streaming_response_with_async(
    header_html, footer_html, shell,
  )
  ffi_create_stream_response(stream)
}

///|
/// Create a ReadableStream that streams HTML with async resolution
fn create_streaming_response_with_async(
  header : String,
  footer : String,
  shell : @luna.Node[Unit, String],
) -> @js.Any {
  ffi_create_streaming_response_async(header, footer, async fn(write) {
    // Use render_to_stream_with_async which handles VAsync nodes
    @stream_renderer.render_to_stream_with_async(
      shell,
      @stream_renderer.StreamWriter::from_callback(write),
    )
  })
}

///|
extern "js" fn ffi_create_streaming_response_async(
  header : String,
  footer : String,
  render_with_async : async ((String) -> Unit) -> Unit,
) -> @js.Any =
  #| (header, footer, renderWithAsync) => new ReadableStream({
  #|   async start(controller) {
  #|     const encoder = new TextEncoder();
  #|     const write = (chunk) => controller.enqueue(encoder.encode(chunk));
  #|     write(header);
  #|     await renderWithAsync(write);
  #|     write(footer);
  #|     controller.close();
  #|   }
  #| })

///|
extern "js" fn ffi_create_stream_response(stream : @js.Any) -> @http.Response =
  #| (stream) => new Response(stream, { headers: { 'Content-Type': 'text/html; charset=utf-8' } })

///|
/// Register a streaming page route with async support
/// VAsync nodes in the rendered tree will be handled automatically
/// Note: This uses ReadableStream internally for proper streaming support
pub fn streaming_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[Unit, String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let shell = render_fn(c)
      let title_str = title.unwrap_or("App")
      let head_str = head.unwrap_or("")
      let loader = loader_url.unwrap_or(default_loader_url)
      let header_html = @page_shell.render_streaming_header(
        title_str, head_str, loader,
      )
      let footer_html = @page_shell.render_streaming_footer()
      // Create streaming response and send via FFI
      let stream = create_streaming_response_with_async(
        header_html, footer_html, shell,
      )
      ffi_set_streaming_response(c, stream)
    }),
  )
}

///|
/// Set streaming response via FFI (for Mars Context)
extern "js" fn ffi_set_streaming_response(ctx : Ctx, stream : @js.Any) -> Unit =
  #| (ctx, stream) => {
  #|   const headers = { 'Content-Type': 'text/html; charset=utf-8' };
  #|   const map = ctx.response_headers;
  #|   let curr = map ? map.head : undefined;
  #|   while (curr !== undefined && curr !== -1) {
  #|     headers[curr.key] = curr.value;
  #|     curr = curr.next;
  #|   }
  #|   const response = new Response(stream, { headers });
  #|   ctx.platform.response_resolve(response);
  #|   ctx.response_sent = true;
  #| }
