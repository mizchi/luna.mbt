///|
fn button_style() -> @css.Style {
  @css.create([
    @css.rule(@css.Color, "var(--text)"),
    @css.rule(@css.BackgroundColor, "var(--surface)"),
    @css.rule(@css.Width, "var(--width)"),
    @css.rule(@css.FontSize, "12px"),
    @css.rule_media("min-width:768px", @css.FontSize, "16px"),
    @css.rule_media("min-width:1024px", @css.FontSize, "20px"),
    @css.rule_on(@css.Hover, @css.Color, "green"),
    @css.rule_on(@css.NthChild("2n+1"), @css.FontWeight, "700"),
    @css.rule_on(@css.Before, @css.Content, "\"\""),
    @css.rule_when("min-width:1024px", @css.Hover, @css.Color, "purple"),
  ])
}

///|
fn light_theme() -> @css.Style {
  @css.create_theme([("--surface", "white"), ("--text", "black")]) catch {
    _ => abort("invalid fixture theme")
  }
}

///|
fn dark_theme() -> @css.Style {
  @css.create_theme([("--surface", "black"), ("--text", "white")]) catch {
    _ => abort("invalid fixture theme")
  }
}

///|
pub fn css_text() -> String {
  @css.stylesheet([button_style(), light_theme(), dark_theme()])
}

///|
fn button_attrs(active : Bool) -> @css.StyleAttrs {
  let style = button_style().with_vars([
    ("--width", if active { "160px" } else { "120px" }),
  ]) catch {
    _ => abort("invalid fixture variable")
  }
  @css.attrs([style])
}

///|
fn[E] demo_node(
  active : () -> Bool,
  on_click : @core.EventHandler[E],
) -> @core.Node[E, String] {
  @core.h(
    "div",
    [
      (
        "class",
        @core.attr_dynamic(fn() {
          @css.attrs([light_theme(), dark_theme().when(active())]).class_name
        }),
      ),
    ],
    [
      @core.h(
        "button",
        [
          (
            "class",
            @core.attr_dynamic(fn() { button_attrs(active()).class_name }),
          ),
          ("style", @core.attr_dynamic(fn() { button_attrs(active()).style })),
          ("onClick", @core.attr_handler(on_click)),
        ],
        [@core.text("Toggle theme")],
      ),
    ],
  )
}

///|
pub fn render_html() -> String {
  let content = demo_node(fn() { false }, @core.event_handler())
  let content_html = @render.render_to_string_with_hydration(content)
  let container : @core.Node[Unit, String] = @core.h("section", [], [
    @core.raw_html(content_html),
  ])
  let island = @core.wc_island("style-demo", "/demo.js", css_text(), "{}", [
    container,
  ])
  @render.render_to_string(island).html
}

///|
pub fn hydrate_demo(root : @js_dom.Element) -> Unit {
  let active = @signals.signal(false)
  let node = demo_node(
    fn() { active.get() },
    @core.handler(fn(_ : @js.Any) { active.set(!active.get()) }),
  )
  ignore(@client.hydrate(root, node))
}
