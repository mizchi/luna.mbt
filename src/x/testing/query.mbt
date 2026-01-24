// Luna Testing - VNode Query Helpers
// DOM非依存でVNode構造をクエリするためのヘルパー関数群

// =============================================================================
// Basic Query Helpers
// =============================================================================

///|
/// VNode から Element を取得（Element でなければ None）
pub fn[E] get_element(
  node : @luna.Node[E, String],
) -> @luna.VElement[E, String]? {
  match node {
    @core.Element(elem) => Some(elem)
    _ => None
  }
}

///|
/// VNode から Text コンテンツを取得
pub fn[E] get_text(node : @luna.Node[E, String]) -> String? {
  match node {
    @core.Text(s) => Some(s)
    _ => None
  }
}

///|
/// VNode から DynamicText の現在値を取得
pub fn[E] get_dynamic_text(node : @luna.Node[E, String]) -> String? {
  match node {
    @core.DynamicText(getter) => Some(getter())
    _ => None
  }
}

///|
/// VNode のタグ名を取得（Element でなければ None）
pub fn[E] get_tag(node : @luna.Node[E, String]) -> String? {
  match node {
    @core.Element(elem) => Some(elem.tag)
    _ => None
  }
}

///|
/// VNode の子要素数を取得
pub fn[E] child_count(node : @luna.Node[E, String]) -> Int {
  match node {
    @core.Element(elem) => elem.children.length()
    @core.Fragment(children) => children.length()
    _ => 0
  }
}

///|
/// VNode の子要素を取得（Show/For/Component を透過的に展開）
pub fn[E] get_children(
  node : @luna.Node[E, String],
) -> Array[@luna.Node[E, String]] {
  match node {
    @core.Element(elem) => elem.children
    @core.Fragment(children) => children
    @core.Show(condition~, child~) => if condition() { [child()] } else { [] }
    @core.For(render~) => render()
    @core.Component(render~) => [render()]
    _ => []
  }
}

// =============================================================================
// Attribute Query Helpers
// =============================================================================

///|
/// VNode から属性を取得
pub fn[E] get_attr(
  node : @luna.Node[E, String],
  name : String,
) -> @luna.Attr[E, String]? {
  match node {
    @core.Element(elem) => {
      for attr in elem.attrs {
        if attr.0 == name {
          return Some(attr.1)
        }
      }
      None
    }
    _ => None
  }
}

///|
/// 静的属性の値を取得
pub fn[E] get_static_attr(
  node : @luna.Node[E, String],
  name : String,
) -> String? {
  match get_attr(node, name) {
    Some(@core.VStatic(value)) => Some(value)
    _ => None
  }
}

///|
/// 動的属性の現在値を取得
pub fn[E] get_dynamic_attr(
  node : @luna.Node[E, String],
  name : String,
) -> String? {
  match get_attr(node, name) {
    Some(@core.VDynamic(getter)) => Some(getter())
    _ => None
  }
}

///|
/// 属性値を取得（静的・動的両対応）
pub fn[E] get_attr_value(
  node : @luna.Node[E, String],
  name : String,
) -> String? {
  match get_attr(node, name) {
    Some(@core.VStatic(value)) => Some(value)
    Some(@core.VDynamic(getter)) => Some(getter())
    _ => None
  }
}

///|
/// イベントハンドラを取得
pub fn[E] get_handler(
  node : @luna.Node[E, String],
  name : String,
) -> @luna.EventHandler[E]? {
  match get_attr(node, name) {
    Some(@core.VHandler(h)) => Some(h)
    _ => None
  }
}

///|
/// VNode がハンドラを持っているか確認
pub fn[E] has_handler(node : @luna.Node[E, String], name : String) -> Bool {
  get_handler(node, name) is Some(_)
}

///|
/// VNode の全属性名を取得
pub fn[E] get_attr_names(node : @luna.Node[E, String]) -> Array[String] {
  match node {
    @core.Element(elem) => elem.attrs.map(fn(attr) { attr.0 })
    _ => []
  }
}

// =============================================================================
// Search Helpers
// =============================================================================

///|
/// タグ名で最初の要素を検索（深さ優先）
pub fn[E] find_by_tag(
  node : @luna.Node[E, String],
  tag : String,
) -> @luna.Node[E, String]? {
  match node {
    @core.Element(elem) => {
      if elem.tag == tag {
        return Some(node)
      }
      for child in elem.children {
        if find_by_tag(child, tag) is Some(found) {
          return Some(found)
        }
      }
      None
    }
    @core.Fragment(children) => {
      for child in children {
        if find_by_tag(child, tag) is Some(found) {
          return Some(found)
        }
      }
      None
    }
    @core.Show(condition~, child~) =>
      if condition() {
        find_by_tag(child(), tag)
      } else {
        None
      }
    @core.For(render~) => {
      for child in render() {
        if find_by_tag(child, tag) is Some(found) {
          return Some(found)
        }
      }
      None
    }
    @core.Component(render~) => find_by_tag(render(), tag)
    _ => None
  }
}

///|
/// タグ名で全ての要素を検索（深さ優先）
pub fn[E] find_all_by_tag(
  node : @luna.Node[E, String],
  tag : String,
) -> Array[@luna.Node[E, String]] {
  let results : Array[@luna.Node[E, String]] = []
  find_all_by_tag_impl(node, tag, results)
  results
}

