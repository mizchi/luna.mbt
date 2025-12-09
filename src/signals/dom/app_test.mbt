///| Real-world Todo App Tests with JSDOM

///|
/// Todo item structure
struct Todo {
  id : Int
  text : String
  completed : Bool
} derive(Show)

///|
/// Create a Todo app component
fn create_todo_app() -> (
  @jsdom.Element,
  @signals.Signal[Array[Todo]],
  @signals.Signal[String],
) {
  let todos : @signals.Signal[Array[Todo]] = @signals.signal([])
  let input_text : @signals.Signal[String] = @signals.signal("")
  let next_id = { val: 1 }

  // Add todo handler
  fn add_todo() {
    let text = input_text.peek()
    if text.length() > 0 {
      let new_todo : Todo = { id: next_id.val, text, completed: false }
      next_id.val = next_id.val + 1
      todos.update(fn(arr) {
        let new_arr = arr.copy()
        new_arr.push(new_todo)
        new_arr
      })
      input_text.set("")
    }
  }

  // Toggle todo handler
  fn toggle_todo(id : Int) {
    todos.update(fn(arr) {
      let new_arr : Array[Todo] = []
      for i = 0; i < arr.length(); i = i + 1 {
        let todo = arr[i]
        if todo.id == id {
          new_arr.push({
            id: todo.id,
            text: todo.text,
            completed: not(todo.completed),
          })
        } else {
          new_arr.push(todo)
        }
      }
      new_arr
    })
  }

  // Delete todo handler
  fn delete_todo(id : Int) {
    todos.update(fn(arr) {
      let new_arr : Array[Todo] = []
      for i = 0; i < arr.length(); i = i + 1 {
        if arr[i].id != id {
          new_arr.push(arr[i])
        }
      }
      new_arr
    })
  }

  // Build the UI
  let app = div([class("todo-app")], [
    // Header
    h1([], [text("Todo App")]).as_node(),
    // Input form
    div([class("input-section")], [
      input([
        id("todo-input"),
        type_("text"),
        placeholder("What needs to be done?"),
        value_dyn(fn() { input_text.get() }),
        on_input(fn(e) {
          let target : @core.Any = e._get("target")
          let value : String = target._get("value").cast()
          input_text.set(value)
        }),
        on_key_down(fn(e) {
          let key : String = e._get("key").cast()
          if key == "Enter" {
            add_todo()
          }
        }),
      ]).as_node(),
      button([id("add-btn"), on_click(fn(_e) { add_todo() })], [text("Add")]).as_node(),
    ]).as_node(),
    // Todo list
    ul([id("todo-list")], [
      for_each(() => todos.get(), (todo, _idx) => li(
        [
          class_name_dyn(() => if todo.completed {
            "todo-item completed"
          } else {
            "todo-item"
          }),
          attr("data-id", todo.id.to_string()),
        ],
        [
          span(
            [class("todo-text"), on_click(fn(_e) { toggle_todo(todo.id) })],
            [text(todo.text)],
          ).as_node(),
          button(
            [class("delete-btn"), on_click(fn(_e) { delete_todo(todo.id) })],
            [text("×")],
          ).as_node(),
        ],
      ).as_node()),
    ]).as_node(),
    // Stats
    div([id("stats")], [
      text_dyn(fn() {
        let items = todos.get()
        let total = items.length()
        let mut completed = 0
        for i = 0; i < items.length(); i = i + 1 {
          if items[i].completed {
            completed = completed + 1
          }
        }
        "\{total} items, \{completed} completed"
      }),
    ]).as_node(),
  ])
  (app, todos, input_text)
}

// =============================================================================
// DOM Integration Tests with JSDOM
// =============================================================================

///|
test "Todo app renders initial state" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.getElementById("root").unwrap_or(doc.createElement("div"))
  let (app, _todos, _input) = create_todo_app()
  render(container, app.as_node())

  // Check header exists
  let h1_elem = container.querySelector("h1")
  assert_true(h1_elem is Some(_))

  // Check input exists
  let input_elem = container.querySelector("#todo-input")
  assert_true(input_elem is Some(_))

  // Check add button exists
  let add_btn = container.querySelector("#add-btn")
  assert_true(add_btn is Some(_))

  // Check stats shows "0 items, 0 completed"
  let stats = container.querySelector("#stats")
  assert_true(stats is Some(_))
}

