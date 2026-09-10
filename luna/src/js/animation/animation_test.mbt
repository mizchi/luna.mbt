///|
test "FLIP computes translation and preserves the underlying transform" {
  let from : Rect = { left: 10.0, top: 20.0, width: 40.0, height: 30.0, }
  let to : Rect = { left: 110.0, top: 70.0, width: 40.0, height: 30.0, }
  let frames = flip_frames(from, to, "rotate(10deg)")
  assert_eq(read_transform(frames[0]), "translate(-100px, -50px) rotate(10deg)")
  assert_eq(read_transform(frames[1]), "rotate(10deg)")
}

///|
extern "js" fn read_transform(frame : Keyframe) -> String =
  #| frame => frame.transform

///|
test "typed keyframes use WAAPI names without mutating the original" {
  let initial = Keyframe::new().set(BackgroundColor, "red")
  let next = initial.set(BackgroundColor, "blue").offset(0.5)
  assert_eq(read_color(initial), "red")
  assert_eq(read_color(next), "blue")
}

///|
extern "js" fn read_color(frame : Keyframe) -> String =
  #| frame => frame.backgroundColor