///|
fn[E] find_all_by_tag_impl(
  node : @luna.Node[E, String],
  tag : String,
  results : Array[@luna.Node[E, String]],
) -> Unit {
  match node {
    @core.Element(elem) => {
      if elem.tag == tag {
        results.push(node)
      }
      for child in elem.children {
        find_all_by_tag_impl(child, tag, results)
      }
    }
    @core.Fragment(children) =>
      for child in children {
        find_all_by_tag_impl(child, tag, results)
      }
    @core.Show(condition~, child~) =>
      if condition() {
        find_all_by_tag_impl(child(), tag, results)
      }
    @core.For(render~) =>
      for child in render() {
        find_all_by_tag_impl(child, tag, results)
      }
    @core.Component(render~) => find_all_by_tag_impl(render(), tag, results)
    _ => ()
  }
}

///|
/// 属性値で要素を検索
pub fn[E] find_by_attr(
  node : @luna.Node[E, String],
  attr_name : String,
  attr_value : String,
) -> @luna.Node[E, String]? {
  match node {
    @core.Element(elem) => {
      for attr in elem.attrs {
        if attr.0 == attr_name {
          match attr.1 {
            @core.VStatic(v) => if v == attr_value { return Some(node) }
            @core.VDynamic(getter) =>
              if getter() == attr_value {
                return Some(node)
              }
            _ => ()
          }
        }
      }
      for child in elem.children {
        if find_by_attr(child, attr_name, attr_value) is Some(found) {
          return Some(found)
        }
      }
      None
    }
    @core.Fragment(children) => {
      for child in children {
        if find_by_attr(child, attr_name, attr_value) is Some(found) {
          return Some(found)
        }
      }
      None
    }
    @core.Show(condition~, child~) =>
      if condition() {
        find_by_attr(child(), attr_name, attr_value)
      } else {
        None
      }
    @core.For(render~) => {
      for child in render() {
        if find_by_attr(child, attr_name, attr_value) is Some(found) {
          return Some(found)
        }
      }
      None
    }
    @core.Component(render~) => find_by_attr(render(), attr_name, attr_value)
    _ => None
  }
}

///|
/// 述語関数で要素を検索
pub fn[E] find_by(
  node : @luna.Node[E, String],
  predicate : (@luna.Node[E, String]) -> Bool,
) -> @luna.Node[E, String]? {
  if predicate(node) {
    return Some(node)
  }
  for child in get_children(node) {
    if find_by(child, predicate) is Some(found) {
      return Some(found)
    }
  }
  None
}

///|
/// 述語関数で全ての要素を検索
pub fn[E] find_all_by(
  node : @luna.Node[E, String],
  predicate : (@luna.Node[E, String]) -> Bool,
) -> Array[@luna.Node[E, String]] {
  let results : Array[@luna.Node[E, String]] = []
  find_all_by_impl(node, predicate, results)
  results
}

///|
fn[E] find_all_by_impl(
  node : @luna.Node[E, String],
  predicate : (@luna.Node[E, String]) -> Bool,
  results : Array[@luna.Node[E, String]],
) -> Unit {
  if predicate(node) {
    results.push(node)
  }
  for child in get_children(node) {
    find_all_by_impl(child, predicate, results)
  }
}

// =============================================================================
// Text Content Helpers
// =============================================================================

///|
/// VNode 以下の全テキストコンテンツを取得
pub fn[E] get_all_text(node : @luna.Node[E, String]) -> String {
  let sb = StringBuilder::new()
  collect_text(node, sb)
  sb.to_string()
}

///|
fn[E] collect_text(node : @luna.Node[E, String], sb : StringBuilder) -> Unit {
  match node {
    @core.Text(s) => sb.write_string(s)
    @core.DynamicText(getter) => sb.write_string(getter())
    @core.Element(elem) =>
      for child in elem.children {
        collect_text(child, sb)
      }
    @core.Fragment(children) =>
      for child in children {
        collect_text(child, sb)
      }
    @core.Show(condition~, child~) =>
      if condition() {
        collect_text(child(), sb)
      }
    @core.For(render~) =>
      for child in render() {
        collect_text(child, sb)
      }
    @core.Component(render~) => collect_text(render(), sb)
    _ => ()
  }
}

///|
/// VNode にテキストが含まれるか確認
pub fn[E] contains_text(node : @luna.Node[E, String], text : String) -> Bool {
  get_all_text(node).contains(text)
}

// =============================================================================
// Type Helpers
// =============================================================================

///|
/// VNode のタイプ名を取得（デバッグ用）
pub fn[E] node_type_name(node : @luna.Node[E, String]) -> String {
  match node {
    @core.Element(_) => "Element"
    @core.Text(_) => "Text"
    @core.DynamicText(_) => "DynamicText"
    @core.Fragment(_) => "Fragment"
    @core.Show(..) => "Show"
    @core.For(..) => "For"
    @core.Component(..) => "Component"
    @core.Island(_) => "Island"
    @core.WcIsland(_) => "WcIsland"
    @core.Async(_) => "Async"
    @core.ErrorBoundary(_) => "ErrorBoundary"
    @core.Switch(_) => "Switch"
    @core.InternalRef(_) => "InternalRef"
    @core.RawHtml(_) => "RawHtml"
  }
}

///|
pub fn[E] is_element(node : @luna.Node[E, String]) -> Bool {
  node is @core.Element(_)
}

///|
pub fn[E] is_text(node : @luna.Node[E, String]) -> Bool {
  node is @core.Text(_)
}

///|
pub fn[E] is_dynamic_text(node : @luna.Node[E, String]) -> Bool {
  node is @core.DynamicText(_)
}

///|
pub fn[E] is_fragment(node : @luna.Node[E, String]) -> Bool {
  node is @core.Fragment(_)
}

///|
pub fn[E] is_show(node : @luna.Node[E, String]) -> Bool {
  node is @core.Show(..)
}

///|
pub fn[E] is_for(node : @luna.Node[E, String]) -> Bool {
  node is @core.For(..)
}

///|
pub fn[E] is_component(node : @luna.Node[E, String]) -> Bool {
  node is @core.Component(..)
}
