// Counter Client Component
// Client components receive Props and return DomNode.

///|
/// Props passed from server
pub(all) struct CounterProps {
  initial_count : Int
} derive(ToJson, FromJson)

///|
/// Counter component
pub fn counter(props : CounterProps) -> DomNode {
  let count = @signal.signal(props.initial_count)
  div(class="counter", [
    span(class="count-display", [text_of(count)]),
    div(class="buttons", [
      button(class="dec", on=events().click(_ => count.update(n => n - 1)), [
        text("-"),
      ]),
      button(class="inc", on=events().click(_ => count.update(n => n + 1)), [
        text("+"),
      ]),
    ]),
  ])
}