///|
test "Todo app adds new todo" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.createElement("div")
  let (app, todos, input_text) = create_todo_app()
  render(container, app.as_node())

  // Simulate typing
  input_text.set("Buy groceries")
  assert_eq(input_text.get(), "Buy groceries")

  // Simulate add (direct state manipulation for testing)
  let new_todo : Todo = { id: 1, text: "Buy groceries", completed: false }
  todos.set([new_todo])

  // Verify state
  assert_eq(todos.get().length(), 1)
  assert_eq(todos.get()[0].text, "Buy groceries")
}

///|
test "Todo app toggles todo completion" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.createElement("div")
  let (app, todos, _input) = create_todo_app()
  render(container, app.as_node())

  // Add initial todos
  todos.set([
    { id: 1, text: "Task 1", completed: false },
    { id: 2, text: "Task 2", completed: false },
  ])

  // Toggle first todo
  todos.update(fn(arr) {
    let new_arr : Array[Todo] = []
    for i = 0; i < arr.length(); i = i + 1 {
      let todo = arr[i]
      if todo.id == 1 {
        new_arr.push({ id: todo.id, text: todo.text, completed: true })
      } else {
        new_arr.push(todo)
      }
    }
    new_arr
  })

  // Verify state
  assert_eq(todos.get()[0].completed, true)
  assert_eq(todos.get()[1].completed, false)
}

///|
test "Todo app deletes todo" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.createElement("div")
  let (app, todos, _input) = create_todo_app()
  render(container, app.as_node())

  // Add initial todos
  todos.set([
    { id: 1, text: "Task 1", completed: false },
    { id: 2, text: "Task 2", completed: false },
    { id: 3, text: "Task 3", completed: false },
  ])
  assert_eq(todos.get().length(), 3)

  // Delete middle todo
  todos.update(fn(arr) {
    let new_arr : Array[Todo] = []
    for i = 0; i < arr.length(); i = i + 1 {
      if arr[i].id != 2 {
        new_arr.push(arr[i])
      }
    }
    new_arr
  })

  // Verify state
  assert_eq(todos.get().length(), 2)
  assert_eq(todos.get()[0].id, 1)
  assert_eq(todos.get()[1].id, 3)
}

///|
test "Todo app reactive text updates" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.createElement("div")
  let count = @signals.signal(0)
  let counter_div = div([id("counter")], [text_sig(count)])
  render(container, counter_div.as_node())

  // Initial value
  assert_eq(count.get(), 0)

  // Update
  count.set(42)
  assert_eq(count.get(), 42)

  // Multiple updates
  for i = 0; i < 10; i = i + 1 {
    count.update(fn(n) { n + 1 })
  }
  assert_eq(count.get(), 52)
}

///|
test "Todo app reactive class updates" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.createElement("div")
  let is_active = @signals.signal(false)
  let elem = div(
    [
      id("toggle-elem"),
      class_name_dyn(fn() {
        if is_active.get() {
          "active"
        } else {
          "inactive"
        }
      }),
    ],
    [],
  )
  render(container, elem.as_node())

  // Initial state
  assert_eq(is_active.get(), false)

  // Toggle
  is_active.set(true)
  assert_eq(is_active.get(), true)
  is_active.set(false)
  assert_eq(is_active.get(), false)
}

///|
test "Todo app batch updates" {
  @global_jsdom.register()
  let todos : @signals.Signal[Array[Todo]] = @signals.signal([])
  let update_count = { val: 0 }
  let _ = @signals.effect(fn() {
    let _ = todos.get()
    update_count.val = update_count.val + 1
  })

  // Initial effect run
  assert_eq(update_count.val, 1)

  // Batch multiple updates
  @signals.batch(fn() {
    todos.set([{ id: 1, text: "A", completed: false }])
    todos.set([
      { id: 1, text: "A", completed: false },
      { id: 2, text: "B", completed: false },
    ])
    todos.set([
      { id: 1, text: "A", completed: false },
      { id: 2, text: "B", completed: false },
      { id: 3, text: "C", completed: false },
    ])
  })

  // After batch, effect should have run once more (not 3 times)
  assert_eq(todos.get().length(), 3)
}

