// Tests for MBTI Parser

// =============================================================================
// Function Parsing Tests
// =============================================================================

///|
test "parse simple function" {
  let content =
    #|// Generated using `moon info`, DON'T EDIT IT
    #|package "example/sol-app/client"
    #|
    #|// Values
    #|fn counter(CounterProps) -> @element.DomNode
    #|
    #|// Types and methods
    #|pub(all) struct CounterProps {
    #|  initial_count : Int
    #|}
  let funcs = parse_pub_funcs(content, "test.mbti")
  assert_eq(funcs.length(), 1)
  assert_eq(funcs[0].name, "counter")
  assert_true(funcs[0].type_name is None)
}

///|
test "parse function with type (method)" {
  let content =
    #|package "test"
    #|
    #|fn[A, B] List::map(Self[A], (A) -> B) -> Self[B]
    #|fn[A] empty() -> List[A]
  let funcs = parse_pub_funcs(content, "test.mbti")
  assert_eq(funcs.length(), 2)
  // Method
  assert_eq(funcs[0].name, "map")
  assert_eq(funcs[0].type_name, Some("List"))
  // Standalone function
  assert_eq(funcs[1].name, "empty")
  assert_true(funcs[1].type_name is None)
}

///|
test "parse multiple methods on same type" {
  let content =
    #|package "test"
    #|
    #|fn Counter::new(Int) -> Counter
    #|fn Counter::increment(Counter) -> Counter
    #|fn Counter::decrement(Counter) -> Counter
    #|fn Counter::value(Counter) -> Int
  let funcs = parse_pub_funcs(content, "test.mbti")
  assert_eq(funcs.length(), 4)
  for f in funcs {
    assert_eq(f.type_name, Some("Counter"))
  }
}

///|
test "get standalone funcs filters out methods" {
  let content =
    #|package "test"
    #|
    #|fn[A, B] List::map(Self[A], (A) -> B) -> Self[B]
    #|fn counter(Props) -> Node
    #|fn render(State) -> Node
    #|fn Option::unwrap(Self) -> T
  let funcs = parse_pub_funcs(content, "test.mbti")
  let standalone = get_standalone_funcs(funcs)
  assert_eq(standalone.length(), 2)
  assert_eq(standalone[0], "counter")
  assert_eq(standalone[1], "render")
}

///|
test "get methods for specific type" {
  let content =
    #|package "test"
    #|
    #|fn Counter::new(Int) -> Counter
    #|fn Counter::value(Counter) -> Int
    #|fn Timer::start() -> Timer
    #|fn Timer::stop(Timer) -> Unit
    #|fn helper() -> Unit
  let funcs = parse_pub_funcs(content, "test.mbti")
  let counter_methods = get_methods_for_type(funcs, "Counter")
  assert_eq(counter_methods.length(), 2)
  assert_eq(counter_methods[0], "new")
  assert_eq(counter_methods[1], "value")
  let timer_methods = get_methods_for_type(funcs, "Timer")
  assert_eq(timer_methods.length(), 2)
}

// =============================================================================
// Struct Parsing Tests
// =============================================================================

///|
test "parse struct definitions - pub(all)" {
  let content =
    #|package "example/sol-app/client"
    #|
    #|pub fn counter(CounterProps) -> @element.DomNode
    #|
    #|pub(all) struct CounterProps {
    #|  initial_count : Int
    #|}
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 1)
  assert_eq(structs[0].name, "CounterProps")
  assert_eq(structs[0].visibility, "pub(all)")
  assert_true(structs[0].raw_definition.contains("initial_count"))
}

///|
test "parse struct definitions - pub" {
  let content =
    #|package "test"
    #|
    #|pub struct Config {
    #|  debug : Bool
    #|  timeout : Int
    #|}
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 1)
  assert_eq(structs[0].name, "Config")
  assert_eq(structs[0].visibility, "pub")
}

///|
test "parse multiple struct definitions" {
  let content =
    #|package "test"
    #|
    #|pub(all) struct CounterProps {
    #|  count : Int
    #|}
    #|
    #|pub(all) struct UserState {
    #|  name : String
    #|  age : Int
    #|}
    #|
    #|pub(all) struct ButtonProps {
    #|  label : String
    #|  disabled : Bool
    #|}
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 3)
  assert_eq(structs[0].name, "CounterProps")
  assert_eq(structs[1].name, "UserState")
  assert_eq(structs[2].name, "ButtonProps")
}

///|
test "get props structs filters by suffix" {
  let content =
    #|package "test"
    #|
    #|pub(all) struct CounterProps {
    #|  count : Int
    #|}
    #|pub(all) struct UserState {
    #|  name : String
    #|}
    #|pub(all) struct ButtonProps {
    #|  label : String
    #|}
    #|pub(all) struct Config {
    #|  debug : Bool
    #|}
  let structs = parse_struct_defs(content, "test.mbti")
  let props = get_props_structs(structs)
  assert_eq(props.length(), 2)
  assert_eq(props[0].name, "CounterProps")
  assert_eq(props[1].name, "ButtonProps")
}

///|
test "parse single line struct" {
  let content =
    #|package "test"
    #|
    #|pub(all) struct Empty {}
    #|pub struct Point { x : Int, y : Int }
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 2)
  assert_eq(structs[0].name, "Empty")
  assert_eq(structs[1].name, "Point")
}

///|
test "parse nested struct (multi-line)" {
  let content =
    #|package "test"
    #|
    #|pub(all) struct ComplexProps {
    #|  config : Config
    #|  items : Array[Item]
    #|  callback : (Int) -> Unit
    #|}
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 1)
  assert_eq(structs[0].name, "ComplexProps")
  assert_true(structs[0].raw_definition.contains("config"))
  assert_true(structs[0].raw_definition.contains("items"))
  assert_true(structs[0].raw_definition.contains("callback"))
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "empty content" {
  let content = ""
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 0)
}

///|
test "content with only package declaration" {
  let content =
    #|package "test"
  let structs = parse_struct_defs(content, "test.mbti")
  assert_eq(structs.length(), 0)
}

///|
test "parse generic function signatures" {
  let content =
    #|package "test"
    #|
    #|fn[T] identity(T) -> T
    #|fn[A, B] compose((A) -> B, (B) -> C) -> (A) -> C
  let funcs = parse_pub_funcs(content, "test.mbti")
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0].name, "identity")
  assert_eq(funcs[1].name, "compose")
}
