// TodoMVC - LocalStorage Persistence

///|
let storage_key : String = "todos-luna"

///|
fn save_todos(todos : Array[Todo]) -> Unit {
  @storage.localStorage().setItem(storage_key, todos.to_json().stringify())
}

///|
fn load_todos() -> Array[Todo] {
  match @storage.localStorage().getItem(storage_key) {
    Some(str) => {
      let json = @json.parse(str) catch { _ => return [] }
      @json.from_json(json) catch {
        _ => []
      }
    }
    None => []
  }
}