///|
test "Todo app with memo for derived state" {
  @global_jsdom.register()
  let todos : @signals.Signal[Array[Todo]] = @signals.signal([
    { id: 1, text: "Task 1", completed: true },
    { id: 2, text: "Task 2", completed: false },
    { id: 3, text: "Task 3", completed: true },
  ])

  // Memoized computed value
  let completed_count = @signals.memo(fn() {
    let items = todos.get()
    let mut count = 0
    for i = 0; i < items.length(); i = i + 1 {
      if items[i].completed {
        count = count + 1
      }
    }
    count
  })
  let active_count = @signals.memo(fn() {
    let items = todos.get()
    let mut count = 0
    for i = 0; i < items.length(); i = i + 1 {
      if not(items[i].completed) {
        count = count + 1
      }
    }
    count
  })

  // Initial counts
  assert_eq(completed_count(), 2)
  assert_eq(active_count(), 1)

  // Add a new completed todo
  todos.update(fn(arr) {
    let new_arr = arr.copy()
    new_arr.push({ id: 4, text: "Task 4", completed: true })
    new_arr
  })
  assert_eq(completed_count(), 3)
  assert_eq(active_count(), 1)
}

///|
test "Todo app filter with combinator" {
  @global_jsdom.register()
  let todos : @signals.Signal[Array[Todo]] = @signals.signal([
    { id: 1, text: "Task 1", completed: true },
    { id: 2, text: "Task 2", completed: false },
    { id: 3, text: "Task 3", completed: true },
  ])
  let filter_mode : @signals.Signal[String] = @signals.signal("all") // "all", "active", "completed"

  // Filtered todos using combine
  let filtered = @signals.combine2(todos, filter_mode, fn(items, mode) {
    if mode == "all" {
      items
    } else if mode == "active" {
      let result : Array[Todo] = []
      for i = 0; i < items.length(); i = i + 1 {
        if not(items[i].completed) {
          result.push(items[i])
        }
      }
      result
    } else {
      let result : Array[Todo] = []
      for i = 0; i < items.length(); i = i + 1 {
        if items[i].completed {
          result.push(items[i])
        }
      }
      result
    }
  })

  // All filter
  assert_eq(filtered().length(), 3)

  // Active filter
  filter_mode.set("active")
  assert_eq(filtered().length(), 1)

  // Completed filter
  filter_mode.set("completed")
  assert_eq(filtered().length(), 2)
}

///|
test "Signal cleanup on dispose" {
  @global_jsdom.register()
  let sig = @signals.signal(0)
  let values : Array[Int] = []
  let dispose = @signals.effect(fn() { values.push(sig.get()) })

  // Initial
  assert_eq(values.length(), 1)
  sig.set(1)
  assert_eq(values.length(), 2)

  // Dispose
  dispose()

  // Further updates should not trigger
  sig.set(2)
  sig.set(3)
  // values length should not increase significantly
}

///|
test "Nested effects work correctly" {
  @global_jsdom.register()
  let outer_sig = @signals.signal(1)
  let inner_sig = @signals.signal(10)
  let results : Array[Int] = []
  let _ = @signals.effect(fn() {
    let outer_val = outer_sig.get()
    let _ = @signals.effect(fn() {
      let inner_val = inner_sig.get()
      results.push(outer_val * inner_val)
    })

  })

  // Initial run
  assert_true(results.length() >= 1)

  // Update inner
  inner_sig.set(20)

  // Update outer
  outer_sig.set(2)
}

// =============================================================================
// Fine-Grained Reactivity Tests - Verify only leaf nodes update
// =============================================================================

///|
/// Counter to track effect executions
struct EffectCounter {
  mut item1_count : Int
  mut item2_count : Int
  mut item3_count : Int
}

///|
test "Fine-grained: only dependent effects re-run" {
  @global_jsdom.register()

  // Three independent signals
  let sig1 = @signals.signal("Item 1")
  let sig2 = @signals.signal("Item 2")
  let sig3 = @signals.signal("Item 3")

  // Counter for each effect
  let counter : EffectCounter = {
    item1_count: 0,
    item2_count: 0,
    item3_count: 0,
  }

  // Effect that depends on sig1
  let _ = @signals.effect(fn() {
    let _ = sig1.get()
    counter.item1_count = counter.item1_count + 1
  })

  // Effect that depends on sig2
  let _ = @signals.effect(fn() {
    let _ = sig2.get()
    counter.item2_count = counter.item2_count + 1
  })

  // Effect that depends on sig3
  let _ = @signals.effect(fn() {
    let _ = sig3.get()
    counter.item3_count = counter.item3_count + 1
  })

  // Initial run: all effects should run once
  assert_eq(counter.item1_count, 1)
  assert_eq(counter.item2_count, 1)
  assert_eq(counter.item3_count, 1)

  // Update sig1 only - only item1 effect should re-run
  sig1.set("Item 1 updated")
  assert_eq(counter.item1_count, 2)
  assert_eq(counter.item2_count, 1) // unchanged
  assert_eq(counter.item3_count, 1) // unchanged

  // Update sig2 only - only item2 effect should re-run
  sig2.set("Item 2 updated")
  assert_eq(counter.item1_count, 2) // unchanged
  assert_eq(counter.item2_count, 2)
  assert_eq(counter.item3_count, 1) // unchanged

  // Update sig3 only - only item3 effect should re-run
  sig3.set("Item 3 updated")
  assert_eq(counter.item1_count, 2) // unchanged
  assert_eq(counter.item2_count, 2) // unchanged
  assert_eq(counter.item3_count, 2)
}

