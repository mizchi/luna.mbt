// WC Sample Application demonstrating Luna Web Components features
//
// This file serves as a comprehensive example showing Web Components
// with MoonBit and Luna's reactive system.
//

///|
/// Check if debug mode is enabled
extern "js" fn is_debug() -> Bool =
  #| () => typeof window !== 'undefined' && window.__DEBUG__ === true

///|
/// Debug logging helper - only logs when window.__DEBUG__ is true
fn debug_log(msg : String) -> Unit {
  if is_debug() {
    let global = @global.global_this()
    global["console"]._call("log", [@js.any(msg)]) |> ignore
  }
}

// =============================================================================
// FFI for Web Components
// =============================================================================

///|
extern "js" fn define_custom_element(
  name : String,
  render_fn : (@js_dom.Element) -> Unit,
) -> Unit =
  #| (name, renderFn) => {
  #|   if (customElements.get(name)) return;
  #|   class LunaElement extends HTMLElement {
  #|     constructor() {
  #|       super();
  #|       this.attachShadow({ mode: 'open' });
  #|     }
  #|     connectedCallback() {
  #|       renderFn(this);
  #|     }
  #|   }
  #|   customElements.define(name, LunaElement);
  #| }

///|
extern "js" fn get_shadow_root_ffi(
  element : @js_dom.Element,
) -> @js_dom.Element =
  #| (el) => el.shadowRoot

///|
extern "js" fn set_inner_html(element : @js_dom.Element, html : String) -> Unit =
  #| (el, html) => { el.innerHTML = html; }

///|
extern "js" fn query_selector_raw(
  element : @js_dom.Element,
  selector : String,
) -> @js_dom.Element =
  #| (el, sel) => el.querySelector(sel)

///|
extern "js" fn is_element_null(el : @js_dom.Element) -> Bool =
  #| (el) => el === null || el === undefined

///|
fn query_selector(
  element : @js_dom.Element,
  selector : String,
) -> @js_dom.Element? {
  let result = query_selector_raw(element, selector)
  if is_element_null(result) {
    None
  } else {
    Some(result)
  }
}

///|
extern "js" fn add_event_listener_ffi(
  element : @js_dom.Element,
  event_type : String,
  handler : () -> Unit,
) -> Unit =
  #| (el, type, handler) => el.addEventListener(type, handler)

///|
extern "js" fn add_input_listener(
  element : @js_dom.Element,
  handler : (String) -> Unit,
) -> Unit =
  #| (el, handler) => el.addEventListener('input', (e) => { handler(e.target.value); })

///|
extern "js" fn set_text_content(
  element : @js_dom.Element,
  text : String,
) -> Unit =
  #| (el, text) => { el.textContent = text; }

///|
extern "js" fn set_style(
  element : @js_dom.Element,
  property : String,
  value : String,
) -> Unit =
  #| (el, prop, val) => { el.style[prop] = val; }

///|
extern "js" fn prevent_default(event : @js.Any) -> Unit =
  #| (e) => e.preventDefault()

///|
extern "js" fn add_submit_listener(
  element : @js_dom.Element,
  handler : (@js.Any) -> Unit,
) -> Unit =
  #| (el, handler) => el.addEventListener('submit', handler)

// =============================================================================
// Counter Component
// =============================================================================

