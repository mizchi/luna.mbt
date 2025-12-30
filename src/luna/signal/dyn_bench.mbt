///|
/// Benchmarks for comparing () -> T vs Signal[T] for DSL design
/// Question: Should dyn_class accept () -> String or Signal[String]?

// =============================================================================
// Direct function call vs Signal.get() vs wrapped Signal
// =============================================================================

///|
test "dyn: direct function call (1000 reads)" (b : @bench.T) {
  // Simulating a pure getter function
  let value = "static-class-name"
  let getter : () -> String = fn() { value }
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = getter()

    }
  })
}

///|
test "dyn: Signal.get (1000 reads)" (b : @bench.T) {
  let sig = signal("static-class-name")
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.get()

    }
  })
}

///|
test "dyn: Signal.peek (1000 reads, no tracking)" (b : @bench.T) {
  let sig = signal("static-class-name")
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.peek()

    }
  })
}

///|
test "dyn: wrapped Signal in closure (1000 reads)" (b : @bench.T) {
  // This is what users would write if dyn_ accepts () -> T
  let sig = signal("static-class-name")
  let getter : () -> String = fn() { sig.get() }
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = getter()

    }
  })
}

// =============================================================================
// With computation (more realistic case)
// =============================================================================

///|
test "dyn: computed function (1000 reads)" (b : @bench.T) {
  let completed = signal(true)
  let editing = signal(false)
  // TodoMVC-style class computation
  let class_getter : () -> String = fn() {
    match (completed.get(), editing.get()) {
      (true, true) => "completed editing"
      (true, false) => "completed"
      (false, true) => "editing"
      (false, false) => ""
    }
  }
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = class_getter()

    }
  })
}

///|
test "dyn: memo computed (1000 reads)" (b : @bench.T) {
  let completed = signal(true)
  let editing = signal(false)
  let class_memo = memo(fn() {
    match (completed.get(), editing.get()) {
      (true, true) => "completed editing"
      (true, false) => "completed"
      (false, true) => "editing"
      (false, false) => ""
    }
  })
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = class_memo()

    }
  })
}

// =============================================================================
// API design comparison: () -> T vs Signal[T]
// =============================================================================

// Simulating DSL parameter handling

///|
/// If dyn_class accepts () -> String
fn apply_dyn_getter(getter : () -> String) -> String {
  getter()
}

///|
/// If dyn_class accepts Signal[String]
fn apply_dyn_signal(sig : Signal[String]) -> String {
  sig.get()
}

///|
test "api: () -> String parameter (1000 calls)" (b : @bench.T) {
  let sig = signal("class-name")
  let getter : () -> String = fn() { sig.get() }
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = apply_dyn_getter(getter)

    }
  })
}

///|
test "api: Signal[String] parameter (1000 calls)" (b : @bench.T) {
  let sig = signal("class-name")
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = apply_dyn_signal(sig)

    }
  })
}

// =============================================================================
// Bool case (for checked, disabled, etc.)
// =============================================================================

///|
test "dyn bool: () -> Bool (1000 reads)" (b : @bench.T) {
  let sig = signal(true)
  let getter : () -> Bool = fn() { sig.get() }
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = getter()

    }
  })
}

///|
test "dyn bool: Signal[Bool].get (1000 reads)" (b : @bench.T) {
  let sig = signal(true)
  b.bench(fn() {
    for i = 0; i < 1000; i = i + 1 {
      let _ = sig.get()

    }
  })
}