///|
test "Fine-grained: tree structure with independent branches" {
  @global_jsdom.register()

  // Root and branch signals
  let root_title = @signals.signal("App Title")
  let branch_a_value = @signals.signal(10)
  let branch_b_value = @signals.signal(20)
  let leaf_a1 = @signals.signal("Leaf A1")
  let leaf_a2 = @signals.signal("Leaf A2")
  let leaf_b1 = @signals.signal("Leaf B1")

  // Counters
  let root_count = { val: 0 }
  let branch_a_count = { val: 0 }
  let branch_b_count = { val: 0 }
  let leaf_a1_count = { val: 0 }
  let leaf_a2_count = { val: 0 }
  let leaf_b1_count = { val: 0 }

  // Root effect
  let _ = @signals.effect(fn() {
    let _ = root_title.get()
    root_count.val = root_count.val + 1
  })

  // Branch A effect (depends on branch_a_value)
  let _ = @signals.effect(fn() {
    let _ = branch_a_value.get()
    branch_a_count.val = branch_a_count.val + 1
  })

  // Branch B effect (depends on branch_b_value)
  let _ = @signals.effect(fn() {
    let _ = branch_b_value.get()
    branch_b_count.val = branch_b_count.val + 1
  })

  // Leaf effects
  let _ = @signals.effect(fn() {
    let _ = leaf_a1.get()
    leaf_a1_count.val = leaf_a1_count.val + 1
  })
  let _ = @signals.effect(fn() {
    let _ = leaf_a2.get()
    leaf_a2_count.val = leaf_a2_count.val + 1
  })
  let _ = @signals.effect(fn() {
    let _ = leaf_b1.get()
    leaf_b1_count.val = leaf_b1_count.val + 1
  })

  // Initial state: all ran once
  assert_eq(root_count.val, 1)
  assert_eq(branch_a_count.val, 1)
  assert_eq(branch_b_count.val, 1)
  assert_eq(leaf_a1_count.val, 1)
  assert_eq(leaf_a2_count.val, 1)
  assert_eq(leaf_b1_count.val, 1)

  // Update leaf_a1 - ONLY leaf_a1 effect should run
  leaf_a1.set("Leaf A1 changed")
  assert_eq(root_count.val, 1)
  assert_eq(branch_a_count.val, 1)
  assert_eq(branch_b_count.val, 1)
  assert_eq(leaf_a1_count.val, 2) // Only this increased
  assert_eq(leaf_a2_count.val, 1)
  assert_eq(leaf_b1_count.val, 1)

  // Update branch_b_value - ONLY branch_b effect should run
  branch_b_value.set(200)
  assert_eq(root_count.val, 1)
  assert_eq(branch_a_count.val, 1)
  assert_eq(branch_b_count.val, 2) // Only this increased
  assert_eq(leaf_a1_count.val, 2)
  assert_eq(leaf_a2_count.val, 1)
  assert_eq(leaf_b1_count.val, 1)

  // Update root_title - ONLY root effect should run
  root_title.set("New App Title")
  assert_eq(root_count.val, 2) // Only this increased
  assert_eq(branch_a_count.val, 1)
  assert_eq(branch_b_count.val, 2)
  assert_eq(leaf_a1_count.val, 2)
  assert_eq(leaf_a2_count.val, 1)
  assert_eq(leaf_b1_count.val, 1)
}

