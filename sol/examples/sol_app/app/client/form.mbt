// Contact Form Client Component
// Demonstrates data binding and form submission using Server Actions

///|
/// Props passed from server
pub(all) struct ContactFormProps {
  initial_name : String
  initial_email : String
} derive(ToJson, FromJson)

///|
priv struct ContactSubmitRequest {
  name : String
  email : String
} derive(ToJson)

///|
priv struct ContactSubmitResponse {
  success : Bool
  message : String
} derive(FromJson)

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
    let handle_response : (
      @action.TypedActionResponse[ContactSubmitResponse]
    ) -> Unit = fn(response) {
      match response {
        @action.TypedActionResponse::Success(data) => {
          is_submitting.set(false)
          is_error.set(!data.success)
          result_msg.set(data.message)
        }
        @action.TypedActionResponse::Error(_, error_msg) => {
          is_submitting.set(false)
          is_error.set(true)
          result_msg.set(error_msg)
        }
        @action.TypedActionResponse::NetworkError(error_msg) => {
          is_submitting.set(false)
          is_error.set(true)
          result_msg.set("Network error: " + error_msg)
        }
        @action.TypedActionResponse::Redirect(url) => {
          is_submitting.set(false)
          result_msg.set("Redirecting to: " + url)
          redirect_to(url)
        }
        @action.TypedActionResponse::DecodeError(error_msg) => {
          is_submitting.set(false)
          is_error.set(true)
          result_msg.set(error_msg)
        }
      }
    }

    // Call Server Action with callback
    let key : @action.TypedActionKey[ContactSubmitRequest, ContactSubmitResponse] = @action.TypedActionKey::from_key(
      @types.action_submit_contact(),
    )
    let payload = ContactSubmitRequest::{ name: name.get(), email: email.get() }
    @action.invoke_typed_action_key(
      key,
      payload,
      handle_response,
    )
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
      (
        "action",
        @element.AttrString(
          @action.action_url(@types.action_submit_contact()),
        ),
      ),
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
extern "js" fn redirect_to(url : String) -> Unit =
  #| (url) => { window.location.href = url; }
