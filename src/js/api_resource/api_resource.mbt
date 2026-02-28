// JS Resource API - focused wrappers for tree-shake friendly resource entrypoint

///|
/// Opaque type for JS interop - represents any JS value
#external
pub type Any

///|
/// Resource wrapper for JS
pub struct JsResource(@resource.Resource[Any])

///|
/// AsyncState wrapper for JS
pub struct JsAsyncState(@ui.AsyncState[Any])

///|
/// Create a Resource from a callback-based fetcher
pub fn create_resource(
  fetcher : ((Any) -> Unit, (String) -> Unit) -> Unit,
) -> JsResource {
  JsResource(@resource.resource(fetcher))
}

///|
/// Create a deferred Resource (starts pending, resolve/reject manually)
pub fn create_deferred() -> (JsResource, (Any) -> Unit, (String) -> Unit) {
  let (res, resolve, reject) = @resource.deferred()
  (JsResource(res), resolve, reject)
}

///|
/// Get current async state (reactive)
pub fn resource_get(res : JsResource) -> JsAsyncState {
  JsAsyncState(res.0.get())
}

///|
/// Peek current state without tracking
pub fn resource_peek(res : JsResource) -> JsAsyncState {
  JsAsyncState(res.0.peek())
}

///|
/// Trigger refetch
pub fn resource_refetch(res : JsResource) -> Unit {
  res.0.refetch()
}

///|
/// Check if currently pending
pub fn resource_is_pending(res : JsResource) -> Bool {
  res.0.is_pending()
}

///|
/// Check if successfully loaded
pub fn resource_is_success(res : JsResource) -> Bool {
  res.0.is_success()
}

///|
/// Check if failed
pub fn resource_is_failure(res : JsResource) -> Bool {
  res.0.is_failure()
}

///|
/// Get value if success, undefined otherwise
pub fn resource_value(res : JsResource) -> Any {
  match res.0.value() {
    Some(v) => v
    None => undefined()
  }
}

///|
/// Get error if failure, undefined otherwise
pub fn resource_error(res : JsResource) -> Any {
  match res.0.error() {
    Some(e) => js_any_from_string(e)
    None => undefined()
  }
}

///|
/// Check if state is pending
pub fn state_is_pending(state : JsAsyncState) -> Bool {
  state.0.is_pending()
}

///|
/// Check if state is success
pub fn state_is_success(state : JsAsyncState) -> Bool {
  state.0.is_success()
}

///|
/// Check if state is failure
pub fn state_is_failure(state : JsAsyncState) -> Bool {
  state.0.is_failure()
}

///|
/// Get value from state if success
pub fn state_value(state : JsAsyncState) -> Any {
  match state.0.value() {
    Some(v) => v
    None => undefined()
  }
}

///|
/// Get error from state if failure
pub fn state_error(state : JsAsyncState) -> Any {
  match state.0.error() {
    Some(e) => js_any_from_string(e)
    None => undefined()
  }
}

///|
/// JS undefined value
extern "js" fn undefined() -> Any =
  #| () => undefined

///|
/// Convert String to JS Any
extern "js" fn js_any_from_string(s : String) -> Any =
  #| (s) => s
