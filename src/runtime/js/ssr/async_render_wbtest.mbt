///| Tests for async SSR

test "render_async - compiles" {
  // Verify async SSR compiles correctly
  // Actual async tests would need a test runner that supports async
  let _f : async () -> String = async fn() -> String {
    render_async(async fn() -> @kaguya.Node {
      @kaguya.vtext("Hello")
    })
  }
}

test "collect2 - compiles" {
  let _f : async () -> (Int, String) = async fn() -> (Int, String) {
    collect2(
      async fn() -> Int { 1 },
      async fn() -> String { "hello" }
    )
  }
}

test "collect3 - compiles" {
  let _f : async () -> (Int, String, Bool) = async fn() -> (Int, String, Bool) {
    collect3(
      async fn() -> Int { 1 },
      async fn() -> String { "hello" },
      async fn() -> Bool { true }
    )
  }
}
