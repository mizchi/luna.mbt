// Runtime environment and mount helpers

///|
/// Check if running in adapter mode (SOL_ADAPTER env variable)
/// When true, server startup is delegated to the adapter wrapper (serve.js)
extern "js" fn is_adapter_mode() -> Bool =
  #| () => globalThis.__SOL_ADAPTER_MODE__ === true ||
  #|   (typeof process !== 'undefined' && process.env?.SOL_ADAPTER === "1")

///|
extern "js" fn is_edge_runtime() -> Bool =
  #| () => globalThis.__SOL_RUNTIME__ === "cloudflare" ||
  #|   globalThis.__SOL_EDGE_RUNTIME__ === true

///|
extern "js" fn ffi_init_fs() -> @js.Promise[Unit] =
  #| () => {
  #|   const importer = globalThis.__SOL_DYNAMIC_IMPORT__ ||
  #|     ((specifier) => import(specifier));
  #|   return importer('node:fs').then(fs => { globalThis.__SOL_FS__ = fs; });
  #| }

///|
fn with_initialized_fs(callback : () -> Unit) -> Unit {
  let _ = ffi_init_fs().then(fn(_) {
    callback()
    @js.Promise::resolve(@js.any(()))
  })
}

///|
/// Get port from PORT environment variable, default to 7777
fn runtime_port_from_env() -> Int {
  @hot_reload.app_port_from_env()
}
