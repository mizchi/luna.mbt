///|
test "linear and cubic easing interpolate known values" {
  assert_eq(linear(0.25), 0.25)
  assert_eq(cubic_out(0.5), 0.875)
}

///|
test "all easings have finite samples and exact endpoints within tolerance" {
  let easings : Array[(Double) -> Double] = [
    linear, quad_in, quad_out, quad_in_out, cubic_in, cubic_out, cubic_in_out, quart_in,
    quart_out, quart_in_out, quint_in, quint_out, quint_in_out, sine_in, sine_out,
    sine_in_out, circ_in, circ_out, circ_in_out, expo_in, expo_out, expo_in_out,
    back_in, back_out, back_in_out, elastic_in, elastic_out, elastic_in_out, bounce_in,
    bounce_out, bounce_in_out,
  ]
  for easing in easings {
    assert_true(easing(0.0).abs() < 0.000001)
    assert_true((easing(1.0) - 1.0).abs() < 0.000001)
    for i in 0..<=100 {
      let v = easing(i.to_double() / 100.0)
      assert_true(v == v && v.abs() < 10.0)
    }
  }
}

///|
test "CSS sampling preserves overshoot and rejects invalid input" {
  assert_eq(to_css(linear, samples=2), "linear(0, 0.5, 1)")
  assert_true(back_out(0.7) > 1.0)
  assert_true(to_css(back_out, samples=10).contains("1.080"))
  try to_css(linear, samples=1) catch {
    _ => ()
  } noraise {
    _ => fail("expected error")
  }
  try to_css(fn(_) { 1.0 / 0.0 }) catch {
    _ => ()
  } noraise {
    _ => fail("expected error")
  }
}
