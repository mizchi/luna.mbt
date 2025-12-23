// Sol ISR Memory Cache Implementation
//
// In-memory cache for development and testing.
// Not suitable for production (data lost on restart).

// ============================================================================
// MemoryCache
// ============================================================================

///|
/// In-memory ISR cache implementation
/// Suitable for development and single-instance deployments
pub struct MemoryCache {
  store : Map[String, CacheEntry]
}

///|
/// Create a new empty MemoryCache
pub fn MemoryCache::new() -> MemoryCache {
  { store: {} }
}

///|
pub impl ISRCache for MemoryCache with get(self, key) {
  self.store.get(key)
}

///|
pub impl ISRCache for MemoryCache with put(self, key, entry) {
  self.store[key] = entry
}

///|
pub impl ISRCache for MemoryCache with delete(self, key) {
  self.store.remove(key) |> ignore
}

///|
pub impl ISRCache for MemoryCache with schedule_revalidation(_self, task) {
  // In memory mode, execute task synchronously via promise
  // This is simplified - in production, use waitUntil
  let _ = ffi_run_async(task)

}

///|
extern "js" fn ffi_run_async(task : async () -> Unit) -> @js.Promise[Unit] =
  #| (task) => task()
