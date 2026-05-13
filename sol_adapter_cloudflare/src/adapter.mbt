///| Cloudflare Workers adapter helpers for Sol.

///|
/// Mars app type used by Sol.
pub type App = @mars.Server

///|
/// Cloudflare Workers environment object.
pub type Env = @mars.JsEnv

///|
/// Cloudflare Workers execution context.
pub type ExecutionContext = @mars.JsExecCtx

///|
priv struct WorkerFetchHandler(
  (@mars.JsRequest, @mars.JsEnv, @mars.JsExecCtx) -> @js.Promise[
    @mars.JsResponse,
  ]
)

///|
extern "js" fn ffi_convert_worker_fetch_handler(
  handler : @js.Any,
) -> WorkerFetchHandler =
  #| (handler) => handler

///|
extern "js" fn ffi_set_cloudflare_runtime() -> Unit =
  #| () => {
  #|   globalThis.__SOL_RUNTIME__ = "cloudflare";
  #|   globalThis.__SOL_ADAPTER_MODE__ = true;
  #| }

///|
extern "js" fn ffi_ensure_mars_reschedule_symbol() -> Unit =
  #| () => {
  #|   if (typeof globalThis.moonbitlang$async$internal$event_loop$$reschedule !== "function") {
  #|     globalThis.moonbitlang$async$internal$event_loop$$reschedule = () => {};
  #|   }
  #| }

///|
extern "js" fn ffi_export_cloudflare_app(
  fetch_handler : WorkerFetchHandler,
) -> Unit =
  #| (fetchHandler) => {
  #|   globalThis.__SOL_APP__ = {
  #|     fetch(request, env, ctx) {
  #|       return fetchHandler(request, env, ctx);
  #|     }
  #|   };
  #| }

///|
fn to_worker_fetch_handler(app : App) -> WorkerFetchHandler {
  ffi_convert_worker_fetch_handler(
    @js.any(fn(
      request : @mars.JsRequest,
      env : @mars.JsEnv,
      ctx : @mars.JsExecCtx,
    ) {
      let fetch_handler = app.to_fetch_handler_with_env(env, ctx)
      fetch_handler(request)
    }),
  )
}

///|
/// Export a Sol app as a Cloudflare Worker `fetch(request, env, ctx)` app.
pub fn export_app(app : App) -> Unit {
  ffi_set_cloudflare_runtime()
  ffi_ensure_mars_reschedule_symbol()
  ffi_export_cloudflare_app(to_worker_fetch_handler(app))
}

///|
/// Run a configured Sol app in Cloudflare adapter mode.
pub fn run(configure : (App) -> Unit) -> Unit {
  let app = @mars.Server::new()
  configure(app)
  export_app(app)
}

///|
/// Run a Sol app factory in Cloudflare adapter mode.
pub fn run_app(create_and_configure : () -> App) -> Unit {
  let app = create_and_configure()
  export_app(app)
}
