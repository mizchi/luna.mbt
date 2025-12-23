// Contact Form Client Component
// Demonstrates data binding and form submission using Server Actions

///|
/// Props passed from server
pub(all) struct ContactFormProps {
  action : String
  initial_name : String
  initial_email : String
} derive(ToJson, FromJson)

///|
/// Contact form component with two-way data binding and Server Action submission
pub fn contact_form(props : ContactFormProps) -> DomNode {
  // Signals for form state
  let name = @signal.signal(props.initial_name)
  let email = @signal.signal(props.initial_email)
  let is_submitting = @signal.signal(false)
  let result_msg = @signal.signal("")
  let is_error = @signal.signal(false)

  // Form submit handler using Server Action
  let handle_submit : @element.FormHandler = fn(e) {
    e.preventDefault()
    is_submitting.set(true)
    is_error.set(false)
    result_msg.set("Submitting...")

    // Create response handler callback
    let handle_response : (@action.ActionResponse) -> Unit = fn(response) {
      match response {
        @action.ActionResponse::Success(data) => {
          is_submitting.set(false)
          let msg = get_message(data)
          result_msg.set(msg)
        }
        @action.ActionResponse::Error(_, error_msg) => {
          is_submitting.set(false)
          is_error.set(true)
          result_msg.set(error_msg)
        }
        @action.ActionResponse::NetworkError(error_msg) => {
          is_submitting.set(false)
          is_error.set(true)
          result_msg.set("Network error: " + error_msg)
        }
        @action.ActionResponse::Redirect(url) => {
          is_submitting.set(false)
          result_msg.set("Redirecting to: " + url)
          redirect_to(url)
        }
      }
    }

    // Call Server Action with callback
    let payload = create_form_payload(name.get(), email.get())
    @action.invoke_action(props.action, payload, handle_response)
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
          name="name",
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
          name="email",
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
      div(
        class="form-result",
        attrs=[("data-testid", @element.AttrString("form-result"))],
        [text_of(result_msg)],
      ),
    ],
  )
}

///|
extern "js" fn get_message(data : @js.Any) -> String =
  #| (data) => data.message || JSON.stringify(data)

///|
extern "js" fn create_form_payload(name : String, email : String) -> @js.Any =
  #| (name, email) => ({ name, email })

///|
extern "js" fn redirect_to(url : String) -> Unit =
  #| (url) => { window.location.href = url; }
