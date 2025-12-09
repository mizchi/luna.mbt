///| Context Storage Interface

///|

///| Provides an abstraction over context value storage,

///| allowing different backends (JavaScript Map, in-memory Map, etc.)

///|
/// Context storage interface using function pointers
pub struct ContextStorage {
  get_value : (Int) -> @core.Any?
  set_value : (Int, @core.Any) -> Unit
  delete_value : (Int) -> Unit
  get_next_id : () -> Int
}

///| Create a JavaScript-based context storage (default implementation)

///|

///| Uses globalThis and JavaScript Map for storage.

///|
/// This is the production implementation for browser/Node.js environments.
pub fn create_js_storage() -> ContextStorage {
  {
    get_value: js_storage_get,
    set_value: js_storage_set,
    delete_value: js_storage_delete,
    get_next_id: js_storage_next_id,
  }
}

///| JavaScript storage implementation using globalThis and Map

///|
/// Check if a property exists on an object
extern "js" fn has_property(obj : @core.Any, key : String) -> Bool =
  #| (obj, key) => key in obj

///|
/// Create a new JavaScript Map
extern "js" fn new_map() -> @core.Any =
  #| () => new Map()

///|
/// Get value from JS storage
fn js_storage_get(id : Int) -> @core.Any? {
  let storage = get_js_context_map()
  let has : Bool = storage._call("has", [@core.any(id)]).cast()
  if has {
    Some(storage._call("get", [@core.any(id)]))
  } else {
    None
  }
}

///|
/// Set value in JS storage
fn js_storage_set(id : Int, value : @core.Any) -> Unit {
  let storage = get_js_context_map()
  storage._call("set", [@core.any(id), value]) |> ignore
}

///|
/// Delete value from JS storage
fn js_storage_delete(id : Int) -> Unit {
  let storage = get_js_context_map()
  storage._call("delete", [@core.any(id)]) |> ignore
}

///|
/// Get next available context ID from JS storage
fn js_storage_next_id() -> Int {
  let global : @core.Any = @global.globalThis()
  let storage_key = "__moonbit_context_id"
  let has_storage : Bool = has_property(global, storage_key)
  if has_storage {
    let current : Int = global._get(storage_key).cast()
    global._set(storage_key, @core.any(current + 1))
    current
  } else {
    global._set(storage_key, @core.any(1))
    0
  }
}

///|
/// Get global context storage Map
fn get_js_context_map() -> @core.Any {
  let global : @core.Any = @global.globalThis()
  let storage_key = "__moonbit_context_storage"
  let has_storage : Bool = has_property(global, storage_key)
  if has_storage {
    global._get(storage_key)
  } else {
    let map = new_map()
    global._set(storage_key, map)
    map
  }
}

///| Create an in-memory context storage (for testing/non-JS environments)

///|

///| Note: This is a placeholder for future implementation.

///| Currently, we only support JavaScript-based storage.

///|

///|
/// TODO: Implement using MoonBit's Map once available.
pub fn create_memory_storage() -> ContextStorage {
  // For now, use JavaScript storage as fallback
  // This will be replaced with a pure MoonBit implementation in the future
  create_js_storage()
}
