// Shared JavaScript Any helpers

///|
extern "js" fn ffi_json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any =
  #| (pairs) => Object.fromEntries(pairs.map(p => [p._0, p._1]))

///|
pub fn json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any {
  ffi_json_obj(pairs)
}

///|
extern "js" fn ffi_object_get_string(obj : @js.Any, key : String) -> String? =
  #| (obj, key) => {
  #|   const value = obj?.[key];
  #|   return typeof value === 'string' ? value : undefined;
  #| }

///|
pub fn object_get_string(obj : @js.Any, key : String) -> String? {
  ffi_object_get_string(obj, key)
}
