///|
/// VNodes share the JS API's signal/owner runtime with DOM components.
pub fn ssr_text(content : String) -> @core.Node[@js.Any, String] {
  @core.text(content)
}

///|
pub fn ssr_text_dyn(content : () -> String) -> @core.Node[@js.Any, String] {
  @core.text_dyn(content)
}

///|
pub fn ssr_fragment(
  children : Array[@core.Node[@js.Any, String]],
) -> @core.Node[@js.Any, String] {
  @core.fragment(children)
}

///|
pub fn ssr_element(
  tag : String,
  attrs : Array[(String, @element.AttrValue)],
  children : Array[@core.Node[@js.Any, String]],
) -> @core.Node[@js.Any, String] {
  @core.h(
    tag,
    attrs.map(fn(attr) {
      let (name, value) = attr
      let value = match value {
        Static(value) => @core.attr_static(value)
        Dynamic(getter) => @core.attr_dynamic(getter)
        Handler(handler) => @core.attr_handler(@core.handler(handler))
      }
      (name, value)
    }),
    children,
  )
}

///|
pub fn ssr_render(node : @core.Node[@js.Any, String]) -> String {
  @ssr.render_to_string_with_hydration(node)
}

///|
/// Return a mismatch message and the root disposer; never silently remount.
pub fn ssr_hydrate(
  container : @js_dom.Element,
  node : @core.Node[@js.Any, String],
) -> (String, () -> Unit) {
  let (result, dispose) = @client.hydrate_with_dispose(
    container,
    node,
    recover_on_mismatch=false,
    warn_on_mismatch=false,
  )
  (if result.is_mismatch() { result.get_message() } else { "" }, dispose)
}