///|
fn register_wc_counter() -> Unit {
  define_custom_element("wc-counter", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let count = @signal.signal(0)
    let doubled = @signal.memo(fn() { count.get() * 2 })
    let is_even = @signal.memo(fn() { count.get() % 2 == 0 })

    // Initial render
    let html =
      #|<style>
      #|  :host { display: block; }
      #|  .buttons button { font-size: 18px; min-width: 40px; padding: 8px 16px; margin: 4px; cursor: pointer; }
      #|</style>
      #|<h2>Counter Example</h2>
      #|<p class="count">Count: 0</p>
      #|<p class="doubled">Doubled: 0</p>
      #|<p class="parity">Even</p>
      #|<div class="buttons">
      #|  <button class="dec">-</button>
      #|  <button class="inc">+</button>
      #|  <button class="reset">Reset</button>
      #|</div>
    set_inner_html(shadow, html)

    // Bind events
    match query_selector(shadow, ".dec") {
      Some(btn) =>
        add_event_listener_ffi(btn, "click", fn() { count.update(n => n - 1) })
      None => ()
    }
    match query_selector(shadow, ".inc") {
      Some(btn) =>
        add_event_listener_ffi(btn, "click", fn() { count.update(n => n + 1) })
      None => ()
    }
    match query_selector(shadow, ".reset") {
      Some(btn) => add_event_listener_ffi(btn, "click", fn() { count.set(0) })
      None => ()
    }

    // Reactive updates
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".count") {
        Some(el) => set_text_content(el, "Count: " + count.get().to_string())
        None => ()
      }
    })
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".doubled") {
        Some(el) => set_text_content(el, "Doubled: " + doubled().to_string())
        None => ()
      }
    })
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".parity") {
        Some(el) => set_text_content(el, if is_even() { "Even" } else { "Odd" })
        None => ()
      }
    })

  })
}

// =============================================================================
// Input Component
// =============================================================================

///|
fn register_wc_input() -> Unit {
  define_custom_element("wc-input", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let text = @signal.signal("")
    let char_count = @signal.memo(fn() { text.get().length() })
    let html =
      #|<style>:host { display: block; } input { padding: 8px; margin: 4px; }</style>
      #|<h2>Input Example</h2>
      #|<input type="text" placeholder="Type something..." class="text-input">
      #|<p class="char-count">Characters: 0</p>
      #|<p class="typed">You typed: </p>
    set_inner_html(shadow, html)
    match query_selector(shadow, ".text-input") {
      Some(input) => add_input_listener(input, fn(value) { text.set(value) })
      None => ()
    }
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".char-count") {
        Some(el) =>
          set_text_content(el, "Characters: " + char_count().to_string())
        None => ()
      }
    })
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".typed") {
        Some(el) => set_text_content(el, "You typed: " + text.get())
        None => ()
      }
    })

  })
}

// =============================================================================
// Effect Component
// =============================================================================

///|
fn register_wc_effect() -> Unit {
  define_custom_element("wc-effect", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let active = @signal.signal(false)
    let ticks = @signal.signal(0)
    let _ = @signal.effect(fn() {
      let is_active = active.get()
      debug_log("Active state changed: " + is_active.to_string())
      @signal.on_cleanup(fn() { debug_log("Cleaning up effect") })
    })
    let html =
      #|<style>:host { display: block; } button { padding: 8px 16px; margin: 4px; cursor: pointer; }</style>
      #|<h2>Effect Example</h2>
      #|<p class="status">Status: Inactive</p>
      #|<p class="ticks">Ticks: 0</p>
      #|<button class="toggle">Start</button>
      #|<button class="tick">Tick</button>
    set_inner_html(shadow, html)
    match query_selector(shadow, ".toggle") {
      Some(btn) =>
        add_event_listener_ffi(btn, "click", fn() { active.update(b => not(b)) })
      None => ()
    }
    match query_selector(shadow, ".tick") {
      Some(btn) =>
        add_event_listener_ffi(btn, "click", fn() { ticks.update(n => n + 1) })
      None => ()
    }
    let _ = @signal.effect(fn() {
      let status = if active.get() { "Active" } else { "Inactive" }
      match query_selector(shadow, ".status") {
        Some(el) => set_text_content(el, "Status: " + status)
        None => ()
      }
      match query_selector(shadow, ".toggle") {
        Some(el) =>
          set_text_content(el, if active.get() { "Stop" } else { "Start" })
        None => ()
      }
    })
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".ticks") {
        Some(el) => set_text_content(el, "Ticks: " + ticks.get().to_string())
        None => ()
      }
    })

  })
}

// =============================================================================
// Conditional Component
// =============================================================================

