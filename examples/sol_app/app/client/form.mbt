// Contact Form Client Component
// Demonstrates data binding and form submission

///|
/// Props passed from server
pub(all) struct ContactFormProps {
  action : String
  initial_name : String
  initial_email : String
} derive(ToJson, FromJson)

///|
/// Contact form component with two-way data binding
pub fn contact_form(props : ContactFormProps) -> DomNode {
  // Signals for form state
  let name = @signal.signal(props.initial_name)
  let email = @signal.signal(props.initial_email)
  let submitted = @signal.signal(false)
  let result_msg = @signal.signal("")

  // Form submit handler
  let handle_submit : @element.FormHandler = fn(e) {
    e.preventDefault()
    submitted.set(true)
    result_msg.set("Submitting...")
    // In real app, would POST to server
    // For demo, just show the values
    let msg = "Submitted: name=\{name.get()}, email=\{email.get()}"
    result_msg.set(msg)
  }

  // Input handlers for two-way binding
  let on_name_input : @element.InputHandler = fn(e) {
    let target : @js_dom.HTMLInputElement = e.target() |> @js.identity
    name.set(target.value)
  }
  let on_email_input : @element.InputHandler = fn(e) {
    let target : @js_dom.HTMLInputElement = e.target() |> @js.identity
    email.set(target.value)
  }
  form(
    class="contact-form",
    on=events().submit(handle_submit),
    attrs=[
      ("action", @element.AttrString(props.action)),
      ("method", @element.AttrString("POST")),
    ],
    [
      div(class="form-group", [
        label(for_="name", [text("Name:")]),
        input(
          type_="text",
          id="name",
          placeholder="Enter your name",
          value=props.initial_name,
          on=events().input(on_name_input),
        ),
      ]),
      div(class="form-group", [
        label(for_="email", [text("Email:")]),
        input(
          type_="email",
          id="email",
          placeholder="Enter your email",
          value=props.initial_email,
          on=events().input(on_email_input),
        ),
      ]),
      div(class="form-preview", [
        span([text("Preview: ")]),
        span(class="preview-name", [text_of(name)]),
        span([text(" <")]),
        span(class="preview-email", [text_of(email)]),
        span([text(">")]),
      ]),
      div(class="form-actions", [
        button(
          class="submit-btn",
          attrs=[("type", @element.AttrString("submit"))],
          [text("Submit")],
        ),
      ]),
      div(class="form-result", [text_of(result_msg)]),
    ],
  )
}
