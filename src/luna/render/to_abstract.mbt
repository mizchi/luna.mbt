// Luna Node to AbstractNode Converter
//
// Converts Luna's VNode tree to framework-agnostic AbstractNode.
// Evaluates dynamic content at conversion time.

///|
/// Convert Luna Node to AbstractNode
/// Dynamic content (DynamicText, Show, For, Component) is evaluated at conversion time.
pub fn[E] to_abstract(node : @luna.Node[E]) -> @abstract.AbstractNode {
  match node {
    Text(content) => @abstract.Text(content)
    DynamicText(getter) => @abstract.Text(getter())
    RawHtml(html) => @abstract.RawHtml(html)
    Fragment(children) => @abstract.Fragment(children.map(to_abstract))
    Element(elem) => convert_element(elem)
    Show(condition~, child~) =>
      if condition() {
        to_abstract(child())
      } else {
        @abstract.Fragment([])
      }
    For(render~) => @abstract.Fragment(render().map(to_abstract))
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
            _ => @abstract.Fragment([])
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
        None => @abstract.Fragment([])
      }
    }
  }
}

///|
/// Convert Luna Element to AbstractNode Element
fn[E] convert_element(elem : @luna.VElement[E]) -> @abstract.AbstractNode {
  let attrs = elem.attrs.map(convert_attr)
  let children = elem.children.map(to_abstract)
  @abstract.element(elem.tag, attrs, children)
}

///|
/// Convert Luna Attr to AbstractNode AttrValue
fn[E] convert_attr(
  attr : (String, @luna.Attr[E]),
) -> (String, @abstract.AttrValue) {
  let (name, value) = attr
  match value {
    VStatic(s) => (name, @abstract.Str(s))
    VDynamic(getter) => (name, @abstract.Str(getter()))
    VHandler(_) => (name, @abstract.Str(""))
    VAction(action_name) =>
      ("data-action-" + name[2:].to_string(), @abstract.Str(action_name)) catch {
        _ => (name, @abstract.Str(action_name))
      }
  }
}

///|
/// Convert Luna TriggerType to AbstractNode HydrationTrigger
fn convert_trigger(trigger : @luna.TriggerType) -> @abstract.HydrationTrigger {
  match trigger {
    Load => @abstract.Load
    Idle => @abstract.Idle
    Visible => @abstract.Visible
    Media(query) => @abstract.Media(query)
    None => @abstract.Load
  }
}

///|
/// Convert Luna Island to AbstractNode Component
fn[E] convert_island(island : @luna.VIsland[E]) -> @abstract.AbstractNode {
  let trigger = convert_trigger(island.trigger)
  let mode = @abstract.Hydration(trigger)
  let children = island.children.map(to_abstract)
  // Parse state JSON
  let props : Json = @json.parse(island.state) catch { _ => Json::null() }
  @abstract.component(island.id, props, mode, children)
}

///|
/// Convert Luna WcIsland to AbstractNode Component
fn[E] convert_wc_island(island : @luna.VWcIsland[E]) -> @abstract.AbstractNode {
  let trigger = convert_trigger(island.trigger)
  let mode = @abstract.Hydration(trigger)
  let children = island.children.map(to_abstract)
  let props : Json = @json.parse(island.state) catch { _ => Json::null() }
  @abstract.component(island.name, props, mode, children)
}

///|
/// Convert Luna InternalRef to AbstractNode Component
fn[E] convert_internal_ref(
  iref : @luna.VInternalRef[E],
) -> @abstract.AbstractNode {
  let trigger = convert_trigger(iref.trigger)
  let mode = @abstract.Hydration(trigger)
  let children = iref.children.map(to_abstract)
  let props : Json = @json.parse(iref.state) catch { _ => Json::null() }
  // Extract component name from URL
  let name = @utils.extract_wc_name_from_url(iref.url)
  @abstract.component(name, props, mode, children)
}
