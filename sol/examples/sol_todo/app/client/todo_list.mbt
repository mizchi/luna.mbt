///| Todo List Client Island

///| Simple interactive counter to demonstrate hydration

///|
/// Props for the todo stats island
pub(all) struct TodoListProps {
  total : Int
  completed : Int
} derive(ToJson, FromJson)

///|
/// Todo stats island - shows count with live updates
pub fn todo_list(props : TodoListProps) -> DomNode {
  let total = @signal.signal(props.total)
  let completed = @signal.signal(props.completed)

  div(class="stats-island", [
    div(class="stat-row", [
      span(class="stat-label", [text("Total: ")]),
      span(class="stat-value", [text_of(total)]),
    ]),
    div(class="stat-row", [
      span(class="stat-label", [text("Completed: ")]),
      span(class="stat-value", [text_of(completed)]),
    ]),
    div(class="stat-actions", [
      button(
        class="btn refresh-btn",
        on=events().click(
          // Reload stats from server
          _ => refresh_stats(total, completed),
        ),
        [text("Refresh Stats")],
      ),
    ]),
  ])
}

///|
/// Fetch updated stats from server
fn refresh_stats(
  total : @signal.Signal[Int],
  completed : @signal.Signal[Int],
) -> Unit {
  ffi_fetch_stats(fn(t, c) {
    total.set(t)
    completed.set(c)
  })
}

///|
/// FFI to fetch stats
extern "js" fn ffi_fetch_stats(callback : (Int, Int) -> Unit) -> Unit =
  #| (callback) => {
  #|   fetch('/api/todos')
  #|     .then(r => r.json())
  #|     .then(data => {
  #|       const total = data.todos ? data.todos.length : 0;
  #|       const completed = data.todos ? data.todos.filter(t => t.completed).length : 0;
  #|       callback(total, completed);
  #|     })
  #|     .catch(err => console.error('Failed to fetch stats:', err));
  #| }
