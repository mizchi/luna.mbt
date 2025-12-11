///| Async Resource JS Bindings - Promise integration for browser/Node.js
///|
///| This module provides JS-specific bindings to convert Promise and
///| async functions to environment-agnostic Resource.

///|
/// Create a Resource from an async function (JS environment)
/// The async function is executed immediately and the Resource
/// is updated when it resolves or rejects.
pub fn[T] from_async(fetcher : async () -> T) -> @signal.Resource[T] {
  @signal.resource(fn(resolve, reject) {
    @js.run_async(async fn() noraise {
      try {
        let value = fetcher()
        resolve(value)
      } catch {
        e => reject(e.to_string())
      }
    })
  })
}

///|
/// Create a Resource from a Promise (JS environment)
pub fn[T] from_promise(promise : @js.Promise[T]) -> @signal.Resource[T] {
  from_async(async fn() { promise.wait() })
}

///|
/// Create a Resource that fetches from a URL (convenience helper)
pub fn fetch_text(url : String) -> @signal.Resource[String] {
  from_async(async fn() { js_fetch_text(url).wait() })
}

///|
extern "js" fn js_fetch_text(url : String) -> @js.Promise[String] =
  #| (url) => fetch(url).then(r => r.text())

///|
/// Create a Resource that fetches JSON from a URL
pub fn fetch_json(url : String) -> @signal.Resource[@js.Any] {
  from_async(async fn() { js_fetch_json(url).wait() })
}

///|
extern "js" fn js_fetch_json(url : String) -> @js.Promise[@js.Any] =
  #| (url) => fetch(url).then(r => r.json())

///|
/// Create a refetchable Resource from an async function
/// Returns a Resource that can be refetched with resource.refetch()
pub fn[T] create_resource(fetcher : async () -> T) -> @signal.Resource[T] {
  @signal.resource(fn(resolve, reject) {
    @js.run_async(async fn() noraise {
      try {
        let value = fetcher()
        resolve(value)
      } catch {
        e => reject(e.to_string())
      }
    })
  })
}

///|
/// Sleep for given milliseconds, then resolve with value
pub fn[T] delayed(ms : Int, value : T) -> @signal.Resource[T] {
  from_async(async fn() {
    @js.sleep(ms)
    value
  })
}
