///|
/// Styled Disclosure Component
///
/// A styled disclosure (show/hide) widget with icon and animated content.
///
/// Class names (BEM):
/// - .disclosure           - Root container
/// - .disclosure__trigger  - Trigger button
/// - .disclosure__icon     - Expand/collapse icon
/// - .disclosure__panel    - Content panel
/// - .disclosure__content  - Inner content wrapper (for animation)
///
/// Data attributes:
/// - [data-state="open"|"closed"]

///|
/// Slots for the disclosure component
pub(all) struct DisclosureSlots {
  root : String
  trigger : String
  icon : String
  panel : String
  content : String
}

///|
/// Default BEM class names for disclosure
pub fn disclosure_slots() -> DisclosureSlots {
  {
    root: "disclosure",
    trigger: "disclosure__trigger",
    icon: "disclosure__icon",
    panel: "disclosure__panel",
    content: "disclosure__content",
  }
}

///|
/// Create a styled disclosure component.
///
/// Parameters:
/// - id: Base ID for the disclosure
/// - expanded: Signal containing the expanded state
/// - trigger_text: Text for the trigger button
/// - children: Content to show/hide
/// - class: Additional CSS class
pub fn disclosure(
  id : String,
  expanded : @resource.Signal[Bool],
  trigger_text : String,
  children : Array[@luna.Node[@js.Any]],
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = disclosure_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }
  let button_id = id + "-trigger"
  let panel_id = id + "-panel"

  // Get headless props
  let trigger_props = @headless.use_disclosure_trigger(
    button_id, panel_id, expanded,
  )
  let panel_props = @headless.use_disclosure_panel(
    panel_id, button_id, expanded,
  )

  // Trigger button with styling
  let trigger = @luna.h(
    "button",
    trigger_props.attrs +
    [
      ("class", @luna.attr_static(slots.trigger)),
      (
        "data-state",
        @luna.attr_dynamic(fn() {
          if expanded.get() {
            "open"
          } else {
            "closed"
          }
        }),
      ),
    ],
    [
      @luna.h(
        "span",
        [
          ("class", @luna.attr_static(slots.icon)),
          ("aria-hidden", @luna.attr_static("true")),
        ],
        [@luna.text("\u{25BC}")], // ▼
      ),
      @luna.text(trigger_text),
    ],
  )

  // Panel with styling
  let panel = @luna.h(
    "div",
    panel_props.attrs +
    [
      ("class", @luna.attr_static(slots.panel)),
      (
        "data-state",
        @luna.attr_dynamic(fn() {
          if expanded.get() {
            "open"
          } else {
            "closed"
          }
        }),
      ),
    ],
    [@luna.h("div", [("class", @luna.attr_static(slots.content))], children)],
  )
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(root_class)),
      (
        "data-state",
        @luna.attr_dynamic(fn() {
          if expanded.get() {
            "open"
          } else {
            "closed"
          }
        }),
      ),
    ],
    [trigger, panel],
  )
}

///|
/// Get the CSS for the styled disclosure.
pub fn disclosure_css() -> String {
  let css =
    #|/* Disclosure - Default Theme */
    #|.disclosure {
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.5rem;
    #|  background: var(--background);
    #|  overflow: hidden;
    #|}
    #|
    #|.disclosure__trigger {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|  width: 100%;
    #|  padding: 1rem;
    #|  border: none;
    #|  background: transparent;
    #|  color: var(--foreground);
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  text-align: left;
    #|  cursor: pointer;
    #|  transition: background-color 0.15s;
    #|}
    #|
    #|.disclosure__trigger:hover {
    #|  background: var(--muted);
    #|}
    #|
    #|.disclosure__trigger:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.disclosure__icon {
    #|  flex-shrink: 0;
    #|  font-size: 0.625rem;
    #|  color: var(--muted-foreground);
    #|  transition: transform 0.2s ease-out;
    #|}
    #|
    #|.disclosure__trigger[data-state="open"] .disclosure__icon {
    #|  transform: rotate(180deg);
    #|}
    #|
    #|.disclosure__panel {
    #|  display: grid;
    #|  grid-template-rows: 0fr;
    #|  overflow: hidden;
    #|  transition: grid-template-rows 0.2s ease-out;
    #|}
    #|
    #|.disclosure__panel[data-state="open"] {
    #|  grid-template-rows: 1fr;
    #|}
    #|
    #|.disclosure__content {
    #|  min-height: 0;
    #|  overflow: hidden;
    #|}
    #|
    #|.disclosure__panel[data-state="open"] .disclosure__content {
    #|  padding: 0 1rem 1rem 2rem;
    #|}
    #|
    #|.disclosure__panel[data-state="closed"] .disclosure__content {
    #|  padding: 0 1rem 0 2rem;
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .disclosure__trigger,
    #|  .disclosure__icon,
    #|  .disclosure__panel {
    #|    transition: none;
    #|  }
    #|}
  css
}
