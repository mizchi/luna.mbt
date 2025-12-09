///| Component tests

///|

///|
test "component: create simple component without props" {
  let hooks_state = HooksState::new()
  let counter_component : Component0[JSHandler] = fn() {
    div([], [text("Counter")])
  }
  let vnode : JSVNode = component(counter_component, None, hooks_state)
  match vnode {
    Component(_) => inspect(true, content="true")
    _ => inspect(false, content="true")
  }
}

///|

///|
test "component: render component to VNode" {
  let hooks_state = HooksState::new()
  let counter_component : Component0[JSHandler] = fn() {
    div([class_name("counter")], [text("Count: 0")])
  }
  let component_vnode : JSVNode = component(
    counter_component,
    None,
    hooks_state,
  )
  let rendered : JSVNode = render_component(component_vnode)
  match rendered {
    Element({ tag, .. }) => inspect(tag, content="div")
    _ => inspect(false, content="true")
  }
}

///|

///|
test "component: useState in component" {
  let hooks_state = HooksState::new()
  let counter_component : Component0[JSHandler] = fn() {
    let (count, _) : (Int, (Int) -> Unit) = use_state(0)
    div([], [text("Count: " + count.to_string())])
  }
  let component_vnode : JSVNode = component(
    counter_component,
    None,
    hooks_state,
  )
  let rendered : JSVNode = render_component(component_vnode)
  inspect(rendered.debug_string(), content="Element(div, 1 children)")
}

///|

///|
test "component: useState persists across renders" {
  let hooks_state = HooksState::new()
  let counter_component : Component0[JSHandler] = fn() {
    let (count, set_count) : (Int, (Int) -> Unit) = use_state(0)
    set_count(5) // Update on first render
    div([], [text("Count: " + count.to_string())])
  }

  // First render
  let component_vnode1 : JSVNode = component(
    counter_component,
    None,
    hooks_state,
  )
  let _rendered1 : JSVNode = render_component(component_vnode1)

  // Second render - should have updated value
  let component_vnode2 : JSVNode = component(
    counter_component,
    None,
    hooks_state,
  )
  let rendered2 : JSVNode = render_component(component_vnode2)
  inspect(rendered2.debug_string(), content="Element(div, 1 children)")
}

///|

///|
test "component: nested components" {
  let hooks_state_inner = HooksState::new()
  let hooks_state_outer = HooksState::new()
  let inner_component : Component0[JSHandler] = fn() {
    span([], [text("Inner")])
  }
  let outer_component : Component0[JSHandler] = fn() {
    let inner : JSVNode = component(inner_component, None, hooks_state_inner)
    div([], [text("Outer: "), inner])
  }
  let component_vnode : JSVNode = component(
    outer_component,
    None,
    hooks_state_outer,
  )
  let rendered : JSVNode = render_component(component_vnode)
  match rendered {
    Element({ tag, children, .. }) => {
      inspect(tag, content="div")
      inspect(children.length(), content="2")
    }
    _ => inspect(false, content="true")
  }
}

///|

///|
/// Props for greeting component test
struct GreetingProps {
  name : String
}

///|

///|
test "component: component with props" {
  let hooks_state = HooksState::new()
  let greeting_component : Component1[JSHandler, GreetingProps] = fn(
    props : GreetingProps,
  ) {
    div([], [text("Hello, " + props.name)])
  }
  let vnode : JSVNode = component_with_props(
    greeting_component,
    { name: "Alice" },
    None,
    hooks_state,
  )
  let rendered : JSVNode = render_component(vnode)
  inspect(rendered.debug_string(), content="Element(div, 1 children)")
}

///|

///|
test "component: render with effects" {
  let hooks_state = HooksState::new()
  let mut effect_ran = false
  let component_with_effect : Component0[JSHandler] = fn() {
    use_effect(
      fn() {
        effect_ran = true
        None
      },
      None,
    )
    div([], [text("Component")])
  }
  let vnode : JSVNode = component(component_with_effect, None, hooks_state)

  // Effect should not have run yet
  inspect(effect_ran, content="false")

  // Render with effects
  let _rendered : JSVNode = render_component_with_effects(vnode)

  // Effect should have run
  inspect(effect_ran, content="true")
}
