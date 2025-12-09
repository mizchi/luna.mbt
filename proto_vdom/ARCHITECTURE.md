# UI Library Architecture - Multi-Backend Support

## Design Goal

Make the UI library work across multiple backends:
- **JS**: DOM rendering in browsers
- **WASM**: DOM rendering via FFI imports
- **Native**: TUI rendering (similar to ink)

## Current Problem

The library depends on `@core.Any` (JS-specific) in core types, making it impossible to use on other backends.

## Solution: Type Parameterization

Make `VNode` parameterized by handler type `H`, allowing different backends to use different event handler implementations.

### Core Types (Backend-Agnostic)

```moonbit
// vdom.mbt - Pure MoonBit, no backend dependencies

///| Virtual Node - parameterized by handler type H
pub enum VNode[H] {
  Element(ElementNode[H])
  Text(String)
  Component(ComponentNode[H])
  Fragment(Array[VNode[H]])
  Empty
}

///| Element node
pub struct ElementNode[H] {
  tag : String
  props : Props[H]
  children : Array[VNode[H]]
  key : String?
}

///| Attribute value - parameterized by handler type
pub enum AttrValue[H] {
  Str(String)
  Num(Int)
  Bool(Bool)
  Handler(H)  // H is the handler type (backend-specific)
  StyleObj(Array[(String, String)])
}

///| Props type
pub type Props[H] = Array[(String, AttrValue[H])]
```

### JS Backend

```moonbit
// vdom_js.mbt - JS-specific type aliases

///| JS event handler type
pub type JSHandler = (@core.Any) -> Unit

///| JS-specific VNode type
pub type JSVNode = VNode[JSHandler]

///| JS-specific Props type
pub type JSProps = Props[JSHandler]

///| JS-specific AttrValue type
pub type JSAttrValue = AttrValue[JSHandler]
```

### Native Backend (Future)

```moonbit
// vdom_native.mbt - Native-specific type aliases

///| Native event handler type
pub struct NativeEvent {
  // Terminal event data
}

pub type NativeHandler = (NativeEvent) -> Unit

///| Native-specific VNode type
pub type NativeVNode = VNode[NativeHandler]

///| Native-specific Props type
pub type NativeProps = Props[NativeHandler]
```

### WASM Backend (Future)

```moonbit
// vdom_wasm.mbt - WASM-specific type aliases

///| WASM event handler type (via FFI)
pub type WasmHandler = (WasmEvent) -> Unit

///| WASM-specific VNode type
pub type WasmVNode = VNode[WasmHandler]
```

## Migration Plan

### Phase 1: Type Parameterization (Current)

1. ✅ Add type parameter `H` to `VNode`, `AttrValue`, `Props`
2. ✅ Update all core types to use `H` instead of `EventHandler`
3. ✅ Create JS-specific type aliases
4. ✅ Update all existing code to use JS types

### Phase 2: Renderer Interface

```moonbit
// renderer.mbt - Generic renderer interface

pub trait Renderer[H, Target] {
  render(self : Self, vnode : VNode[H]) -> Target
  diff(self : Self, old : VNode[H], new : VNode[H]) -> Patches[H]
  apply_patches(self : Self, patches : Patches[H]) -> Unit
}
```

### Phase 3: Backend-Specific Implementations

- **JS Backend**: `renderer_dom.mbt` implements `Renderer[JSHandler, @dom.Element]`
- **Native Backend**: `renderer_tui.mbt` implements `Renderer[NativeHandler, TUIBuffer]`
- **WASM Backend**: `renderer_wasm.mbt` implements `Renderer[WasmHandler, WasmDom]`

## Benefits

### 1. Type Safety
- Each backend has compile-time type checking
- No runtime type errors from mixing backends

### 2. Code Reuse
- Core VNode structure is shared
- Diff algorithm is shared
- Only renderers are backend-specific

### 3. Flexibility
- Easy to add new backends
- Can optimize per-backend without affecting others

### 4. Testing
- Can test core logic without backend dependencies
- Can mock renderers for unit tests

## File Organization

```
src/_experimental/ui/
├── vdom.mbt              # Core types: VNode[H], AttrValue[H], Props[H]
├── vdom_js.mbt           # JS type aliases: JSVNode, JSHandler, etc.
├── element.mbt           # Element creation DSL (generic)
├── props_builder.mbt     # Props builder (generic)
├── reconcile.mbt         # Diff algorithm (generic)
├── renderer.mbt          # Renderer interface (generic)
├── renderer_dom.mbt      # JS DOM renderer (JS-specific)
├── renderer_ssr.mbt      # SSR renderer (JS-specific)
├── context.mbt           # Context API (needs parameterization)
└── (future)
    ├── vdom_native.mbt   # Native type aliases
    ├── renderer_tui.mbt  # TUI renderer for native
    ├── vdom_wasm.mbt     # WASM type aliases
    └── renderer_wasm.mbt # WASM renderer
```

## Context API

Context API also needs parameterization:

```moonbit
pub struct Context[T, H] {
  id : Int
  default_value : T
  // H is phantom type for compatibility with VNode[H]
}
```

Or use a separate storage mechanism that doesn't depend on VNode type.

## Backwards Compatibility

To minimize breaking changes:
1. Create new parameterized types
2. Keep old types as aliases to JS-specific versions
3. Gradually migrate code
4. Deprecate old types in next major version

Example:
```moonbit
// Deprecated (for backwards compatibility)
pub type EventHandler = JSHandler
pub type VNode = JSVNode
pub type Props = JSProps
```

## Next Steps

1. Implement type parameterization in `vdom.mbt`
2. Create `vdom_js.mbt` with JS-specific aliases
3. Update `element.mbt` and `props_builder.mbt` to be generic
4. Update renderers to use parameterized types
5. Update tests and benchmarks
6. Document migration guide