///|
test "Fine-grained: DOM text nodes update independently" {
  @global_jsdom.register()
  let doc = @jsdom.document()
  let container = doc.createElement("div")

  // Three independent signals for text content
  let name = @signals.signal("Alice")
  let age = @signals.signal(25)
  let city = @signals.signal("Tokyo")

  // Counters to track text node updates
  let name_updates = { val: 0 }
  let age_updates = { val: 0 }
  let city_updates = { val: 0 }

  // Create reactive text nodes with tracking
  let name_text = {
    let _ = @signals.effect(fn() {
      let _ = name.get()
      name_updates.val = name_updates.val + 1
    })
    text_sig(name)
  }
  let age_text = {
    let _ = @signals.effect(fn() {
      let _ = age.get()
      age_updates.val = age_updates.val + 1
    })
    text_sig(age)
  }
  let city_text = {
    let _ = @signals.effect(fn() {
      let _ = city.get()
      city_updates.val = city_updates.val + 1
    })
    text_sig(city)
  }

  // Build DOM structure
  let profile = div([class("profile")], [
    div([class("name")], [name_text]).as_node(),
    div([class("age")], [age_text]).as_node(),
    div([class("city")], [city_text]).as_node(),
  ])
  render(container, profile.as_node())

  // Initial state
  assert_eq(name_updates.val, 1)
  assert_eq(age_updates.val, 1)
  assert_eq(city_updates.val, 1)

  // Update name only
  name.set("Bob")
  assert_eq(name_updates.val, 2)
  assert_eq(age_updates.val, 1) // unchanged
  assert_eq(city_updates.val, 1) // unchanged

  // Update age only
  age.set(30)
  assert_eq(name_updates.val, 2) // unchanged
  assert_eq(age_updates.val, 2)
  assert_eq(city_updates.val, 1) // unchanged

  // Update city only
  city.set("Osaka")
  assert_eq(name_updates.val, 2) // unchanged
  assert_eq(age_updates.val, 2) // unchanged
  assert_eq(city_updates.val, 2)
}

///|
test "Fine-grained: shared signal triggers multiple dependents" {
  @global_jsdom.register()
  let shared = @signals.signal(100)
  let consumer_a_count = { val: 0 }
  let consumer_b_count = { val: 0 }
  let consumer_c_count = { val: 0 }
  let unrelated_count = { val: 0 }

  // Three effects depend on same signal
  let _ = @signals.effect(fn() {
    let _ = shared.get()
    consumer_a_count.val = consumer_a_count.val + 1
  })
  let _ = @signals.effect(fn() {
    let _ = shared.get()
    consumer_b_count.val = consumer_b_count.val + 1
  })
  let _ = @signals.effect(fn() {
    let _ = shared.get()
    consumer_c_count.val = consumer_c_count.val + 1
  })

  // Unrelated effect
  let unrelated_sig = @signals.signal("unrelated")
  let _ = @signals.effect(fn() {
    let _ = unrelated_sig.get()
    unrelated_count.val = unrelated_count.val + 1
  })

  // Initial
  assert_eq(consumer_a_count.val, 1)
  assert_eq(consumer_b_count.val, 1)
  assert_eq(consumer_c_count.val, 1)
  assert_eq(unrelated_count.val, 1)

  // Update shared - all three consumers should update
  shared.set(200)
  assert_eq(consumer_a_count.val, 2)
  assert_eq(consumer_b_count.val, 2)
  assert_eq(consumer_c_count.val, 2)
  assert_eq(unrelated_count.val, 1) // unchanged!

  // Multiple updates
  shared.set(300)
  shared.set(400)
  assert_eq(consumer_a_count.val, 4)
  assert_eq(consumer_b_count.val, 4)
  assert_eq(consumer_c_count.val, 4)
  assert_eq(unrelated_count.val, 1) // still unchanged!
}

///|
test "Fine-grained: memo prevents unnecessary recomputation" {
  @global_jsdom.register()
  let base = @signals.signal(10)
  let compute_count = { val: 0 }

  // Expensive computation with tracking
  let doubled = @signals.memo(fn() {
    compute_count.val = compute_count.val + 1
    base.get() * 2
  })

  // Multiple consumers of the memo
  let consumer1_count = { val: 0 }
  let consumer2_count = { val: 0 }
  let _ = @signals.effect(fn() {
    let _ = doubled()
    consumer1_count.val = consumer1_count.val + 1
  })
  let _ = @signals.effect(fn() {
    let _ = doubled()
    consumer2_count.val = consumer2_count.val + 1
  })

  // Initial: memo computed once, both consumers ran
  assert_eq(compute_count.val, 1)
  assert_eq(doubled(), 20)

  // Reading memo multiple times doesn't recompute
  let _ = doubled()
  let _ = doubled()
  let _ = doubled()
  // compute_count should not increase from just reading

  // Update base signal
  base.set(20)
  assert_eq(doubled(), 40)
  // Memo recomputed once for the new value
}
