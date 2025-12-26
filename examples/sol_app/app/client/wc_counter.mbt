///| WC Counter Client Component with CSS

///|

///| Demonstrates CSS injection pattern for Web Components.

///| The same CSS is used for SSR (Shadow DOM) and hydration.

///|
/// CSS for the WC counter - exported for server-side access
pub let wc_counter_css : String =
  #|:host { display: block; }
  #|.counter { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; }
  #|.count-display { font-size: 2rem; font-weight: bold; color: #333; }
  #|.buttons { margin-top: 1rem; }
  #|.buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0 0.5rem; cursor: pointer; border: 1px solid #666; border-radius: 4px; background: #f0f0f0; }
  #|.buttons button:hover { background: #e0e0e0; }

///|
/// Props for WC Counter
pub(all) struct WcCounterProps {
  initial_count : Int
} derive(ToJson, FromJson)

///| WC Counter component

///|
/// Returns DomNode with use_style for CSS injection
pub fn wc_counter(props : WcCounterProps) -> DomNode {
  let count = @signal.signal(props.initial_count)

  // CSS injection using use_style
  // - During SSR: CSS is already in Shadow DOM <style> tag (server-side rendered)
  // - During CSR: use_style injects CSS into Shadow DOM or document.head
  // Using ref to get the root element and inject style
  div(class="counter", ref_=fn(el) { use_style(wc_counter_css, el) }, [
    span(class="count-display", [text_of(count)]),
    div(class="buttons", [
      button(class="dec", on=events().click(_ => count.update(n => n - 1)), [
        text("-"),
      ]),
      button(class="inc", on=events().click(_ => count.update(n => n + 1)), [
        text("+"),
      ]),
    ]),
  ])
}
