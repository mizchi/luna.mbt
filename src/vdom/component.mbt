///| Component API - Functional components with hooks support

///|

///|
/// Component function type - takes no props
pub type Component0[H] = () -> VNode[H]

///|

///|
/// Component function type - takes props of type P
pub type Component1[H, P] = (P) -> VNode[H]

///|

///|
/// Create a component VNode without props
pub fn[H] component(
  render : Component0[H],
  key : String?,
  hooks_state : HooksState,
) -> VNode[H] {
  Component({ render, key, hooks_state })
}

///|

///|
/// Create a component VNode with props
pub fn[H, P] component_with_props(
  render : Component1[H, P],
  props : P,
  key : String?,
  hooks_state : HooksState,
) -> VNode[H] {
  let render_fn = fn() { render(props) }
  Component({ render: render_fn, key, hooks_state })
}

///|

///|
/// Render a component VNode to its actual VNode representation
/// This evaluates the component function and returns the resulting VNode
pub fn[H] render_component(vnode : VNode[H]) -> VNode[H] {
  match vnode {
    Component({ render, hooks_state, .. }) => {
      // Set up hooks context
      set_current_hooks_state(Some(hooks_state))

      // Reset hook index for new render
      hooks_state.reset_index()

      // Render component
      let result_vnode = render()

      // Recursively render nested components
      let final_vnode = render_component(result_vnode)

      // Clean up hooks context
      set_current_hooks_state(None)
      final_vnode
    }
    Element({ tag, props, children, key }) => {
      // Recursively render children components
      let rendered_children : Array[VNode[H]] = []
      for child in children {
        let rendered_child = render_component(child)
        rendered_children.push(rendered_child)
      }
      Element({ tag, props, children: rendered_children, key })
    }
    Fragment(children) => {
      // Recursively render fragment children
      let rendered_children : Array[VNode[H]] = []
      for child in children {
        let rendered_child = render_component(child)
        rendered_children.push(rendered_child)
      }
      Fragment(rendered_children)
    }
    Text(_) => vnode
    Empty => vnode
  }
}

///|

///|
/// Render and run effects for a component
/// This is a convenience function that renders the component and runs its effects
pub fn[H] render_component_with_effects(vnode : VNode[H]) -> VNode[H] {
  match vnode {
    Component({ hooks_state, .. }) => {
      let rendered = render_component(vnode)

      // Run effects after rendering
      hooks_state.run_effects()
      rendered
    }
    _ => render_component(vnode)
  }
}
