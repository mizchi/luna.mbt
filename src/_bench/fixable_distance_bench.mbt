///|

///| Distance-based Benchmarks for Fixable Hydration

///| Measures how repair cost scales with mismatch severity

// =============================================================================
// Helper Functions
// =============================================================================

///|
fn create_distance_tree(count : Int) -> @luna.Node[@js.Any] {
  let items : Array[@luna.Node[@js.Any]] = []
  for i in 0..<count {
    items.push(@luna.h("li", [], [@luna.text("Item " + i.to_string())]))
  }
  @luna.h("ul", [], items)
}

///|
fn create_distance_tree_with_attrs(count : Int) -> @luna.Node[@js.Any] {
  let items : Array[@luna.Node[@js.Any]] = []
  for i in 0..<count {
    items.push(
      @luna.h("li", [("class", @luna.attr_static("item-" + i.to_string()))], [
        @luna.text("Item " + i.to_string()),
      ]),
    )
  }
  @luna.h("ul", [], items)
}

///|
fn create_distance_html_text_diff(count : Int, diff_count : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("<ul>")
  for i in 0..<count {
    if i < diff_count {
      sb.write_string("<li>WRONG " + i.to_string() + "</li>")
    } else {
      sb.write_string("<li>Item " + i.to_string() + "</li>")
    }
  }
  sb.write_string("</ul>")
  sb.to_string()
}

///|
fn create_distance_html_attr_diff(count : Int, diff_count : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("<ul>")
  for i in 0..<count {
    if i < diff_count {
      sb.write_string("<li class=\"wrong-" + i.to_string() + "\">")
    } else {
      sb.write_string("<li class=\"item-" + i.to_string() + "\">")
    }
    sb.write_string("Item " + i.to_string() + "</li>")
  }
  sb.write_string("</ul>")
  sb.to_string()
}

///|
fn create_distance_html_missing_elements(count : Int, missing : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string("<ul>")
  for i in 0..<(count - missing) {
    sb.write_string("<li>Item " + i.to_string() + "</li>")
  }
  sb.write_string("</ul>")
  sb.to_string()
}

// =============================================================================
// Distance 0: Clean match (baseline)
// =============================================================================

///|
test "distance_0_clean_10_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(10)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="distance_0_clean_10_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_0_clean_50_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="distance_0_clean_50_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_0_clean_100_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(100)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="distance_0_clean_100_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Distance 1: Single text mismatch
// =============================================================================

///|
test "distance_1_text_10_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(10)
  let html = create_distance_html_text_diff(10, 1)
  let logger = StringBuilder::new()
  b.bench(name="distance_1_text_10_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_1_text_50_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_text_diff(50, 1)
  let logger = StringBuilder::new()
  b.bench(name="distance_1_text_50_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Distance 10%: 10% of texts differ
// =============================================================================

///|
test "distance_10pct_text_50_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_text_diff(50, 5)
  let logger = StringBuilder::new()
  b.bench(name="distance_10pct_text_50_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_10pct_text_100_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(100)
  let html = create_distance_html_text_diff(100, 10)
  let logger = StringBuilder::new()
  b.bench(name="distance_10pct_text_100_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Distance 50%: Half of texts differ
// =============================================================================

///|
test "distance_50pct_text_50_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_text_diff(50, 25)
  let logger = StringBuilder::new()
  b.bench(name="distance_50pct_text_50_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_50pct_text_100_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(100)
  let html = create_distance_html_text_diff(100, 50)
  let logger = StringBuilder::new()
  b.bench(name="distance_50pct_text_100_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Distance 100%: All texts differ
// =============================================================================

///|
test "distance_100pct_text_50_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_text_diff(50, 50)
  let logger = StringBuilder::new()
  b.bench(name="distance_100pct_text_50_nodes", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Attribute mismatches
// =============================================================================

///|
test "distance_attr_1_of_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree_with_attrs(50)
  let html = create_distance_html_attr_diff(50, 1)
  let logger = StringBuilder::new()
  b.bench(name="distance_attr_1_of_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_attr_25_of_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree_with_attrs(50)
  let html = create_distance_html_attr_diff(50, 25)
  let logger = StringBuilder::new()
  b.bench(name="distance_attr_25_of_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Missing elements (structural repair)
// =============================================================================

///|
test "distance_missing_1_of_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_missing_elements(50, 1)
  let logger = StringBuilder::new()
  b.bench(name="distance_missing_1_of_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_missing_10_of_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_missing_elements(50, 10)
  let logger = StringBuilder::new()
  b.bench(name="distance_missing_10_of_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_missing_25_of_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_missing_elements(50, 25)
  let logger = StringBuilder::new()
  b.bench(name="distance_missing_25_of_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Complete mismatch (worst case)
// =============================================================================

///|
test "distance_complete_mismatch_10" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(10)
  let html = "<span>Wrong</span><p>Content</p>"
  let logger = StringBuilder::new()
  b.bench(name="distance_complete_mismatch_10", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "distance_complete_mismatch_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = "<span>Wrong</span><p>Content</p>"
  let logger = StringBuilder::new()
  b.bench(name="distance_complete_mismatch_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Baseline: Full re-render comparison
// =============================================================================

///|
test "baseline_full_render_10_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(10)
  b.bench(name="baseline_full_render_10_nodes", fn() {
    b.keep(@client.render_vnode_to_dom(node))
  })
}

///|
test "baseline_full_render_50_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  b.bench(name="baseline_full_render_50_nodes", fn() {
    b.keep(@client.render_vnode_to_dom(node))
  })
}

///|
test "baseline_full_render_100_nodes" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(100)
  b.bench(name="baseline_full_render_100_nodes", fn() {
    b.keep(@client.render_vnode_to_dom(node))
  })
}

// =============================================================================
// Smart Hydrate Benchmarks (with heuristics)
// =============================================================================

///|
test "smart_hydrate_10_nodes_clean" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(10)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="smart_hydrate_10_nodes_clean", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.smart_hydrate(container, node, logger~))
  })
}

///|
test "smart_hydrate_50_nodes_clean" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="smart_hydrate_50_nodes_clean", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.smart_hydrate(container, node, logger~))
  })
}

///|
test "smart_hydrate_60_nodes_fallback" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(60)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="smart_hydrate_60_nodes_fallback", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.smart_hydrate(container, node, logger~))
  })
}

///|
test "smart_hydrate_100_nodes_fallback" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(100)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="smart_hydrate_100_nodes_fallback", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.smart_hydrate(container, node, logger~))
  })
}

///|
test "smart_hydrate_50_nodes_low_ratio" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = create_distance_html_missing_elements(50, 45)
  let logger = StringBuilder::new()
  b.bench(name="smart_hydrate_50_nodes_low_ratio", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.smart_hydrate(container, node, logger~))
  })
}

///|
test "smart_hydrate_50_nodes_mismatch" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_distance_tree(50)
  let html = "<span>Wrong</span>"
  let logger = StringBuilder::new()
  b.bench(name="smart_hydrate_50_nodes_mismatch", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.smart_hydrate(container, node, logger~))
  })
}
