///| Contact Form Page Server Component
///|
///| Uses client() to embed the contact_form client component.

///| Contact form page - with contact_form client component (sync server component)
pub fn form_page(props : @router.PageProps) -> @server_dom.ServerNode {
  // Create props using generated types
  let form_props : @types.ContactFormProps = {
    action: "/api/contact",
    initial_name: "",
    initial_email: "",
  }

  let content = [
    h1([text("Contact Form")]),
    p([text("A demo of data binding and form submission")]),
    @server_dom.client(
      @types.contact_form(form_props),
      [
        // SSR placeholder matching client component structure
        form(
          class="contact-form",
          action=form_props.action,
          http_method="POST",
          [
            div(class="form-group", [
              label(for_="name", [text("Name:")]),
              input(
                type_="text",
                id="name",
                name="name",
                placeholder="Enter your name",
                value=form_props.initial_name,
              ),
            ]),
            div(class="form-group", [
              label(for_="email", [text("Email:")]),
              input(
                type_="email",
                id="email",
                name="email",
                placeholder="Enter your email",
                value=form_props.initial_email,
              ),
            ]),
            div(class="form-preview", [
              span([text("Preview: ")]),
              span(class="preview-name", [text(form_props.initial_name)]),
              span([text(" <")]),
              span(class="preview-email", [text(form_props.initial_email)]),
              span([text(">")]),
            ]),
            div(class="form-actions", [
              button(
                attrs=[("type", @luna.attr_static("submit"))],
                [text("Submit")],
              ),
            ]),
            div(class="form-result", [text("")]),
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
