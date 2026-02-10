// Static Content Performance Test
// Tests innerHTML-based static rendering vs createElement

///|
extern "js" fn performance_now() -> Double =
  #| () => performance.now()

///|
fn create_list_vnode_dynamic(count : Int) -> @luna.Node[@js.Any, String] {
  let items : Array[@luna.Node[@js.Any, String]] = []
  for j in 0..<count {
    items.push(@luna.h("li", [], [@luna.text("Item " + j.to_string())]))
  }
  @luna.h("ul", [], items)
}

///|
fn create_list_vnode_static(count : Int) -> @luna.Node[Unit, String] {
  let items : Array[@luna.Node[Unit, String]] = []
  for j in 0..<count {
    items.push(@luna.h("li", [], [@luna.text("Item " + j.to_string())]))
  }
  @luna.h("ul", [], items)
}

///|
test "perf_static_vs_dynamic_rendering" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let iterations = 100
  let item_count = 100

  // Pre-render HTML for SSR simulation
  let pre_html = @ssr.render_to_string(create_list_vnode_static(item_count)).html

  // Measure: render_vnode_to_dom (createElement one by one)
  let start_dynamic = performance_now()
  for i in 0..<iterations {
    let node = create_list_vnode_dynamic(item_count)
    let container = doc.createElement("div")
    container.as_node().appendChild(@client.render_vnode_to_dom(node)) |> ignore
  }
  let dynamic_time = performance_now() - start_dynamic

  // Measure: inject_static (VNode → HTML → innerHTML)
  let start_inject = performance_now()
  for i in 0..<iterations {
    let node = create_list_vnode_static(item_count)
    let container = doc.createElement("div")
    @client.inject_static(container, node)
  }
  let inject_time = performance_now() - start_inject

  // Measure: inject_static_html (pre-rendered HTML → innerHTML)
  let start_ssr = performance_now()
  for i in 0..<iterations {
    let container = doc.createElement("div")
    @client.inject_static_html(container, pre_html)
  }
  let ssr_time = performance_now() - start_ssr

  // Measure: static_div (creates wrapper, uses innerHTML)
  let start_block = performance_now()
  for i in 0..<iterations {
    let node = create_list_vnode_static(item_count)
    let _ = @client.static_div(node)
  }
  let block_time = performance_now() - start_block
  println(
    "=== Static Content Performance (\{item_count} items, \{iterations} iterations) ===",
  )
  println("render_vnode_to_dom:  \{dynamic_time.to_string()}ms (baseline)")
  println(
    "inject_static:        \{inject_time.to_string()}ms (VNode → innerHTML)",
  )
  println("inject_static_html:   \{ssr_time.to_string()}ms (pre-rendered HTML)")
  println(
    "static_div:           \{block_time.to_string()}ms (composable wrapper)",
  )
  println("")
  println("Note: jsdom doesn't reflect real browser performance.")
  println("Real browser: innerHTML is 2-3x faster than createElement.")
}
