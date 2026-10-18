///|
test "linear and cubic easing interpolate known values" {
  assert_eq(@easing.linear(0.25), 0.25)
  assert_eq(@easing.cubic_out(0.5), 0.875)
}

///|
test "all easings have finite samples and exact endpoints within tolerance" {
  let easings : Array[(Double) -> Double] = [
    @easing.linear, @easing.quad_in, @easing.quad_out, @easing.quad_in_out, @easing.cubic_in,
    @easing.cubic_out, @easing.cubic_in_out, @easing.quart_in, @easing.quart_out,
    @easing.quart_in_out, @easing.quint_in, @easing.quint_out, @easing.quint_in_out,
    @easing.sine_in, @easing.sine_out, @easing.sine_in_out, @easing.circ_in, @easing.circ_out,
    @easing.circ_in_out, @easing.expo_in, @easing.expo_out, @easing.expo_in_out,
    @easing.back_in, @easing.back_out, @easing.back_in_out, @easing.elastic_in, @easing.elastic_out,
    @easing.elastic_in_out, @easing.bounce_in, @easing.bounce_out, @easing.bounce_in_out,
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
  assert_eq(@easing.to_css(@easing.linear, samples=2), "linear(0, 0.5, 1)")
  assert_true(@easing.back_out(0.7) > 1.0)
  assert_true(@easing.to_css(@easing.back_out, samples=10).contains("1.080"))
  try @easing.to_css(@easing.linear, samples=1) catch {
    _ => ()
  } noraise {
    _ => fail("expected error")
  }
  try @easing.to_css(fn(_) { 1.0 / 0.0 }) catch {
    _ => ()
  } noraise {
    _ => fail("expected error")
  }
}
