// Progress Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/progress.js" luna:trigger="load">
//     <div data-progress role="progressbar"
//          aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
//          data-value="50" data-max="100"
//          style="--progress-percent: 50;">
//       <div data-progress-indicator style="width: calc(var(--progress-percent) * 1%);"></div>
//     </div>
//   </div>

///|
/// Progress props
pub(all) struct ProgressProps {
  id : String
  value : Int
  max : Int
  hydration_url : String
}

///|
/// Create a progress component
fn progress_inner(value : Int, max : Int) -> @luna.Node[Unit] {
  let percent = value * 100 / max
  let state = if value >= max {
    "complete"
  } else if value > 0 {
    "loading"
  } else {
    "indeterminate"
  }
  @element.div(
    attrs=[
      ("data-progress", @luna.attr_static("")),
      ("role", @luna.attr_static("progressbar")),
      ("aria-valuenow", @luna.attr_static(value.to_string())),
      ("aria-valuemin", @luna.attr_static("0")),
      ("aria-valuemax", @luna.attr_static(max.to_string())),
      ("data-value", @luna.attr_static(value.to_string())),
      ("data-max", @luna.attr_static(max.to_string())),
      ("data-state", @luna.attr_static(state)),
      ("style", @luna.attr_static("--progress-percent: " + percent.to_string())),
    ],
    [
      @element.div(
        attrs=[
          ("data-progress-indicator", @luna.attr_static("")),
          (
            "style",
            @luna.attr_static("width: calc(var(--progress-percent) * 1%)"),
          ),
        ],
        [],
      ),
    ],
  )
}

///|
/// Create a progress component with hydration
pub fn progress(props : ProgressProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [progress_inner(props.value, props.max)],
    trigger=@luna.Load,
  )
}

///|
/// Create a progress without island wrapper
pub fn progress_static(value : Int, max : Int) -> @luna.Node[Unit] {
  progress_inner(value, max)
}
