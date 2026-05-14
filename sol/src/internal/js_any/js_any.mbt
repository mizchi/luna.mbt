// Shared JavaScript Any helpers

///|
extern "js" fn ffi_json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any =
  #| (pairs) => Object.fromEntries(pairs.map(p => [p._0, p._1]))

///|
pub fn json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any {
  ffi_json_obj(pairs)
}

///|
extern "js" fn ffi_json_to_any(json : Json) -> @js.Any =
  #| (json) => {
  #|   const convert = (value) => {
  #|     if (value === null || value === undefined) return null;
  #|     switch (value.$tag) {
  #|       case 0: return null;
  #|       case 1: return true;
  #|       case 2: return false;
  #|       case 3: return value._0;
  #|       case 4: return value._0;
  #|       case 5: {
  #|         const arr = value._0;
  #|         if (Array.isArray(arr)) return arr.map(convert);
  #|         if (arr && Array.isArray(arr.buf)) {
  #|           return arr.buf.slice(arr.start, arr.end).map(convert);
  #|         }
  #|         return [];
  #|       }
  #|       case 6: {
  #|         const result = {};
  #|         const map = value._0;
  #|         if (map instanceof Map) {
  #|           for (const [k, v] of map.entries()) result[k] = convert(v);
  #|         } else if (map && Array.isArray(map.entries)) {
  #|           for (const entry of map.entries) {
  #|             if (entry) result[entry.key] = convert(entry.value);
  #|           }
  #|         } else if (Array.isArray(map)) {
  #|           for (const pair of map) result[pair._0 ?? pair[0]] = convert(pair._1 ?? pair[1]);
  #|         } else if (map && typeof map === "object") {
  #|           for (const [k, v] of Object.entries(map)) result[k] = convert(v);
  #|         }
  #|         return result;
  #|       }
  #|       default: return value;
  #|     }
  #|   };
  #|   return convert(json);
  #| }

///|
pub fn json_to_any(json : Json) -> @js.Any {
  ffi_json_to_any(json)
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
