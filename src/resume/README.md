# Resumable State

Qwik-inspired resumable state serialization for SSR hydration.

## Overview

This module provides functionality to serialize Signal states to JSON during SSR (Server-Side Rendering) and restore them on the client side without re-executing the application logic. This is the core concept behind Qwik's "Resumability".

### Traditional Hydration vs Resumability

**Traditional Hydration:**
1. Server renders HTML
2. Client downloads JavaScript
3. Client re-executes the entire application to rebuild state
4. Client attaches event handlers

**Resumability:**
1. Server renders HTML with embedded state
2. Client downloads JavaScript
3. Client deserializes state directly from HTML (no re-execution)
4. Client attaches event handlers lazily

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SSR Phase                                │
├─────────────────────────────────────────────────────────────────┤
│  Signal[Int](5) ──► register_signal() ──► ResumableState        │
│  Signal[String]("hello") ──────────────►   [5, "hello"]         │
│                                                                 │
│  ResumableState ──► state_to_script_tag() ──►                   │
│    <script type="application/json" data-resumable-state>        │
│      [5,"hello"]                                                │
│    </script>                                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ HTML sent to browser
┌─────────────────────────────────────────────────────────────────┐
│                       Client Phase                              │
├─────────────────────────────────────────────────────────────────┤
│  parse_state_from_html() ──► ResumableState [5, "hello"]        │
│                                                                 │
│  resume_signal(state, 0, 0) ──► Signal[Int](5)                  │
│  resume_signal(state, 1, "") ──► Signal[String]("hello")        │
│                                                                 │
│  Signals are reactive and ready to use immediately!             │
└─────────────────────────────────────────────────────────────────┘
```

## API Reference

### ResumableState

Container for serializable state values.

```moonbit
// Create a new empty state
let state = ResumableState::new()

// Register values
let id1 = state.register_int(42)
let id2 = state.register_string("hello")
let id3 = state.register_bool(true)
let id4 = state.register_float(3.14)

// Retrieve values
state.get_int(id1)    // Some(42)
state.get_string(id2) // Some("hello")

// Serialize to JSON
state.to_json() // "[42,\"hello\",true,3.14]"

// Parse from JSON
ResumableState::from_json("[42,\"hello\"]") // Some(ResumableState)
```

### Signal Serialization

Functions to serialize and restore Signal values.

```moonbit
// Register a signal's current value to state
let signal = @ui.signal(42)
let id = register_signal(state, signal)

// Restore a signal's value from state
let new_signal = @ui.signal(0)
restore_signal(state, new_signal, id) // new_signal now has value 42

// Create a signal and register it in one step (SSR)
let (signal, id) = create_resumable_signal(state, 42)

// Resume or create a signal from state (Client)
let signal = resume_signal(state, id, default_value)
```

### HTML Embedding

Functions to embed and extract state from HTML.

```moonbit
// Generate a script tag with embedded state (global)
let tag = state_to_script_tag(state)
// "<script type=\"application/json\" data-resumable-state>[42]</script>"

// Generate a script tag with named state ID
let tag = state_to_script_tag_with_id(state, "counter")
// "<script type=\"application/json\" data-resumable-state=\"counter\">[42]</script>"

// Generate a container with lazy-load endpoint
let tag = state_endpoint_tag("user", "/api/user/123", "<div>Loading...</div>")
// "<div data-state-id=\"user\" data-state-src=\"/api/user/123\">...</div>"

// Extract state JSON from HTML
let json = extract_state_from_html(html) // Some("[42]")

// Parse state directly from HTML
let state = parse_state_from_html(html) // Some(ResumableState)
```

## Usage Modes

### Mode 1: Portable HTML (Inline State)

State is embedded directly in the HTML. The file is completely self-contained.

```html
<!DOCTYPE html>
<html>
<body>
  <!-- Component with inline state -->
  <div data-state-id="counter">
    <span>10</span>
    <button on:click="./app.js#increment">+1</button>
  </div>
  <script type="application/json" data-resumable-state="counter">[10]</script>

  <!-- Another component -->
  <div data-state-id="form">
    <input value="alice">
  </div>
  <script type="application/json" data-resumable-state="form">["alice"]</script>

  <!-- Loader (inline for portability) -->
  <script>/* loader.min.js contents */</script>
</body>
</html>
```

### Mode 2: Lazy Loading (Endpoint)

State is loaded from an endpoint on first interaction.

```html
<!DOCTYPE html>
<html>
<body>
  <!-- Component loads state from endpoint -->
  <div data-state-id="user-profile" data-state-src="/api/user/123">
    <span>Loading...</span>
    <button on:click="./profile.js#edit">Edit</button>
  </div>

  <script>/* loader.min.js contents */</script>
