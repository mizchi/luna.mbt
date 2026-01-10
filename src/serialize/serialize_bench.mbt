// Benchmarks for serialize module
// Run with: moon bench --target js src/core/serialize

// =============================================================================
// Test Data - StateValue
// =============================================================================

///|
/// Simple int value
fn sv_simple_int() -> StateValue {
  sv_int(42)
}

///|
/// Simple string value
fn sv_simple_string() -> StateValue {
  sv_str("Hello World")
}

///|
/// String with special chars (needs escaping)
fn sv_escaped_string() -> StateValue {
  sv_str("Hello \"World\" with\nnewline and\ttab")
}

///|
/// Small array of ints
fn sv_small_array() -> StateValue {
  sv_arr([sv_int(1), sv_int(2), sv_int(3)])
}

///|
/// Medium array (10 items)
fn sv_medium_array() -> StateValue {
  let arr : Array[StateValue] = []
  for i = 0; i < 10; i = i + 1 {
    arr.push(sv_int(i))
  }
  sv_arr(arr)
}

///|
/// Large array (100 items)
fn sv_large_array() -> StateValue {
  let arr : Array[StateValue] = []
  for i = 0; i < 100; i = i + 1 {
    arr.push(sv_int(i))
  }
  sv_arr(arr)
}

///|
/// Mixed array (typical state)
fn sv_mixed_array() -> StateValue {
  sv_arr([
    sv_int(42),
    sv_str("counter"),
    sv_bool(true),
    sv_number(3.14),
    sv_arr([sv_int(1), sv_int(2), sv_int(3)]),
  ])
}

///|
/// Nested array (deep nesting)
fn sv_nested_array() -> StateValue {
  sv_arr([sv_arr([sv_arr([sv_arr([sv_int(1), sv_int(2)])])])])
}

// =============================================================================
// ResumableState Test Data
// =============================================================================

///|
/// Create small state (3 values)
fn create_small_state() -> ResumableState {
  let state = ResumableState::new()
  let _ = state.register_int(42)
  let _ = state.register_string("hello")
  let _ = state.register_bool(true)
  state
}

///|
/// Create medium state (10 values)
fn create_medium_state() -> ResumableState {
  let state = ResumableState::new()
  for i = 0; i < 10; i = i + 1 {
    let _ = state.register_int(i)

  }
  state
}

///|
/// Create large state (100 values)
fn create_large_state() -> ResumableState {
  let state = ResumableState::new()
  for i = 0; i < 100; i = i + 1 {
    let _ = state.register_int(i)

  }
  state
}

///|
/// Create mixed state (typical SSR state)
fn create_mixed_state() -> ResumableState {
  let state = ResumableState::new()
  let _ = state.register_int(0) // counter
  let _ = state.register_string("Initial")
  let _ = state.register_bool(false)
  let _ = state.register_float(3.14159)
  let _ = state.register_int(100)
  state
}

// =============================================================================
// StateValue to JSON Benchmarks
// =============================================================================

