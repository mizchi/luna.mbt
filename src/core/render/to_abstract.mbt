// Luna Node to AbstractNode Converter
//
// Converts Luna's VNode tree to framework-agnostic AbstractNode.
// Evaluates dynamic content at conversion time.

///|
/// Convert Luna Node to AbstractNode
/// Dynamic content (DynamicText, Show, For, Component) is evaluated at conversion time.
pub fn[E, A : Show] to_abstract(node : @luna.Node[E, A]) -> AbstractNode {
  match node {
    Text(content) => Text(content)
    DynamicText(getter) => Text(getter())
    RawHtml(html) => RawHtml(html)
    Fragment(children) => Fragment(children.map(to_abstract))
    Element(elem) => convert_element(elem)
    Show(condition~, child~) =>
      if condition() {
        to_abstract(child())
      } else {
        Fragment([])
      }
    For(render~) => Fragment(render().map(to_abstract))
    Component(render~) => to_abstract(render())
    Island(island) => convert_island(island)
    WcIsland(wc_island) => convert_wc_island(wc_island)
    InternalRef(iref) => convert_internal_ref(iref)
    Async(async_node) =>
      // In sync conversion, use fallback
      to_abstract((async_node.fallback)())
    ErrorBoundary(boundary) =>
      to_abstract((boundary.children)()) catch {
        err => {
          let reset = fn() { () }
          to_abstract((boundary.fallback)(err, reset)) catch {
            _ => Fragment([])
          }
        }
      }
    Switch(switch_node) => {
      for case_ in switch_node.cases {
        if (case_.when)() {
          return to_abstract((case_.render)())
        }
      }
      match switch_node.fallback {
        Some(fallback_fn) => to_abstract(fallback_fn())
        None => Fragment([])
      }
    }
  }
}

///|
/// Convert Luna Element to AbstractNode Element
fn[E, A : Show] convert_element(elem : @luna.VElement[E, A]) -> AbstractNode {
  let attrs = elem.attrs.map(convert_attr)
  let children = elem.children.map(to_abstract)
  element(elem.tag, attrs, children)
}

///|
/// Convert Luna Attr to AbstractNode AttrValue
fn[E, A : Show] convert_attr(
  attr : (String, @luna.Attr[E, A]),
) -> (String, AttrValue) {
  let (name, value) = attr
  match value {
    VStatic(s) => (name, Str(s.to_string()))
    VDynamic(getter) => (name, Str(getter().to_string()))
    VHandler(_) => (name, Str(""))
    VAction(action_name) =>
      ("data-action-" + name[2:].to_string(), Str(action_name)) catch {
        _ => (name, Str(action_name))
      }
  }
}

///|
/// Convert Luna TriggerType to AbstractNode HydrationTrigger
fn convert_trigger(trigger : @luna.TriggerType) -> HydrationTrigger {
  match trigger {
    Load => Load
    Idle => Idle
    Visible => Visible
    Media(query) => Media(query)
    None => Load
  }
}

///|
/// Convert Luna Island to AbstractNode Component
fn[E, A : Show] convert_island(island : @luna.VIsland[E, A]) -> AbstractNode {
  let trigger = convert_trigger(island.trigger)
  let mode = Hydration(trigger)
  let children = island.children.map(to_abstract)
  // Parse state JSON
  let props : Json = @json.parse(island.state) catch { _ => Json::null() }
  component(island.id, props, mode, children)
}

///|
/// Convert Luna WcIsland to AbstractNode Component
fn[E, A : Show] convert_wc_island(
  island : @luna.VWcIsland[E, A],
) -> AbstractNode {
  let trigger = convert_trigger(island.trigger)
  let mode = Hydration(trigger)
  let children = island.children.map(to_abstract)
  let props : Json = @json.parse(island.state) catch { _ => Json::null() }
  component(island.name, props, mode, children)
}

///|
/// Convert Luna InternalRef to AbstractNode Component
fn[E, A : Show] convert_internal_ref(
  iref : @luna.VInternalRef[E, A],
) -> AbstractNode {
  let trigger = convert_trigger(iref.trigger)
  let mode = Hydration(trigger)
  let children = iref.children.map(to_abstract)
  let props : Json = @json.parse(iref.state) catch { _ => Json::null() }
  // Extract component name from URL
  let name = extract_wc_name_from_url(iref.url)
  component(name, props, mode, children)
}
