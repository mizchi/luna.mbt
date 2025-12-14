# MoonBit Cheatsheet

A quick reference for MoonBit syntax, highlighting differences from Rust.

## Key Differences from Rust

### Syntax

1. Function return type annotation is required: `fn foo() -> Unit`
2. Struct initialization: `Point::{ x, y }` (double colon)
3. No `impl` blocks: `fn Type::method(...)`
4. String interpolation: `\{...}` (curly braces)

### Error Handling

5. No `?` operator (explicit `match` required)
6. Result methods: only `map`, `unwrap_or` available

### Generics

7. Type parameters use square brackets: `[T]`
8. Type parameters before function name: `fn[T] name`
9. No `where` clause: use `[T : Trait]`

### Namespaces

10. No `use` statement: use `@alias.function`
11. No reserved word escaping (use suffix `_` instead)

## Basic Syntax

```mbt

///|
// Variables
fn variables() -> Unit {
  let x = 10 // immutable
  let mut y = 20 // mutable
  y = y + 1
  println("\{x}, \{y}")
}

///|
// Function expressions and type inference
fn function_expressions() -> Int {
  let add = fn(x, y) { x + y } // fn expression
  let add2 : (Int, Int) -> Int = (x, y) => x + y // arrow function
  let _ = add(5, 15) + add2(10, 10)
  let _ = [1, 2, 3].map(_.mul(2)) // _.method(args) form
  1
}

///|
fn add_five(x : Int) -> Int {
  x + 5
}

///|
fn multiply_two(x : Int) -> Int {
  x * 2
}

///|
// Pipeline operator
fn pipeline_example() -> Int {
  10 |> add_five |> multiply_two // 30
}

///|
struct Builder {
  mut name : String
  mut age : Int
}

///|
fn Builder::new() -> Builder {
  Builder::{ name: "", age: 0 }
}

///|
fn Builder::set_name(self : Self, n : String) -> Unit {
  self.name = n
}

///|
fn Builder::set_age(self : Self, a : Int) -> Unit {
  self.age = a
}

///|
// Method cascade
fn cascade_example() -> Unit {
  let b = Builder::new()
  b..set_name("Alice")..set_age(30) // Chain methods on same receiver
}
```

## Pattern Matching

```moonbit

///|
fn option_match(opt : String?) -> Int {
  match opt {
    Some(s) => s.length()
    None => 0
  }
}

///|
/// Do not use ,
enum Status {
  Active
  Inactive
  Pending
}

///|
fn check_status(status : Status) -> String {
  match status {
    Active => "Active"
    Inactive => "Inactive"
    Pending => "Pending"
  }
}
```

## Structs and Methods

```moonbit

///|
/// Do not use ,
struct Coord {
  x : Int
  y : Int
}

///|
struct Counter {
  mut value : Int
}

///|
fn Counter::new() -> Counter {
  Counter::{ value: 0 } // or { value: 0 }
}

///|
fn Counter::increment(self : Self) -> Unit {
  self.value = self.value + 1
}
```

## Error Handling

```moonbit

///|
fn parse_example(s : String) -> Result[Int, String] {
  if s == "42" {
    Ok(42)
  } else {
    Err("Invalid")
  }
}

///|
// No ? operator - explicit match required
fn propagate_error(s : String) -> Result[Int, String] {
  match parse_example(s) {
    Ok(n) => Ok(n * 2)
    Err(e) => Err(e)
  }
}

///|
// map is available
fn with_map(s : String) -> Result[Int, String] {
  parse_example(s).map(n => n * 2)
}
```

## Generics

```moonbit

///|
// Use [T], fn[T] order
pub fn[T] identity(x : T) -> T {
  x
}

///|
pub struct Container[T] {
  value : T
}

///|
// Trait bounds: [T : Trait]
pub fn[T : Show] print_value(x : T) -> Unit {
  println(x.to_string())
}
```

## Namespaces

- **Builtin fn**
  - `println`, `ignore`, `not`, `tap`, `panic`, `abort`, `fail`
  - assertions: `inspect`, `assert_eq`, `assert_true`,  `assert_false`
- **Builtin types**:
  - `Int`, `String`, `Unit`, `Bool`, 
  - `Array`, `Map`, `Set`, `Option`, `Result`, `Json`, `Iterator`, `Iter`, `Iter2`, `Failure`
  - See detail `cat ~/.moon/lib/core/prelude/pkg.generated.mbti`
  - `T?` is `Option[T]` shorthand
- Core libraries with `@` namespace: `@hashmap`, `@json`, `@math`, etc.
  - See details `ls --only-dirs ~/.moon/lib/core/` and thoses `pkg.generated.mbti`

## Library References

### Adding Dependencies

Add libraries in `moon.pkg.json`:

```json
{
  "import": [
    "username/package"
  ]
}
```

### Finding API Documentation

**Core library**: Check `~/.moon/lib/core/**/*.mbti` files
- Example: `~/.moon/lib/core/hashmap/hashmap.mbti`
- `.mbti` files contain type signatures and public APIs

**Third-party libraries**: Check `.mooncakes/**/*.mbti` files
- Installed packages are cached in project's `.mooncakes/` directory
- Browse package structure and `.mbti` files for API reference

```bash
# Find core library APIs
ls ~/.moon/lib/core/
cat ~/.moon/lib/core/hashmap/hashmap.mbti

# Find third-party library APIs
ls .mooncakes/
cat .mooncakes/username/package/lib.mbti
```

## Testing

```moonbit

///|
fn sum(a : Int, b : Int) -> Int {
  a + b
}

///|
test "sum" {
  inspect(sum(2, 3), content="5")
}
```
