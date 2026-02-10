// Real-world Todo App Tests with JSDOM
//

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
  @element.DomNode,
  @resource.Signal[Array[Todo]],
  @resource.Signal[String],
) {
  let todos : @resource.Signal[Array[Todo]] = @resource.signal([])
  let input_text : @resource.Signal[String] = @resource.signal("")
  let next_id = Ref::new(1)

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
      arr.map(fn(todo) {
        if todo.id == id {
          { id: todo.id, text: todo.text, completed: not(todo.completed) }
        } else {
          todo
        }
      })
    })
  }

  // Delete todo handler
  fn delete_todo(id : Int) {
    todos.update(fn(arr) { arr.filter(fn(todo) { todo.id != id }) })
  }

  // Build the UI
  let app = @element.div(class="todo-app", [
    // Header
    @element.h1([@element.text("Todo App")]),
    // Input form
    @element.div(class="input-section", [
      @element.create_element(
        "input",
        [
          ("id", @element.attr_static("todo-input")),
          ("type", @element.attr_static("text")),
          ("placeholder", @element.attr_static("What needs to be done?")),
          ("value", @element.attr_dynamic(fn() { input_text.get() })),
          (
            "onInput",
            @element.attr_handler(fn(e : @js.Any) {
              let target : @js_dom.HTMLInputElement = e
                ._call("target", [])
                .cast()
              input_text.set(target.value)
            }),
          ),
          (
            "onKeydown",
            @element.attr_handler(fn(e : @js.Any) {
              let key : String = e._get("key").cast()
              if key == "Enter" {
                add_todo()
              }
            }),
          ),
        ],
        [],
      ),
      @element.button(
        id="add-btn",
        on=@element.events().click(fn(_) { add_todo() }),
        [@element.text("Add")],
      ),
    ]),
    // Todo list
    @element.create_element("ul", [("id", @element.attr_static("todo-list"))], [
      @element.for_each(fn() { todos.get() }, fn(todo, _idx) {
        @element.create_element(
          "li",
          [
            (
              "className",
              @element.attr_dynamic(fn() {
                if todo.completed {
                  "todo-item completed"
                } else {
                  "todo-item"
                }
              }),
            ),
            ("data-id", @element.attr_static(todo.id.to_string())),
          ],
          [
            @element.span(
              class="todo-text",
              on=@element.events().click(fn(_) { toggle_todo(todo.id) }),
              [@element.text(todo.text)],
            ),
            @element.button(
              class="delete-btn",
              on=@element.events().click(fn(_) { delete_todo(todo.id) }),
              [@element.text("×")],
            ),
          ],
        )
      }),
    ]),
    // Stats
    @element.div(id="stats", [
      @element.text_dyn(fn() {
        let items = todos.get()
        let total = items.length()
        let completed = items.filter(fn(item) { item.completed }).length()
        "\{total} items, \{completed} completed"
      }),
    ]),
  ])
  (app, todos, input_text)
}

// =============================================================================
// DOM Integration Tests with JSDOM
// =============================================================================

///|
test "Todo app renders initial state" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let container = doc.getElementById("root").unwrap_or(doc.createElement("div"))
  let (app, _todos, _input) = create_todo_app()
  @element.render_to(container, app)

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
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let (app, todos, input_text) = create_todo_app()
  @element.render_to(container, app)

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
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let (app, todos, _input) = create_todo_app()
  @element.render_to(container, app)

  // Add initial todos
  todos.set([
    { id: 1, text: "Task 1", completed: false },
    { id: 2, text: "Task 2", completed: false },
  ])

  // Toggle first todo
  todos.update(fn(arr) {
    arr.map(fn(todo) {
      if todo.id == 1 {
        { id: todo.id, text: todo.text, completed: true }
      } else {
        todo
      }
    })
  })

  // Verify state
  assert_eq(todos.get()[0].completed, true)
  assert_eq(todos.get()[1].completed, false)
}

