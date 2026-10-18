///|
/// Tests for hash utility functions (fnv_hash.mbt and hash.mbt)

///|
test "fnv1a - empty string produces offset basis hex" {
  // FNV-1a offset basis for 32-bit is 2166136261 = 0x811c9dc5
  let hash = @cache.fnv1a("")
  assert_eq(hash, "811c9dc5")
}

///|
test "fnv1a - known value for 'a'" {
  // FNV-1a("a") = (2166136261 ^ 97) * 16777619 = 0xe40c292c
  let hash = @cache.fnv1a("a")
  assert_eq(hash, "e40c292c")
}

///|
test "fnv1a - deterministic across calls" {
  let h1 = @cache.fnv1a("hello world")
  let h2 = @cache.fnv1a("hello world")
  assert_eq(h1, h2)
}

///|
test "fnv1a - different inputs produce different hashes" {
  assert_true(@cache.fnv1a("foo") != @cache.fnv1a("bar"))
  assert_true(@cache.fnv1a("abc") != @cache.fnv1a("ABC"))
}

///|
test "fnv1a - result is 8 hex characters" {
  let hash = @cache.fnv1a("test")
  assert_eq(hash.length(), 8)
}

///|
test "fnv1a_64 - empty string produces offset basis hex" {
  // FNV-1a-64 offset basis is 14695981039346656037 = 0xcbf29ce484222325
  let hash = @cache.fnv1a_64("")
  assert_eq(hash, "cbf29ce484222325")
}

///|
test "fnv1a_64 - deterministic across calls" {
  let h1 = @cache.fnv1a_64("hello world")
  let h2 = @cache.fnv1a_64("hello world")
  assert_eq(h1, h2)
}

///|
test "fnv1a_64 - different inputs produce different hashes" {
  assert_true(@cache.fnv1a_64("foo") != @cache.fnv1a_64("bar"))
}

///|
test "fnv1a_64 - result is 16 hex characters" {
  let hash = @cache.fnv1a_64("test")
  assert_eq(hash.length(), 16)
}

///|
test "hash_strings - joins with null separator before hashing" {
  // hash_strings(["a", "b"]) should equal fnv1a("a\x00b")
  let expected = @cache.fnv1a("a\u0000b")
  let result = @cache.hash_strings(["a", "b"])
  assert_eq(result, expected)
}

///|
test "hash_strings - empty array produces hash of empty string" {
  let result = @cache.hash_strings([])
  assert_eq(result, @cache.fnv1a(""))
}

///|
test "hash_strings - single element" {
  let result = @cache.hash_strings(["hello"])
  assert_eq(result, @cache.fnv1a("hello"))
}

///|
test "hash_strings - order matters" {
  let h1 = @cache.hash_strings(["a", "b", "c"])
  let h2 = @cache.hash_strings(["c", "b", "a"])
  assert_true(h1 != h2)
}

///|
test "hash_content - combines content and context with null separator" {
  let expected = @cache.fnv1a("content\u0000/path/to/file.md")
  let result = @cache.hash_content("content", "/path/to/file.md")
  assert_eq(result, expected)
}

///|
test "hash_content - same content different context differs" {
  let h1 = @cache.hash_content("same content", "context-a")
  let h2 = @cache.hash_content("same content", "context-b")
  assert_true(h1 != h2)
}

///|
test "compute_page_hash - deterministic" {
  let h1 = @cache.compute_page_hash("# Hello", "{\"tags\":[]}", "cfg-abc")
  let h2 = @cache.compute_page_hash("# Hello", "{\"tags\":[]}", "cfg-abc")
  assert_eq(h1, h2)
}

///|
test "compute_page_hash - different source changes hash" {
  let h1 = @cache.compute_page_hash("# Hello", "{}", "cfg")
  let h2 = @cache.compute_page_hash("# World", "{}", "cfg")
  assert_true(h1 != h2)
}

///|
test "compute_page_hash - different frontmatter changes hash" {
  let h1 = @cache.compute_page_hash("source", "{\"title\":\"A\"}", "cfg")
  let h2 = @cache.compute_page_hash("source", "{\"title\":\"B\"}", "cfg")
  assert_true(h1 != h2)
}

///|
test "compute_page_hash - different config_hash changes hash" {
  let h1 = @cache.compute_page_hash("source", "{}", "config-v1")
  let h2 = @cache.compute_page_hash("source", "{}", "config-v2")
  assert_true(h1 != h2)
}