///|
test "state_value_to_json: int" (b : @bench.T) {
  let value = sv_simple_int()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: string" (b : @bench.T) {
  let value = sv_simple_string()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: escaped_string" (b : @bench.T) {
  let value = sv_escaped_string()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: small_array" (b : @bench.T) {
  let value = sv_small_array()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: medium_array" (b : @bench.T) {
  let value = sv_medium_array()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: large_array" (b : @bench.T) {
  let value = sv_large_array()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: mixed_array" (b : @bench.T) {
  let value = sv_mixed_array()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

///|
test "state_value_to_json: nested_array" (b : @bench.T) {
  let value = sv_nested_array()
  b.bench(fn() { b.keep(state_value_to_json(value)) })
}

// =============================================================================
// StateValue from JSON Benchmarks (Parsing)
// =============================================================================

///|
test "state_value_from_json: int" (b : @bench.T) {
  let json = "42"
  b.bench(fn() { b.keep(state_value_from_json(json)) })
}

///|
test "state_value_from_json: string" (b : @bench.T) {
  let json = "\"Hello World\""
  b.bench(fn() { b.keep(state_value_from_json(json)) })
}

///|
test "state_value_from_json: small_array" (b : @bench.T) {
  let json = "[1,2,3]"
  b.bench(fn() { b.keep(state_value_from_json(json)) })
}

///|
test "state_value_from_json: medium_array" (b : @bench.T) {
  let json = "[0,1,2,3,4,5,6,7,8,9]"
  b.bench(fn() { b.keep(state_value_from_json(json)) })
}

///|
test "state_value_from_json: mixed_array" (b : @bench.T) {
  let json = "[42,\"counter\",true,3.14,[1,2,3]]"
  b.bench(fn() { b.keep(state_value_from_json(json)) })
}

// =============================================================================
// ResumableState Benchmarks
// =============================================================================

///|
test "ResumableState::to_json: small" (b : @bench.T) {
  let state = create_small_state()
  b.bench(fn() { b.keep(state.to_json()) })
}

///|
test "ResumableState::to_json: medium" (b : @bench.T) {
  let state = create_medium_state()
  b.bench(fn() { b.keep(state.to_json()) })
}

///|
test "ResumableState::to_json: large" (b : @bench.T) {
  let state = create_large_state()
  b.bench(fn() { b.keep(state.to_json()) })
}

///|
test "ResumableState::to_json: mixed" (b : @bench.T) {
  let state = create_mixed_state()
  b.bench(fn() { b.keep(state.to_json()) })
}

///|
test "ResumableState::from_json: small" (b : @bench.T) {
  let json = "[42,\"hello\",true]"
  b.bench(fn() { b.keep(ResumableState::from_json(json)) })
}

///|
test "ResumableState::from_json: medium" (b : @bench.T) {
  let json = "[0,1,2,3,4,5,6,7,8,9]"
  b.bench(fn() { b.keep(ResumableState::from_json(json)) })
}

// =============================================================================
// HTML State Embedding Benchmarks
// =============================================================================

///|
test "state_to_script_tag: small" (b : @bench.T) {
  let state = create_small_state()
  b.bench(fn() { b.keep(state_to_script_tag(state)) })
}

///|
test "state_to_script_tag: medium" (b : @bench.T) {
  let state = create_medium_state()
  b.bench(fn() { b.keep(state_to_script_tag(state)) })
}

///|
test "state_to_script_tag: large" (b : @bench.T) {
  let state = create_large_state()
  b.bench(fn() { b.keep(state_to_script_tag(state)) })
}

///|
test "state_to_script_tag: with id" (b : @bench.T) {
  let state = create_small_state()
  b.bench(fn() { b.keep(state_to_script_tag(state, id="my-component")) })
}

// =============================================================================
// JSON String Escaping Benchmarks
// =============================================================================

///|
test "escape_json_string: safe" (b : @bench.T) {
  let s = "Hello World without special chars"
  b.bench(fn() { b.keep(escape_json_string(s)) })
}

///|
test "escape_json_string: with_quotes" (b : @bench.T) {
  let s = "Hello \"World\" with quotes"
  b.bench(fn() { b.keep(escape_json_string(s)) })
}

///|
test "escape_json_string: with_newlines" (b : @bench.T) {
  let s = "Line 1\nLine 2\nLine 3\tTabbed"
  b.bench(fn() { b.keep(escape_json_string(s)) })
}

///|
test "escape_json_string: heavy" (b : @bench.T) {
  let s = "\"quoted\"\n\"more\"\t\"tabs\"\r\n\"crlf\"\\\\"
  b.bench(fn() { b.keep(escape_json_string(s)) })
}

// =============================================================================
// Registration vs Lookup Benchmarks
// =============================================================================

///|
test "ResumableState: register operations" (b : @bench.T) {
  b.bench(name="register_int", fn() {
    let state = ResumableState::new()
    b.keep(state.register_int(42))
  })
  b.bench(name="register_string", fn() {
    let state = ResumableState::new()
    b.keep(state.register_string("hello"))
  })
  b.bench(name="register_bool", fn() {
    let state = ResumableState::new()
    b.keep(state.register_bool(true))
  })
}

///|
test "ResumableState: get operations" (b : @bench.T) {
  let state = create_medium_state()
  b.bench(name="get(0)", fn() { b.keep(state.get(0)) })
  b.bench(name="get(5)", fn() { b.keep(state.get(5)) })
  b.bench(name="get(9)", fn() { b.keep(state.get(9)) })
  b.bench(name="get_int(5)", fn() { b.keep(state.get_int(5)) })
}
