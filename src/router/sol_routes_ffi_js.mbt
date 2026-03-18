// JS-specific FFI for sol_routes
// These are separated to enable future native compilation of the core router.

///|
extern "js" fn ffi_ensure_mars_to_handler_reschedule_symbol() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

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