///|
fn register_wc_conditional() -> Unit {
  define_custom_element("wc-conditional", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let show_message = @signal.signal(true)
    let html =
      #|<style>
      #|  :host { display: block; }
      #|  button { padding: 8px 16px; margin: 4px; cursor: pointer; }
      #|  .message { padding: 10px; background-color: #e0f7fa; border-radius: 4px; margin-top: 8px; }
      #|</style>
      #|<h2>Conditional Example</h2>
      #|<button class="toggle">Hide Message</button>
      #|<div class="message">Hello! This message is conditionally rendered.</div>
    set_inner_html(shadow, html)
    match query_selector(shadow, ".toggle") {
      Some(btn) =>
        add_event_listener_ffi(btn, "click", fn() {
          show_message.update(b => not(b))
        })
      None => ()
    }
    let _ = @signal.effect(fn() {
      let visible = show_message.get()
      match query_selector(shadow, ".toggle") {
        Some(el) =>
          set_text_content(
            el,
            if visible {
              "Hide Message"
            } else {
              "Show Message"
            },
          )
        None => ()
      }
      match query_selector(shadow, ".message") {
        Some(el) =>
          set_style(el, "display", if visible { "block" } else { "none" })
        None => ()
      }
    })

  })
}

// =============================================================================
// Style Component
// =============================================================================

///|
fn register_wc_style() -> Unit {
  define_custom_element("wc-style", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let hue = @signal.signal(180)
    let size = @signal.signal(100)
    let html =
      #|<style>
      #|  :host { display: block; }
      #|  .box { transition: all 0.3s ease; border-radius: 8px; }
      #|  label { margin-right: 8px; }
      #|  div { margin: 8px 0; }
      #|</style>
      #|<h2>Style Example</h2>
      #|<div class="box" style="width: 100px; height: 100px; background-color: hsl(180, 70%, 50%);"></div>
      #|<div><label>Hue:</label><input type="range" class="hue" value="180" min="0" max="360"></div>
      #|<div><label>Size:</label><input type="range" class="size" value="100" min="50" max="200"></div>
    set_inner_html(shadow, html)
    match query_selector(shadow, ".hue") {
      Some(input) =>
        add_input_listener(input, fn(value) {
          match @global.parseInt(value) {
            Some(n) => hue.set(n)
            None => ()
          }
        })
      None => ()
    }
    match query_selector(shadow, ".size") {
      Some(input) =>
        add_input_listener(input, fn(value) {
          match @global.parseInt(value) {
            Some(n) => size.set(n)
            None => ()
          }
        })
      None => ()
    }
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".box") {
        Some(el) => {
          let s = size.get()
          let h = hue.get()
          set_style(el, "width", s.to_string() + "px")
          set_style(el, "height", s.to_string() + "px")
          set_style(
            el,
            "backgroundColor",
            "hsl(" + h.to_string() + ", 70%, 50%)",
          )
        }
        None => ()
      }
    })

  })
}

// =============================================================================
// Todo Component
// =============================================================================

///|
priv struct TodoItem {
  id : Int
  text : String
  completed : Bool
}

