// JS-specific FFI for sol_routes

///|
extern "js" fn ffi_console_error(msg : String) -> Unit =
  #| (msg) => console.error(msg)

///|
extern "js" fn ffi_ensure_mars_to_handler_reschedule_symbol() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

///|
extern "js" fn ffi_create_streaming_response(
  render_with_async : async ((String) -> Unit) -> Unit,
) -> @js.Any =
  #| (renderWithAsync) => new ReadableStream({
  #|   async start(controller) {
  #|     const encoder = new TextEncoder();
  #|     const write = (chunk) => controller.enqueue(encoder.encode(chunk));
  #|     try {
  #|       await renderWithAsync(write);
  #|       controller.close();
  #|     } catch (e) {
  #|       console.error("[sol] Streaming SSR error:", e);
  #|       try { controller.error(e); } catch (_) {}
  #|     }
  #|   }
  #| })

///|
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

///|
extern "js" fn ffi_json_stringify_any(data : @js.Any) -> String =
  #| (data) => JSON.stringify(data)

///|
/// Send streaming SSR page via JS ReadableStream.
/// The header/footer/rendering logic is portable; only the transport is JS-specific.
async fn send_streaming_server_page(
  c : Ctx,
  node : @server_dom.ServerNode,
  title : String,
  head : String,
  loader_url : String,
  root_template : String,
) -> Unit {
  let full_head = @hot_reload.with_dev_head_script(head)
  let (header_html, footer_html) = match
    @page_shell.render_streaming_template_parts(
      root_template, title, full_head, "", loader_url,
    ) {
    Some(parts) => parts
    None =>
      (
        @page_shell.render_streaming_header(title, full_head, loader_url),
        @page_shell.render_streaming_footer(),
      )
  }
  // JS: use ReadableStream for chunked transfer encoding
  // Header is flushed immediately (fast TTFB), then node is resolved
  // inside the stream so async data fetching happens during streaming.
  let stream = ffi_create_streaming_response(async fn(write) {
    write(header_html)
    let resolved_node = node.resolve()
    @portable_stream.render_to_stream_with_async(
      resolved_node,
      @portable_stream.StreamWriter::from_callback(write),
    )
    write(footer_html)
  })
  ffi_set_streaming_response(c, stream)
}
