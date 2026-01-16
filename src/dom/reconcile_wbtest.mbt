// Whitebox tests for Reconcile - internal logic coverage
// These tests run in Node.js (no DOM), so they test pure logic only.
// DOM-dependent tests are in js/luna/tests/dom.test.ts
//

///|
/// Test ref_equal with same reference
test "ref_equal returns true for same reference" {
  let obj = Ref::new(42)
  assert_true(ref_equal(obj, obj))
}

///|
/// Test ref_equal with different references (same value)
test "ref_equal returns false for different references with same value" {
  let obj1 = Ref::new(42)
  let obj2 = Ref::new(42)
  // Different objects, even with same value, are not ref-equal
  assert_false(ref_equal(obj1, obj2))
}

///|
/// Test ref_equal with primitives
test "ref_equal with integers" {
  let a = 42
  let b = 42
  // Primitives with same value are ref-equal in JavaScript
  assert_true(ref_equal(a, b))
}

///|
/// Test ref_equal with strings
test "ref_equal with same string" {
  let s1 = "hello"
  let s2 = "hello"
  // String interning makes same strings ref-equal
  assert_true(ref_equal(s1, s2))
}

///|
/// Test ref_equal with different strings
test "ref_equal with different strings" {
  let s1 = "hello"
  let s2 = "world"
  assert_false(ref_equal(s1, s2))
}

///|
/// Test ref_equal with arrays (different references)
test "ref_equal with different array references" {
  let arr1 = [1, 2, 3]
  let arr2 = [1, 2, 3]
  // Different arrays are not ref-equal even with same content
  assert_false(ref_equal(arr1, arr2))
}

///|
/// Test ref_equal with same array reference
test "ref_equal with same array reference" {
  let arr = [1, 2, 3]
  assert_true(ref_equal(arr, arr))
}

///|
/// Test ref_equal with nested Ref objects
test "ref_equal with nested Ref objects" {
  let inner : Ref[Int] = Ref::new(1)
  let outer1 : Ref[Ref[Int]] = Ref::new(inner)
  let outer2 : Ref[Ref[Int]] = Ref::new(inner)
  // Different outers but same inner reference
  assert_false(ref_equal(outer1, outer2))
  assert_true(ref_equal(outer1.val, outer2.val))
}

///|
/// Test ref_equal with null-like values
test "ref_equal with None values" {
  let opt1 : Int? = None
  let opt2 : Int? = None
  // Both None should be ref-equal
  assert_true(ref_equal(opt1, opt2))
}

///|
/// Test ref_equal with Some values containing same reference
test "ref_equal with Some values" {
  let inner : Ref[Int] = Ref::new(42)
  let opt1 : Ref[Int]? = Some(inner)
  let opt2 : Ref[Int]? = Some(inner)
  // Same inner reference wrapped in Some
  // Note: This depends on MoonBit/JS semantics
  assert_true(ref_equal(opt1, opt2))
}

///|
/// Test ref_equal identity for function references
test "ref_equal with function references" {
  let f = fn(x : Int) { x + 1 }
  assert_true(ref_equal(f, f))
}

///|
/// Test ref_equal different functions
test "ref_equal with different functions" {
  let f1 = fn(x : Int) { x + 1 }
  let f2 = fn(x : Int) { x + 1 }
  // Different function objects, even with same body
  assert_false(ref_equal(f1, f2))
}

///|
/// Test ref_equal with empty arrays
test "ref_equal with empty arrays" {
  let arr1 : Array[Int] = []
  let arr2 : Array[Int] = []
  // Different empty arrays are not ref-equal
  assert_false(ref_equal(arr1, arr2))
}

///|
/// Test ref_equal with mutated array (same reference)
test "ref_equal after array mutation" {
  let arr = [1, 2, 3]
  let same = arr
  arr.push(4)
  // Still the same reference after mutation
  assert_true(ref_equal(arr, same))
}