///|
fn register_wc_todo() -> Unit {
  define_custom_element("wc-todo", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let todos : @signal.Signal[Array[TodoItem]] = @signal.signal([])
    let input_text = @signal.signal("")
    let next_id = @signal.signal(1)
    fn render_todos() -> String {
      let items = todos.get()
      let sb = StringBuilder::new()
      for i = 0; i < items.length(); i = i + 1 {
        let item = items[i]
        let style = if item.completed {
          "text-decoration: line-through; opacity: 0.6;"
        } else {
          ""
        }
        sb.write_string("<li data-id=\"")
        sb.write_string(item.id.to_string())
        sb.write_string("\" style=\"")
        sb.write_string(style)
        sb.write_string("\"><span class=\"todo-text\">")
        sb.write_string(item.text)
        sb.write_string("</span><button class=\"remove\">x</button></li>")
      }
      sb.to_string()
    }

    fn get_completed_count() -> Int {
      let items = todos.get()
      let mut count = 0
      for i = 0; i < items.length(); i = i + 1 {
        if items[i].completed {
          count = count + 1
        }
      }
      count
    }

    let html =
      #|<style>
      #|  :host { display: block; }
      #|  input { padding: 8px; margin: 4px; }
      #|  button { padding: 8px 16px; margin: 4px; cursor: pointer; }
      #|  ul { list-style: none; padding: 0; }
      #|  li { padding: 8px; margin: 4px 0; background: #fff; border: 1px solid #eee; border-radius: 4px; display: flex; justify-content: space-between; }
      #|  .todo-text { cursor: pointer; }
      #|</style>
      #|<h2>Todo List Example</h2>
      #|<form class="todo-form">
      #|  <input type="text" class="todo-input" placeholder="Add a todo...">
      #|  <button type="submit">Add</button>
      #|</form>
      #|<p class="stats">0/0 completed</p>
      #|<ul class="todo-list"></ul>
    set_inner_html(shadow, html)

    // Input binding
    match query_selector(shadow, ".todo-input") {
      Some(input) =>
        add_input_listener(input, fn(value) { input_text.set(value) })
      None => ()
    }

    // Form submit
    match query_selector(shadow, ".todo-form") {
      Some(form) =>
        add_submit_listener(form, fn(e) {
          prevent_default(e)
          let text = input_text.get()
          if text != "" {
            let id = next_id.get()
            next_id.set(id + 1)
            todos.update(fn(items) {
              let new_items = items.copy()
              new_items.push({ id, text, completed: false })
              new_items
            })
            input_text.set("")
            // Clear input field
            match query_selector(shadow, ".todo-input") {
              Some(input) => set_input_value(input, "")
              None => ()
            }
          }
        })
      None => ()
    }
    fn toggle_todo(id : Int) -> Unit {
      todos.update(fn(items) {
        let new_items : Array[TodoItem] = []
        for i = 0; i < items.length(); i = i + 1 {
          let item = items[i]
          if item.id == id {
            new_items.push({ ..item, completed: not(item.completed) })
          } else {
            new_items.push(item)
          }
        }
        new_items
      })
    }

    fn remove_todo(id : Int) -> Unit {
      todos.update(fn(items) {
        let new_items : Array[TodoItem] = []
        for i = 0; i < items.length(); i = i + 1 {
          if items[i].id != id {
            new_items.push(items[i])
          }
        }
        new_items
      })
    }

    fn bind_todo_handlers_mbt() -> Unit {
      // Bind toggle handlers
      let todo_texts = query_selector_all(shadow, ".todo-text")
      let todo_text_len = get_array_length(todo_texts)
      for i = 0; i < todo_text_len; i = i + 1 {
        let el = get_array_item(todo_texts, i)
        let id = get_parent_data_id(el)
        add_event_listener_ffi(el, "click", fn() { toggle_todo(id) })
      }
      // Bind remove handlers
      let remove_btns = query_selector_all(shadow, ".remove")
      let remove_btn_len = get_array_length(remove_btns)
      for j = 0; j < remove_btn_len; j = j + 1 {
        let el = get_array_item(remove_btns, j)
        let id = get_parent_data_id(el)
        add_event_listener_ffi(el, "click", fn() { remove_todo(id) })
      }
    }

    // Reactive list update
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".todo-list") {
        Some(list) => {
          set_inner_html(list, render_todos())
          // Re-bind click handlers for todos
          bind_todo_handlers_mbt()
        }
        None => ()
      }
      match query_selector(shadow, ".stats") {
        Some(el) => {
          let total = todos.get().length()
          let completed = get_completed_count()
          set_text_content(
            el,
            completed.to_string() + "/" + total.to_string() + " completed",
          )
        }
        None => ()
      }
    })

  })
}

///|
extern "js" fn set_input_value(
  element : @js_dom.Element,
  value : String,
) -> Unit =
  #| (el, val) => { el.value = val; }

///|
extern "js" fn query_selector_all(
  element : @js_dom.Element,
  selector : String,
) -> @js.Any =
  #| (el, sel) => Array.from(el.querySelectorAll(sel))

///|
extern "js" fn get_array_length(arr : @js.Any) -> Int =
  #| (arr) => arr.length

///|
extern "js" fn get_array_item(arr : @js.Any, index : Int) -> @js_dom.Element =
  #| (arr, i) => arr[i]

