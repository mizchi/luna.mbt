///| Whitebox tests for Experimental Hydration - internal coverage

///|
test "ExperimentalHydrationResult Failed variant" {
  // Test that Failed variant can be constructed and matched
  let result : ExperimentalHydrationResult = Failed("Test error message")
  match result {
    Failed(msg) => assert_eq(msg, "Test error message")
    _ => assert_true(false)
  }
}

///|
test "ExperimentalHydrationResult all variants" {
  // Clean variant
  let clean : ExperimentalHydrationResult = Clean
  match clean {
    Clean => assert_true(true)
    _ => assert_true(false)
  }

  // Repaired variant
  let repaired : ExperimentalHydrationResult = Repaired(["repair1", "repair2"])
  match repaired {
    Repaired(repairs) => assert_eq(repairs.length(), 2)
    _ => assert_true(false)
  }

  // Failed variant
  let failed : ExperimentalHydrationResult = Failed("error")
  match failed {
    Failed(err) => assert_eq(err, "error")
    _ => assert_true(false)
  }
}
