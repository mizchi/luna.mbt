// Luna Testing - Assertion Helpers
// テストで使用するアサーション関数群

// =============================================================================
// Tag Assertions
// =============================================================================

///|
/// 要素が特定のタグを持つことを検証
pub fn[E] assert_tag(node : @luna.Node[E], expected : String) -> Unit {
  match get_tag(node) {
    Some(tag) =>
      if tag != expected {
        abort("Expected tag '\{expected}', but got '\{tag}'")
      }
    None =>
      abort(
        "Expected Element with tag '\{expected}', but got \{node_type_name(node)}",
      )
  }
}

///|
/// 要素がElementであることを検証
pub fn[E] assert_is_element(node : @luna.Node[E]) -> Unit {
  if not(is_element(node)) {
    abort("Expected Element, but got \{node_type_name(node)}")
  }
}

///|
/// 要素がTextであることを検証
pub fn[E] assert_is_text(node : @luna.Node[E]) -> Unit {
  if not(is_text(node)) {
    abort("Expected Text, but got \{node_type_name(node)}")
  }
}

// =============================================================================
// Attribute Assertions
// =============================================================================

///|
/// 静的属性の値を検証
pub fn[E] assert_static_attr(
  node : @luna.Node[E],
  name : String,
  expected : String,
) -> Unit {
  match get_static_attr(node, name) {
    Some(value) =>
      if value != expected {
        abort("Attribute '\{name}': expected '\{expected}', but got '\{value}'")
      }
    None => abort("Static attribute '\{name}' not found")
  }
}

///|
/// 動的属性の現在値を検証
pub fn[E] assert_dynamic_attr(
  node : @luna.Node[E],
  name : String,
  expected : String,
) -> Unit {
  match get_dynamic_attr(node, name) {
    Some(value) =>
      if value != expected {
        abort(
          "Dynamic attribute '\{name}': expected '\{expected}', but got '\{value}'",
        )
      }
    None => abort("Dynamic attribute '\{name}' not found")
  }
}

///|
/// 属性値を検証（静的・動的両対応）
pub fn[E] assert_attr(
  node : @luna.Node[E],
  name : String,
  expected : String,
) -> Unit {
  match get_attr_value(node, name) {
    Some(value) =>
      if value != expected {
        abort("Attribute '\{name}': expected '\{expected}', but got '\{value}'")
      }
    None => abort("Attribute '\{name}' not found")
  }
}

///|
/// 属性が存在することを検証
pub fn[E] assert_has_attr(node : @luna.Node[E], name : String) -> Unit {
  if get_attr(node, name) is None {
    abort("Expected attribute '\{name}' to exist")
  }
}

///|
/// イベントハンドラが存在することを検証
pub fn[E] assert_has_handler(node : @luna.Node[E], name : String) -> Unit {
  if not(has_handler(node, name)) {
    abort("Expected handler '\{name}' to exist")
  }
}

// =============================================================================
// Text Assertions
// =============================================================================

///|
/// テキストコンテンツを検証
pub fn[E] assert_text(node : @luna.Node[E], expected : String) -> Unit {
  let actual = get_all_text(node)
  if actual != expected {
    abort("Expected text '\{expected}', but got '\{actual}'")
  }
}

///|
/// テキストが含まれることを検証
pub fn[E] assert_text_contains(node : @luna.Node[E], expected : String) -> Unit {
  let actual = get_all_text(node)
  if not(actual.contains(expected)) {
    abort("Expected text to contain '\{expected}', but got '\{actual}'")
  }
}

///|
/// テキストが含まれないことを検証
pub fn[E] assert_text_not_contains(
  node : @luna.Node[E],
  unexpected : String,
) -> Unit {
  let actual = get_all_text(node)
  if actual.contains(unexpected) {
    abort("Expected text to not contain '\{unexpected}', but got '\{actual}'")
  }
}

// =============================================================================
// Structure Assertions
// =============================================================================

///|
/// 子要素数を検証
pub fn[E] assert_child_count(node : @luna.Node[E], expected : Int) -> Unit {
  let actual = child_count(node)
  if actual != expected {
    abort("Expected \{expected} children, but got \{actual}")
  }
}

///|
/// 特定のタグを持つ要素が存在することを検証
pub fn[E] assert_has_element(node : @luna.Node[E], tag : String) -> Unit {
  if find_by_tag(node, tag) is None {
    abort("Expected to find element with tag '\{tag}'")
  }
}

///|
/// 特定のタグを持つ要素が存在しないことを検証
pub fn[E] assert_no_element(node : @luna.Node[E], tag : String) -> Unit {
  if find_by_tag(node, tag) is Some(_) {
    abort("Expected no element with tag '\{tag}', but found one")
  }
}

///|
/// 特定のタグを持つ要素の数を検証
pub fn[E] assert_element_count(
  node : @luna.Node[E],
  tag : String,
  expected : Int,
) -> Unit {
  let actual = find_all_by_tag(node, tag).length()
  if actual != expected {
    abort("Expected \{expected} '\{tag}' elements, but found \{actual}")
  }
}

// =============================================================================
// Show/For Assertions
// =============================================================================

///|
/// Show条件がtrueのとき子要素が存在することを検証
pub fn[E] assert_show_visible(node : @luna.Node[E]) -> Unit {
  match node {
    @luna.Show(condition~, ..) =>
      if not(condition()) {
        abort("Expected Show to be visible, but condition is false")
      }
    _ => abort("Expected Show node, but got \{node_type_name(node)}")
  }
}

///|
/// Show条件がfalseのとき子要素が存在しないことを検証
pub fn[E] assert_show_hidden(node : @luna.Node[E]) -> Unit {
  match node {
    @luna.Show(condition~, ..) =>
      if condition() {
        abort("Expected Show to be hidden, but condition is true")
      }
    _ => abort("Expected Show node, but got \{node_type_name(node)}")
  }
}

///|
/// Forのレンダリング結果の要素数を検証
pub fn[E] assert_for_count(node : @luna.Node[E], expected : Int) -> Unit {
  match node {
    @luna.For(render~) => {
      let actual = render().length()
      if actual != expected {
        abort("Expected For to render \{expected} items, but got \{actual}")
      }
    }
    _ => abort("Expected For node, but got \{node_type_name(node)}")
  }
}
