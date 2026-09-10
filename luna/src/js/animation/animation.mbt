///|
/// A layout snapshot in viewport coordinates.
pub(all) struct Rect {
  left : Double
  top : Double
  width : Double
  height : Double
} derive(Debug, Eq)

///|
#external
pub type Keyframe

///|
#external
pub type Animation

///|
/// Native KeyframeAnimationOptions. Construct with Options::new in MoonBit.
#external
pub type Options

///|
pub(all) enum Fill {
  None
  Forwards
  Backwards
  Both
}

///|
pub extern "js" fn Keyframe::new() -> Keyframe =
  #| () => ({})

///|
/// Return a new keyframe with a typed CSS property. Values use CSS syntax.
pub fn Keyframe::set(
  self : Keyframe,
  property : @css.Property,
  value : String,
) -> Keyframe {
  set_property(self, property.css_name(), value)
}

///|
extern "js" fn set_property(
  frame : Keyframe,
  property : String,
  value : String,
) -> Keyframe =
  #| (frame, property, value) => {
  #|   const name = property.startsWith('--') ? property : property.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
  #|   return { ...frame, [name]: value };
  #| }

///|
pub extern "js" fn Keyframe::offset(
  self : Keyframe,
  offset : Double,
) -> Keyframe =
  #| (frame, offset) => {
  #|   if (!Number.isFinite(offset) || offset < 0 || offset > 1) throw new RangeError('offset must be in [0, 1]');
  #|   return { ...frame, offset };
  #| }

///|
pub fn Options::new(
  duration? : Double = 300.0,
  delay? : Double = 0.0,
  easing? : String = "linear",
  fill? : Fill = None,
) -> Options {
  let fill = match fill {
    None => "none"
    Forwards => "forwards"
    Backwards => "backwards"
    Both => "both"
  }
  make_options(duration, delay, easing, fill)
}

///|
extern "js" fn make_options(
  duration : Double,
  delay : Double,
  easing : String,
  fill : String,
) -> Options =
  #| (duration, delay, easing, fill) => ({ duration, delay, easing, fill })

///|
/// Play native keyframes. Browser globals are accessed only when called.
/// Cancellation keeps native semantics: finished rejects with AbortError.
pub fn play(
  element : @dom.Element,
  frames : Array[Keyframe],
  options : Options,
  respect_reduced_motion? : Bool = true,
) -> Animation {
  play_native(
    element,
    FixedArray::from_array(frames[:]),
    options,
    respect_reduced_motion,
  )
}

///|
extern "js" fn play_native(
  element : @dom.Element,
  frames : FixedArray[Keyframe],
  options : Options,
  respect_reduced_motion : Bool,
) -> Animation =
  #| (element, frames, options, respectReducedMotion) => {
  #|   if (typeof element.animate !== 'function') throw new Error('Web Animations API is not available');
  #|   const view = element.ownerDocument.defaultView;
  #|   const reduced = respectReducedMotion && view?.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  #|   return element.animate(frames, reduced ? { ...options, duration: 0, delay: 0, endDelay: 0, iterations: 1 } : options);
  #| }

///|
/// Animate with a numerical easing, sampled once into native CSS linear().
pub fn animate(
  element : @dom.Element,
  frames : Array[Keyframe],
  duration? : Double = 300.0,
  delay? : Double = 0.0,
  easing? : (Double) -> Double = @easing.linear,
  fill? : Fill = None,
  respect_reduced_motion? : Bool = true,
) -> Animation raise @easing.InvalidSampling {
  play(
    element,
    frames,
    Options::new(duration~, delay~, easing=@easing.to_css(easing), fill~),
    respect_reduced_motion~,
  )
}

///|
pub fn measure(element : @dom.Element) -> Rect {
  let bounds = read_bounds(element)
  { left: bounds[0], top: bounds[1], width: bounds[2], height: bounds[3], }
}

///|
extern "js" fn read_bounds(element : @dom.Element) -> FixedArray[Double] =
  #| element => { const r = element.getBoundingClientRect(); return [r.left, r.top, r.width, r.height]; }

///|
/// Build translation-only FLIP frames without touching the DOM.
/// Layout must already be in its final state. Ancestor transforms are not compensated.
pub fn flip_frames(
  from : Rect,
  to : Rect,
  transform : String,
) -> Array[Keyframe] {
  let base = if transform == "none" || transform == "" {
    ""
  } else {
    " " + transform
  }
  let start = "translate(\{from.left - to.left}px, \{from.top - to.top}px)" +
    base
  [
    transform_frame(start),
    transform_frame(if transform == "" { "none" } else { transform }),
  ]
}

///|
/// Capture the current computed transform, preserving it in FLIP frames.
pub extern "js" fn computed_transform(element : @dom.Element) -> String =
  #| element => element.ownerDocument.defaultView.getComputedStyle(element).transform

///|
/// Animate a layout change from a previously captured rectangle.
pub fn flip(
  element : @dom.Element,
  from : Rect,
  duration? : Double = 300.0,
  delay? : Double = 0.0,
  easing? : (Double) -> Double = @easing.cubic_out,
  respect_reduced_motion? : Bool = true,
) -> Animation raise @easing.InvalidSampling {
  animate(
    element,
    flip_frames(from, measure(element), computed_transform(element)),
    duration~,
    delay~,
    easing~,
    fill=Backwards,
    respect_reduced_motion~,
  )
}

///|
pub extern "js" fn Animation::cancel(self : Animation) -> Unit =
  #| animation => animation.cancel()

///|
pub extern "js" fn Animation::pause(self : Animation) -> Unit =
  #| animation => animation.pause()

///|
pub extern "js" fn Animation::play(self : Animation) -> Unit =
  #| animation => animation.play()

///|
pub extern "js" fn Animation::reverse(self : Animation) -> Unit =
  #| animation => animation.reverse()

///|
pub extern "js" fn Animation::finish(self : Animation) -> Unit =
  #| animation => animation.finish()

///|
pub extern "js" fn Animation::seek(self : Animation, time : Double) -> Unit =
  #| (animation, time) => { animation.currentTime = time; }

///|
pub extern "js" fn Animation::finished(
  self : Animation,
) -> @js.Promise[Animation] =
  #| animation => animation.finished

///|
extern "js" fn transform_frame(transform : String) -> Keyframe =
  #| transform => ({ transform })
