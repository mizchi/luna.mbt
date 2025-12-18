///| Contact Form Page Server Component
///|
///| Uses island() to embed the contact_form client component.

///| Contact form page - with contact_form island (sync server component)
pub fn form_page(props : @router.PageProps) -> @server_dom.ServerNode {
  // Create props using generated types - auto-serializes to JSON
  let form_props : @types.ContactFormProps = {
    action: "/api/contact",
    initial_name: "",
    initial_email: "",
  }
  let state_json = form_props.to_json().stringify()

  let content = [
    h1(children=[text("Contact Form")]),
    p(children=[text("A demo of data binding and form submission")]),
    @server_dom.island(
      "contact_form",
      "/static/contact_form.js",
      state=state_json,
      trigger=@luna.Load,
      children=[
        // SSR placeholder matching client component structure
        form(
          class="contact-form",
          action=form_props.action,
          http_method="POST",
          children=[
            div(class="form-group", children=[
              label(for_="name", children=[text("Name:")]),
              input(
                type_="text",
                id="name",
                name="name",
                placeholder="Enter your name",
                value=form_props.initial_name,
              ),
            ]),
            div(class="form-group", children=[
              label(for_="email", children=[text("Email:")]),
              input(
                type_="email",
                id="email",
                name="email",
                placeholder="Enter your email",
                value=form_props.initial_email,
              ),
            ]),
            div(class="form-preview", children=[
              span(children=[text("Preview: ")]),
              span(class="preview-name", children=[text(form_props.initial_name)]),
              span(children=[text(" <")]),
              span(class="preview-email", children=[text(form_props.initial_email)]),
              span(children=[text(">")]),
            ]),
            div(class="form-actions", children=[
              button(
                attrs=[("type", @luna.attr_static("submit"))],
                children=[text("Submit")],
              ),
            ]),
            div(class="form-result", children=[text("")]),
          ],
        ),
      ],
    ),
  ]

  // Fragment request: return content only (no layout)
  // Full page request: wrap with layout
  let node = if props.params.is_fragment {
    @luna.fragment(content)
  } else {
    layout(content)
  }
  @server_dom.ServerNode::sync(node)
}