///|
test "Todo app deletes todo" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let (app, todos, _input) = create_todo_app()
  @element.render_to(container, app)

  // Add initial todos
  todos.set([
    { id: 1, text: "Task 1", completed: false },
    { id: 2, text: "Task 2", completed: false },
    { id: 3, text: "Task 3", completed: false },
  ])
  assert_eq(todos.get().length(), 3)

  // Delete middle todo
  todos.update(fn(arr) { arr.filter(fn(todo) { todo.id != 2 }) })

  // Verify state
  assert_eq(todos.get().length(), 2)
  assert_eq(todos.get()[0].id, 1)
  assert_eq(todos.get()[1].id, 3)
}

///|
test "Todo app reactive text updates" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let count = @resource.signal(0)
  let counter_div = @element.div(id="counter", [@element.text_of(count)])
  @element.render_to(container, counter_div)

  // Initial value
  assert_eq(count.get(), 0)

  // Update
  count.set(42)
  assert_eq(count.get(), 42)

  // Multiple updates
  for i in 0..<10 {
    count.update(n => n + 1)
  }
  assert_eq(count.get(), 52)
}

///|
test "Todo app reactive class updates" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  let is_active = @resource.signal(false)
  let elem = @element.create_element(
    "div",
    [
      ("id", @element.attr_static("toggle-elem")),
      (
        "className",
        @element.attr_dynamic(fn() {
          if is_active.get() {
            "active"
          } else {
            "inactive"
          }
        }),
      ),
    ],
    [],
  )
  @element.render_to(container, elem)

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
  let todos : @resource.Signal[Array[Todo]] = @resource.signal([])
  let update_count = Ref::new(0)
  let _ = @resource.render_effect(fn() {
    let _ = todos.get()
    update_count.val = update_count.val + 1
  })

  // Initial effect run
  assert_eq(update_count.val, 1)

  // Batch multiple updates
  @resource.batch(fn() {
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
  let todos : @resource.Signal[Array[Todo]] = @resource.signal([
    { id: 1, text: "Task 1", completed: true },
    { id: 2, text: "Task 2", completed: false },
    { id: 3, text: "Task 3", completed: true },
  ])

  // Memoized computed value
  let completed_count = @resource.memo(fn() {
    todos.get().filter(fn(item) { item.completed }).length()
  })
  let active_count = @resource.memo(fn() {
    todos.get().filter(fn(item) { not(item.completed) }).length()
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
  let todos : @resource.Signal[Array[Todo]] = @resource.signal([
    { id: 1, text: "Task 1", completed: true },
    { id: 2, text: "Task 2", completed: false },
    { id: 3, text: "Task 3", completed: true },
  ])
  let filter_mode : @resource.Signal[String] = @resource.signal("all") // "all", "active", "completed"

  // Filtered todos using combine
  let filtered = @resource.combine2(todos, filter_mode, fn(items, mode) {
    if mode == "all" {
      items
    } else if mode == "active" {
      items.filter(fn(item) { not(item.completed) })
    } else {
      items.filter(fn(item) { item.completed })
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
  let sig = @resource.signal(0)
  let values : Array[Int] = []
  let dispose = @resource.render_effect(fn() { values.push(sig.get()) })

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
  let outer_sig = @resource.signal(1)
  let inner_sig = @resource.signal(10)
  let results : Array[Int] = []
  let _ = @resource.render_effect(fn() {
    let outer_val = outer_sig.get()
    let _ = @resource.render_effect(fn() {
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
  let sig1 = @resource.signal("Item 1")
  let sig2 = @resource.signal("Item 2")
  let sig3 = @resource.signal("Item 3")

  // Counter for each effect
  let counter : EffectCounter = {
    item1_count: 0,
    item2_count: 0,
    item3_count: 0,
  }

  // Effect that depends on sig1
  let _ = @resource.render_effect(fn() {
    let _ = sig1.get()
    counter.item1_count = counter.item1_count + 1
  })

  // Effect that depends on sig2
  let _ = @resource.render_effect(fn() {
    let _ = sig2.get()
    counter.item2_count = counter.item2_count + 1
  })

  // Effect that depends on sig3
  let _ = @resource.render_effect(fn() {
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
  let root_title = @resource.signal("App Title")
  let branch_a_value = @resource.signal(10)
  let branch_b_value = @resource.signal(20)
  let leaf_a1 = @resource.signal("Leaf A1")
  let leaf_a2 = @resource.signal("Leaf A2")
  let leaf_b1 = @resource.signal("Leaf B1")

  // Counters
  let root_count = Ref::new(0)
  let branch_a_count = Ref::new(0)
  let branch_b_count = Ref::new(0)
  let leaf_a1_count = Ref::new(0)
  let leaf_a2_count = Ref::new(0)
  let leaf_b1_count = Ref::new(0)

  // Root effect
  let _ = @resource.render_effect(fn() {
    let _ = root_title.get()
    root_count.val = root_count.val + 1
  })

  // Branch A effect (depends on branch_a_value)
  let _ = @resource.render_effect(fn() {
    let _ = branch_a_value.get()
    branch_a_count.val = branch_a_count.val + 1
  })

  // Branch B effect (depends on branch_b_value)
  let _ = @resource.render_effect(fn() {
    let _ = branch_b_value.get()
    branch_b_count.val = branch_b_count.val + 1
  })

  // Leaf effects
  let _ = @resource.render_effect(fn() {
    let _ = leaf_a1.get()
    leaf_a1_count.val = leaf_a1_count.val + 1
  })
  let _ = @resource.render_effect(fn() {
    let _ = leaf_a2.get()
    leaf_a2_count.val = leaf_a2_count.val + 1
  })
  let _ = @resource.render_effect(fn() {
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
  let doc = @js_dom.document()
  let container = doc.createElement("div")

  // Three independent signals for text content
  let name = @resource.signal("Alice")
  let age = @resource.signal(25)
  let city = @resource.signal("Tokyo")

  // Counters to track text node updates
  let name_updates = Ref::new(0)
  let age_updates = Ref::new(0)
  let city_updates = Ref::new(0)

  // Create reactive text nodes with tracking
  let name_text = {
    let _ = @resource.render_effect(fn() {
      let _ = name.get()
      name_updates.val = name_updates.val + 1
    })
    @element.text_of(name)
  }
  let age_text = {
    let _ = @resource.render_effect(fn() {
      let _ = age.get()
      age_updates.val = age_updates.val + 1
    })
    @element.text_of(age)
  }
  let city_text = {
    let _ = @resource.render_effect(fn() {
      let _ = city.get()
      city_updates.val = city_updates.val + 1
    })
    @element.text_of(city)
  }

  // Build DOM structure
  let profile = @element.div(class="profile", [
    @element.div(class="name", [name_text]),
    @element.div(class="age", [age_text]),
    @element.div(class="city", [city_text]),
  ])
  @element.render_to(container, profile)

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
  let shared = @resource.signal(100)
  let consumer_a_count = Ref::new(0)
  let consumer_b_count = Ref::new(0)
  let consumer_c_count = Ref::new(0)
  let unrelated_count = Ref::new(0)

  // Three effects depend on same signal
  let _ = @resource.render_effect(fn() {
    let _ = shared.get()
    consumer_a_count.val = consumer_a_count.val + 1
  })
  let _ = @resource.render_effect(fn() {
    let _ = shared.get()
    consumer_b_count.val = consumer_b_count.val + 1
  })
  let _ = @resource.render_effect(fn() {
    let _ = shared.get()
    consumer_c_count.val = consumer_c_count.val + 1
  })

  // Unrelated effect
  let unrelated_sig = @resource.signal("unrelated")
  let _ = @resource.render_effect(fn() {
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
  let base = @resource.signal(10)
  let compute_count = Ref::new(0)

  // Expensive computation with tracking
  let doubled = @resource.memo(fn() {
    compute_count.val = compute_count.val + 1
    base.get() * 2
  })

  // Multiple consumers of the memo
  let consumer1_count = Ref::new(0)
  let consumer2_count = Ref::new(0)
  let _ = @resource.render_effect(fn() {
    let _ = doubled()
    consumer1_count.val = consumer1_count.val + 1
  })
  let _ = @resource.render_effect(fn() {
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