</body>
</html>
```

The endpoint should return a JSON array:

```json
["alice", "alice@example.com", 25]
```

### SSR Example (MoonBit)

```moonbit
fn render_page() -> String {
  // Counter component
  let counter_state = ResumableState::new()
  let (count, _) = create_resumable_signal(counter_state, 10)

  // Form component
  let form_state = ResumableState::new()
  let (name, _) = create_resumable_signal(form_state, "alice")

  // Build HTML
  "<!DOCTYPE html><html><body>" +
    "<div data-state-id=\"counter\">" +
      "<span>" + count.get().to_string() + "</span>" +
      "<button on:click=\"./app.js#increment\">+1</button>" +
    "</div>" +
    state_to_script_tag_with_id(counter_state, "counter") +
    "<div data-state-id=\"form\">" +
      "<input value=\"" + name.get() + "\">" +
    "</div>" +
    state_to_script_tag_with_id(form_state, "form") +
    "<script src=\"loader.min.js\"></script>" +
  "</body></html>"
}
```

## Supported Types

The `Serializable` trait is implemented for:

| Type | StateValue | JSON |
|------|------------|------|
| `Int` | `Int(n)` | `42` |
| `String` | `Str(s)` | `"hello"` |
| `Bool` | `Bool(b)` | `true` / `false` |
| `Double` | `Float(f)` | `3.14` |

## Loader (loader.js)

A minimal JavaScript runtime (~894 bytes, ~564 bytes gzipped) that enables lazy event handler loading with multi-state support.

### Features

- Multi-state support with named state IDs
- Extracts all `<script data-resumable-state="id">` into `window.__STATE__[id]`
- Lazy state loading from endpoints via `data-state-src`
- Event delegation with lazy module loading via `on:*` attributes
- Automatic state context detection (walks up DOM to find `data-state-id`)
- Supports: click, input, change, submit, keydown, keyup, focus, blur

### Handler Signature

Handlers receive 4 arguments:

```javascript
// handlers.js
export function increment(event, element, state, stateId) {
  // event: The DOM event
  // element: The element with on:* attribute
  // state: Array of state values for this component
  // stateId: The state ID string (e.g., "counter")

  state[0]++;
  element.textContent = state[0];
}
```

### Example: Counter Component

```html
<div data-state-id="counter">
  <span>0</span>
  <button on:click="./app.js#increment">+1</button>
  <button on:click="./app.js#decrement">-1</button>
</div>
<script type="application/json" data-resumable-state="counter">[0]</script>
```

```javascript
// app.js
export function increment(e, el, state) {
  state[0]++;
  el.closest('[data-state-id]').querySelector('span').textContent = state[0];
}

export function decrement(e, el, state) {
  state[0]--;
  el.closest('[data-state-id]').querySelector('span').textContent = state[0];
}
```

### Example: Lazy Loading

```html
<div data-state-id="user" data-state-src="/api/user/123">
  <button on:click="./user.js#showName">Show Name</button>
</div>
```

```javascript
// user.js
export function showName(e, el, state, id) {
  // state is fetched from /api/user/123 on first interaction
  alert(`User: ${state[0]}`); // state[0] = name
}
```

### API

```javascript
// Access all states (keyed by ID)
window.__STATE__
// { "counter": [0], "form": ["alice"], "_": [...] }

// Access specific state
window.__STATE__["counter"]  // [0]
window.__STATE__["_"]        // Global state (no ID)

// Manually trigger an event handler
window.__RESUME__('click', element)

// Manually load state from endpoint
await window.__LOAD__('user', '/api/user/123')
```

## File Structure

```
src/resume/
├── moon.pkg.json           # Package configuration
├── state.mbt               # ResumableState and JSON serialization
├── serialize.mbt           # Serializable trait and Signal functions
├── html.mbt                # HTML embedding and extraction
├── loader.js               # Resumable loader (readable)
├── loader.min.js           # Resumable loader (minified, 487 bytes)
├── state_test.mbt          # Unit tests for state operations
├── serialize_wbtest.mbt    # Whitebox tests for serialization
└── scenarios_wbtest.mbt    # User scenario tests
```

## Design Decisions

1. **Simple JSON Array Format**: State is serialized as a flat JSON array `[value1, value2, ...]` where the index is the signal ID. This is compact and fast to parse.

2. **Custom JSON Parser**: A lightweight JSON parser is included to avoid external dependencies and keep the bundle size small.

3. **HTML-Safe Escaping**: Special characters (`<`, `>`, `&`) are escaped as Unicode sequences (`\u003c`, etc.) to prevent XSS and HTML parsing issues.

4. **Graceful Degradation**: If state parsing fails, `resume_signal` falls back to the provided default value, ensuring the app still works.

## Limitations

- Currently only supports primitive types (Int, String, Bool, Double)
- Arrays and nested objects are not yet supported for Signal serialization
- No automatic state ID management (IDs must be tracked manually)

## Future Enhancements

- Support for Array and Object serialization
- Automatic ID generation based on component hierarchy
- Compression for large state payloads
- Prefetching of handler modules on hover/focus
