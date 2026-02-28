// JS Resource Lite API - minimal runtime with JS extern implementations

///|
/// Opaque type for JS interop
#external
pub type Any

extern "js" fn _create_resource(
  fetcher : ((Any) -> Unit, (String) -> Unit) -> Unit,
) -> Any =
  #| (fetcher) => {
  #|   const resource = { state: { $tag: 0 }, fetcher: fetcher };
  #|   const refetch = () => {
  #|     resource.state = { $tag: 0 };
  #|     fetcher(
  #|       (value) => {
  #|         resource.state = { $tag: 1, _0: value };
  #|       },
  #|       (error) => {
  #|         resource.state = { $tag: 2, _0: String(error) };
  #|       },
  #|     );
  #|   };
  #|   resource.refetch = refetch;
  #|   refetch();
  #|   return resource;
  #| }

extern "js" fn _create_deferred() -> (Any, (Any) -> Unit, (String) -> Unit) =
  #| () => {
  #|   const resource = {
  #|     state: { $tag: 0 },
  #|     refetch: () => {
  #|       resource.state = { $tag: 0 };
  #|     },
  #|   };
  #|   const resolve = (value) => {
  #|     resource.state = { $tag: 1, _0: value };
  #|   };
  #|   const reject = (error) => {
  #|     resource.state = { $tag: 2, _0: String(error) };
  #|   };
  #|   return { _0: resource, _1: resolve, _2: reject };
  #| }

extern "js" fn _resource_get(resource : Any) -> Any =
  #| (resource) => resource.state

extern "js" fn _resource_peek(resource : Any) -> Any =
  #| (resource) => resource.state

extern "js" fn _resource_refetch(resource : Any) -> Unit =
  #| (resource) => { resource.refetch(); }

extern "js" fn _resource_is_pending(resource : Any) -> Bool =
  #| (resource) => resource.state.$tag === 0

extern "js" fn _resource_is_success(resource : Any) -> Bool =
  #| (resource) => resource.state.$tag === 1

extern "js" fn _resource_is_failure(resource : Any) -> Bool =
  #| (resource) => resource.state.$tag === 2

extern "js" fn _resource_value(resource : Any) -> Any =
  #| (resource) => (resource.state.$tag === 1 ? resource.state._0 : undefined)

extern "js" fn _resource_error(resource : Any) -> Any =
  #| (resource) => (resource.state.$tag === 2 ? resource.state._0 : undefined)

extern "js" fn _state_is_pending(state : Any) -> Bool =
  #| (state) => state.$tag === 0

extern "js" fn _state_is_success(state : Any) -> Bool =
  #| (state) => state.$tag === 1

extern "js" fn _state_is_failure(state : Any) -> Bool =
  #| (state) => state.$tag === 2

extern "js" fn _state_value(state : Any) -> Any =
  #| (state) => (state.$tag === 1 ? state._0 : undefined)

extern "js" fn _state_error(state : Any) -> Any =
  #| (state) => (state.$tag === 2 ? state._0 : undefined)

///|
/// Create a Resource from a callback-based fetcher
pub fn create_resource(fetcher : ((Any) -> Unit, (String) -> Unit) -> Unit) -> Any {
  _create_resource(fetcher)
}

///|
/// Create a deferred Resource (starts pending, resolve/reject manually)
pub fn create_deferred() -> (Any, (Any) -> Unit, (String) -> Unit) {
  _create_deferred()
}

///|
/// Get current async state
pub fn resource_get(resource : Any) -> Any {
  _resource_get(resource)
}

///|
/// Peek current async state
pub fn resource_peek(resource : Any) -> Any {
  _resource_peek(resource)
}

///|
/// Trigger refetch
pub fn resource_refetch(resource : Any) -> Unit {
  _resource_refetch(resource)
}

///|
/// Check if currently pending
pub fn resource_is_pending(resource : Any) -> Bool {
  _resource_is_pending(resource)
}

///|
/// Check if successfully loaded
pub fn resource_is_success(resource : Any) -> Bool {
  _resource_is_success(resource)
}

///|
/// Check if failed
pub fn resource_is_failure(resource : Any) -> Bool {
  _resource_is_failure(resource)
}

///|
/// Get value if success, undefined otherwise
pub fn resource_value(resource : Any) -> Any {
  _resource_value(resource)
}

///|
/// Get error if failure, undefined otherwise
pub fn resource_error(resource : Any) -> Any {
  _resource_error(resource)
}

///|
/// Check if state is pending
pub fn state_is_pending(state : Any) -> Bool {
  _state_is_pending(state)
}

///|
/// Check if state is success
pub fn state_is_success(state : Any) -> Bool {
  _state_is_success(state)
}

///|
/// Check if state is failure
pub fn state_is_failure(state : Any) -> Bool {
  _state_is_failure(state)
}

///|
/// Get value from state if success
pub fn state_value(state : Any) -> Any {
  _state_value(state)
}

///|
/// Get error from state if failure
pub fn state_error(state : Any) -> Any {
  _state_error(state)
}