///|
extern "js" fn get_parent_data_id(el : @js_dom.Element) -> Int =
  #| (el) => parseInt(el.parentElement.dataset.id)

// =============================================================================
// Nested Components - Child Button
// =============================================================================

///|
extern "js" fn dispatch_custom_event(
  element : @js_dom.Element,
  event_name : String,
  detail : @js.Any,
) -> Unit =
  #| (el, name, detail) => {
  #|   el.dispatchEvent(new CustomEvent(name, {
  #|     bubbles: true,
  #|     composed: true,  // This allows crossing shadow DOM boundaries
  #|     detail
  #|   }));
  #| }

///|
extern "js" fn add_custom_event_listener(
  element : @js_dom.Element,
  event_name : String,
  handler : (@js.Any) -> Unit,
) -> Unit =
  #| (el, name, handler) => el.addEventListener(name, (e) => handler(e.detail))

///|
extern "js" fn int_to_any(n : Int) -> @js.Any =
  #| (n) => n

///|
fn register_wc_child_button() -> Unit {
  define_custom_element("wc-child-button", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let click_count = @signal.signal(0)
    set_inner_html(
      shadow,
      (
        #|<style>
        #|  :host { display: inline-block; }
        #|  button { padding: 8px 16px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; }
        #|  button:hover { background: #45a049; }
        #|  .count { font-size: 12px; color: #666; margin-top: 4px; }
        #|</style>
        #|<button class="child-btn">Child Button</button>
        #|<div class="count">Local clicks: <span class="local-count">0</span></div>
      ),
    )
    match query_selector(shadow, ".child-btn") {
      Some(btn) =>
        add_event_listener_ffi(btn, "click", fn() {
          click_count.update(n => n + 1)
          // Dispatch custom event to parent (bubbles through shadow DOM)
          dispatch_custom_event(
            host,
            "child-clicked",
            int_to_any(click_count.get()),
          )
        })
      None => ()
    }
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".local-count") {
        Some(el) => set_text_content(el, click_count.get().to_string())
        None => ()
      }
    })

  })
}

// =============================================================================
// Nested Components - Parent Container
// =============================================================================

///|
fn register_wc_nested_parent() -> Unit {
  define_custom_element("wc-nested-parent", fn(host) {
    let shadow = get_shadow_root_ffi(host)
    let total_child_clicks = @signal.signal(0)
    set_inner_html(
      shadow,
      (
        #|<style>
        #|  :host { display: block; }
        #|  .parent-container { border: 2px solid #2196F3; padding: 16px; border-radius: 8px; }
        #|  .parent-header { color: #2196F3; margin-bottom: 16px; }
        #|  .children { display: flex; gap: 16px; flex-wrap: wrap; }
        #|  .stats { margin-top: 16px; padding: 8px; background: #e3f2fd; border-radius: 4px; }
        #|</style>
        #|<div class="parent-container">
        #|  <h3 class="parent-header">Parent Component</h3>
        #|  <div class="children">
        #|    <wc-child-button></wc-child-button>
        #|    <wc-child-button></wc-child-button>
        #|    <wc-child-button></wc-child-button>
        #|  </div>
        #|  <div class="stats">Total clicks from children: <span class="total-clicks">0</span></div>
        #|</div>
      ),
    )

    // Listen for custom events from child components (bubbles through shadow DOM)
    add_custom_event_listener(host, "child-clicked", fn(_detail) {
      total_child_clicks.update(n => n + 1)
    })
    let _ = @signal.effect(fn() {
      match query_selector(shadow, ".total-clicks") {
        Some(el) => set_text_content(el, total_child_clicks.get().to_string())
        None => ()
      }
    })

  })
}

// =============================================================================
// Main Application
// =============================================================================

///|
fn main {
  // Register all Web Components
  register_wc_counter()
  register_wc_input()
  register_wc_effect()
  register_wc_conditional()
  register_wc_style()
  register_wc_todo()

  // Register nested components (child must be registered before parent uses it)
  register_wc_child_button()
  register_wc_nested_parent()
}
