///|
/// An easing maps normalized time [0, 1] to progress. Back and elastic may overshoot.
pub fn linear(t : Double) -> Double {
  t
}

///|
pub fn quad_in(t : Double) -> Double {
  t * t
}

///|
pub fn quad_out(t : Double) -> Double {
  1.0 - quad_in(1.0 - t)
}

///|
pub fn quad_in_out(t : Double) -> Double {
  if t < 0.5 {
    quad_in(2.0 * t) / 2.0
  } else {
    0.5 + quad_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn cubic_in(t : Double) -> Double {
  t * t * t
}

///|
pub fn cubic_out(t : Double) -> Double {
  1.0 - cubic_in(1.0 - t)
}

///|
pub fn cubic_in_out(t : Double) -> Double {
  if t < 0.5 {
    cubic_in(2.0 * t) / 2.0
  } else {
    0.5 + cubic_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn quart_in(t : Double) -> Double {
  t * t * t * t
}

///|
pub fn quart_out(t : Double) -> Double {
  1.0 - quart_in(1.0 - t)
}

///|
pub fn quart_in_out(t : Double) -> Double {
  if t < 0.5 {
    quart_in(2.0 * t) / 2.0
  } else {
    0.5 + quart_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn quint_in(t : Double) -> Double {
  t * t * t * t * t
}

///|
pub fn quint_out(t : Double) -> Double {
  1.0 - quint_in(1.0 - t)
}

///|
pub fn quint_in_out(t : Double) -> Double {
  if t < 0.5 {
    quint_in(2.0 * t) / 2.0
  } else {
    0.5 + quint_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn sine_in(t : Double) -> Double {
  1.0 - @math.cos(t * @math.PI / 2.0)
}

///|
pub fn sine_out(t : Double) -> Double {
  1.0 - sine_in(1.0 - t)
}

///|
pub fn sine_in_out(t : Double) -> Double {
  if t < 0.5 {
    sine_in(2.0 * t) / 2.0
  } else {
    0.5 + sine_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn circ_in(t : Double) -> Double {
  1.0 - (1.0 - t * t).sqrt()
}

///|
pub fn circ_out(t : Double) -> Double {
  1.0 - circ_in(1.0 - t)
}

///|
pub fn circ_in_out(t : Double) -> Double {
  if t < 0.5 {
    circ_in(2.0 * t) / 2.0
  } else {
    0.5 + circ_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn expo_in(t : Double) -> Double {
  if t == 0.0 {
    0.0
  } else {
    @math.pow(2.0, 10.0 * (t - 1.0))
  }
}

///|
pub fn expo_out(t : Double) -> Double {
  1.0 - expo_in(1.0 - t)
}

///|
pub fn expo_in_out(t : Double) -> Double {
  if t < 0.5 {
    expo_in(2.0 * t) / 2.0
  } else {
    0.5 + expo_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn back_in(t : Double) -> Double {
  t * t * (2.70158 * t - 1.70158)
}

///|
pub fn back_out(t : Double) -> Double {
  1.0 - back_in(1.0 - t)
}

///|
pub fn back_in_out(t : Double) -> Double {
  if t < 0.5 {
    back_in(2.0 * t) / 2.0
  } else {
    0.5 + back_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn elastic_in(t : Double) -> Double {
  if t == 0.0 || t == 1.0 {
    t
  } else {
    -@math.pow(2.0, 10.0 * (t - 1.0)) *
    @math.sin((t - 1.075) * (2.0 * @math.PI) / 0.3)
  }
}

///|
pub fn elastic_out(t : Double) -> Double {
  1.0 - elastic_in(1.0 - t)
}

///|
pub fn elastic_in_out(t : Double) -> Double {
  if t < 0.5 {
    elastic_in(2.0 * t) / 2.0
  } else {
    0.5 + elastic_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub fn bounce_in(t : Double) -> Double {
  1.0 - bounce_out(1.0 - t)
}

///|
pub fn bounce_out(t : Double) -> Double {
  if t < 1.0 / 2.75 {
    7.5625 * t * t
  } else if t < 2.0 / 2.75 {
    let u = t - 1.5 / 2.75
    7.5625 * u * u + 0.75
  } else if t < 2.5 / 2.75 {
    let u = t - 2.25 / 2.75
    7.5625 * u * u + 0.9375
  } else {
    let u = t - 2.625 / 2.75
    7.5625 * u * u + 0.984375
  }
}

///|
pub fn bounce_in_out(t : Double) -> Double {
  if t < 0.5 {
    bounce_in(2.0 * t) / 2.0
  } else {
    0.5 + bounce_out(2.0 * t - 1.0) / 2.0
  }
}

///|
pub suberror InvalidSampling {
  InvalidSampling(String)
}

///|
/// Approximate an easing with evenly spaced CSS linear() stops.
/// samples is the number of intervals (2..4096); overshoot is preserved.
pub fn to_css(
  easing : (Double) -> Double,
  samples? : Int = 100,
) -> String raise InvalidSampling {
  if samples < 2 || samples > 4096 {
    raise InvalidSampling("samples must be between 2 and 4096")
  }
  let stops : Array[String] = []
  for i in 0..<=samples {
    let value = easing(i.to_double() / samples.to_double())
    if value - value != 0.0 {
      raise InvalidSampling("easing must return finite values")
    }
    stops.push(value.to_string())
  }
  "linear(" + stops.join(", ") + ")"
}
