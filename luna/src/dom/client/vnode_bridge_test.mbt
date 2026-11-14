///|
extern "js" fn click_element(el : @js_dom.Element) -> Unit =
  #|(el) => el.click()

///|
test "vnode puts a reactive core node inside the element DSL" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let open = @resource.signal(false)
  let toggle = @luna.h(
    "button",
    [
      ("id", @luna.attr_static("toggle")),
      (
        "aria-expanded",
        @luna.attr_dynamic(fn() { open.get().to_string() }),
      ),
      (
        "onClick",
        @luna.attr_handler(@luna.handler(fn(_) { open.set(!open.get()) })),
      ),
    ],
    [@luna.text("Menu")],
  )
  let page = @element.div(id="bar", [
    @client.vnode(toggle),
    @element.span([@element.text("after")]),
  ])
  @element.render_to(container, page)
  assert_eq(
    get_inner_html(container),
    "<div id=\"bar\"><button id=\"toggle\" aria-expanded=\"false\">Menu</button><span>after</span></div>",
  )
  let button = match @js_dom.document().getElementById("toggle") {
    Some(el) => el
    None => fail("button not rendered")
  }
  click_element(button)
  assert_eq(button.getAttribute("aria-expanded"), Some("true"))
  open.set(false)
  assert_eq(button.getAttribute("aria-expanded"), Some("false"))
}

///|
test "vnode effects are disposed with the surrounding show" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @resource.signal(true)
  let label = @resource.signal("a")
  let runs = Ref(0)
  let node = @element.show(fn() { visible.get() }, fn() {
    @client.vnode(
      @luna.h("p", [], [
        @luna.text_dyn(fn() {
          runs.val += 1
          label.get()
        }),
      ]),
    )
  })
  @element.render_to(container, node)
  assert_true(get_inner_html(container).contains("<p>a</p>"))
  let before = runs.val
  visible.set(false)
  label.set("b")
  assert_eq(runs.val, before)
  assert_false(get_inner_html(container).contains("<p>"))
}
