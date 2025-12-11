///| Async SSR - Server-side rendering with async data fetching
///|
///| JS-specific implementation using Promise for async operations

///|
/// Render an async component to HTML string
/// Waits for all async operations to complete before rendering
pub async fn render_async(component : async () -> @kaguya.Node) -> String {
  let node = component()
  @ssr_core.render_to_string(node)
}

///|
/// Render an async component with hydration markers
pub async fn render_async_with_hydration(
  component : async () -> @kaguya.Node
) -> String {
  let node = component()
  @ssr_core.render_to_string_with_hydration(node)
}

///|
/// Collect multiple async operations in parallel (Promise.all equivalent)
pub async fn[T] collect(fetchers : Array[async () -> T]) -> Array[T] {
  let promises = fetchers.map(fn(f) { @js.from_async(f) })
  @js.Promise::all(promises).wait()
}

///|
/// Collect two async operations in parallel
pub async fn[A, B] collect2(
  a : async () -> A,
  b : async () -> B
) -> (A, B) {
  // Run in parallel using Promise.all pattern
  let result_a : Ref[A?] = { val: None }
  let result_b : Ref[B?] = { val: None }

  let promise_a = @js.from_async(async fn() {
    result_a.val = Some(a())
  })
  let promise_b = @js.from_async(async fn() {
    result_b.val = Some(b())
  })

  @js.Promise::all([promise_a, promise_b]).wait() |> ignore

  match (result_a.val, result_b.val) {
    (Some(va), Some(vb)) => (va, vb)
    _ => abort("collect2: unexpected None")
  }
}

///|
/// Collect three async operations in parallel
pub async fn[A, B, C] collect3(
  a : async () -> A,
  b : async () -> B,
  c : async () -> C
) -> (A, B, C) {
  let result_a : Ref[A?] = { val: None }
  let result_b : Ref[B?] = { val: None }
  let result_c : Ref[C?] = { val: None }

  let promise_a = @js.from_async(async fn() { result_a.val = Some(a()) })
  let promise_b = @js.from_async(async fn() { result_b.val = Some(b()) })
  let promise_c = @js.from_async(async fn() { result_c.val = Some(c()) })

  @js.Promise::all([promise_a, promise_b, promise_c]).wait() |> ignore

  match (result_a.val, result_b.val, result_c.val) {
    (Some(va), Some(vb), Some(vc)) => (va, vb, vc)
    _ => abort("collect3: unexpected None")
  }
}

///|
/// Race multiple async operations (Promise.race equivalent)
pub async fn[T] race(fetchers : Array[async () -> T]) -> T {
  let promises = fetchers.map(fn(f) { @js.from_async(f) })
  @js.Promise::race(promises).wait()
}

///|
/// Timeout wrapper - fails if async takes too long
pub async fn[T] with_timeout(
  ms : Int,
  fetcher : async () -> T
) -> T raise {
  race([
    fetcher,
    async fn() -> T {
      @js.sleep(ms)
      raise TimeoutError(ms)
    }
  ])
}

///|
suberror TimeoutError Int

///|
pub fn TimeoutError::to_string(self : TimeoutError) -> String {
  let TimeoutError(ms) = self
  "Timeout after " + ms.to_string() + "ms"
}
