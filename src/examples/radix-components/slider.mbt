// Slider Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/slider.js" luna:trigger="load">
//     <div data-slider data-value="50" data-min="0" data-max="100" data-step="1"
//          role="slider" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
//          style="--slider-percent: 50;">
//       <div data-slider-track>
//         <div data-slider-range></div>
//       </div>
//       <div data-slider-thumb tabindex="0"></div>
//     </div>
//   </div>
//
// CSS uses --slider-percent for positioning:
//   [data-slider-range] { width: calc(var(--slider-percent) * 1%); }
//   [data-slider-thumb] { left: calc(var(--slider-percent) * 1%); }

///|
/// Slider props
pub(all) struct SliderProps {
  id : String
  value : Int
  min : Int
  max : Int
  step : Int
  hydration_url : String
}

///|
/// Create a slider component
fn slider_inner(
  value : Int,
  min : Int,
  max : Int,
  step : Int,
) -> @luna.Node[Unit] {
  let percent = (value - min) * 100 / (max - min)
  @element.div(
    attrs=[
      ("data-slider", @luna.attr_static("")),
      ("data-value", @luna.attr_static(value.to_string())),
      ("data-min", @luna.attr_static(min.to_string())),
      ("data-max", @luna.attr_static(max.to_string())),
      ("data-step", @luna.attr_static(step.to_string())),
      ("role", @luna.attr_static("slider")),
      ("aria-valuenow", @luna.attr_static(value.to_string())),
      ("aria-valuemin", @luna.attr_static(min.to_string())),
      ("aria-valuemax", @luna.attr_static(max.to_string())),
      ("style", @luna.attr_static("--slider-percent: " + percent.to_string())),
    ],
    [
      @element.div(attrs=[("data-slider-track", @luna.attr_static(""))], [
        @element.div(attrs=[("data-slider-range", @luna.attr_static(""))], []),
      ]),
      @element.div(
        attrs=[
          ("data-slider-thumb", @luna.attr_static("")),
          ("tabindex", @luna.attr_static("0")),
        ],
        [],
      ),
    ],
  )
}

///|
/// Create a slider component with hydration
pub fn slider(props : SliderProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [slider_inner(props.value, props.min, props.max, props.step)],
    trigger=@luna.Load,
  )
}

///|
/// Create a slider without island wrapper
pub fn slider_static(
  value : Int,
  min : Int,
  max : Int,
  step : Int,
) -> @luna.Node[Unit] {
  slider_inner(value, min, max, step)
}
