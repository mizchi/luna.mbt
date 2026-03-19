///| Authentication Pages
///|
///| Login and Profile pages that demonstrate
///| integration with better-auth via dev-auth.ts

///|
/// Login page - shows login/signup forms
/// Uses client-side JavaScript to handle auth API calls
async fn login_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  // Check if already logged in
  let session = get_session()

  let content : Array[@luna.Node[Unit, String]] = match session {
    Some(s) =>
      [
        h1([text("Already Logged In")]),
        p([text("Welcome back, " + s.user_name + "!")]),
        p([a(href="/profile", [text("Go to Profile")])]),
        // Sign out form
        form(
          action="/api/auth/sign-out",
          http_method="POST",
          style="margin-top: 1rem",
          [
            button(attrs=[("type", @luna.attr_static("submit"))], [
              text("Sign Out"),
            ]),
          ],
        ),
      ]
    None =>
      [
        h1([text("Login")]),
        // Login Form
        div(class="auth-form", [
          h2([text("Sign In")]),
          form(id="login-form", [
            div(class="form-group", [
              label(for_="login-email", [text("Email")]),
              input(type_="email", id="login-email", name="email"),
            ]),
            div(class="form-group", [
              label(for_="login-password", [text("Password")]),
              input(type_="password", id="login-password", name="password"),
            ]),
            button(attrs=[("type", @luna.attr_static("submit"))], [
              text("Sign In"),
            ]),
            div(id="login-error", style="color: red; margin-top: 0.5rem", []),
          ]),
        ]),
        // Signup Form
        div(class="auth-form", style="margin-top: 2rem", [
          h2([text("Create Account")]),
          form(id="signup-form", [
            div(class="form-group", [
              label(for_="signup-name", [text("Name")]),
              input(type_="text", id="signup-name", name="name"),
            ]),
            div(class="form-group", [
              label(for_="signup-email", [text("Email")]),
              input(type_="email", id="signup-email", name="email"),
            ]),
            div(class="form-group", [
              label(for_="signup-password", [text("Password")]),
              input(type_="password", id="signup-password", name="password"),
            ]),
            button(attrs=[("type", @luna.attr_static("submit"))], [
              text("Create Account"),
            ]),
            div(id="signup-error", style="color: red; margin-top: 0.5rem", []),
            div(
              id="signup-success",
              style="color: green; margin-top: 0.5rem",
              [],
            ),
          ]),
        ]),
        // Client-side auth script
        @luna.raw_html(auth_script()),
        // Basic styles
        @luna.raw_html(auth_styles()),
      ]
  }
  @sol.nodes(content)
}

///|
/// Profile page - shows user info (requires authentication)
async fn profile_page(_props : @sol.PageProps) -> @server_dom.ServerNode {
  let session = get_session()

  let content : Array[@luna.Node[Unit, String]] = match session {
    Some(s) =>
      [
        h1([text("Profile")]),
        div(class="profile-card", [
          h2([text(s.user_name)]),
          p([text("Email: " + s.user_email)]),
          p(style="color: #666; font-size: 0.9em", [
            text("User ID: " + s.user_id),
          ]),
        ]),
        // Sign out form (POST form for proper sign-out)
        form(
          id="signout-form",
          action="/api/auth/sign-out",
          http_method="POST",
          style="margin-top: 1rem",
          [
            button(attrs=[("type", @luna.attr_static("submit"))], [
              text("Sign Out"),
            ]),
          ],
        ),
        @luna.raw_html(profile_script()),
        @luna.raw_html(profile_styles()),
      ]
    None =>
      [
        h1([text("Not Authenticated")]),
        p([text("Please log in to view your profile.")]),
        p([a(href="/login", [text("Go to Login")])]),
      ]
  }
  @sol.nodes(content)
}

///|
fn auth_script() -> String {
  let js =
    #|document.getElementById('login-form')?.addEventListener('submit', async (e) => {
    #|  e.preventDefault();
    #|  const form = e.target;
    #|  const email = form.email.value;
    #|  const password = form.password.value;
    #|  const errorEl = document.getElementById('login-error');
    #|  try {
    #|    const res = await fetch('/api/auth/sign-in/email', {
    #|      method: 'POST',
    #|      headers: { 'Content-Type': 'application/json' },
    #|      credentials: 'include',
    #|      body: JSON.stringify({ email, password })
    #|    });
    #|    if (res.ok) {
    #|      window.location.href = '/profile';
    #|    } else {
    #|      const data = await res.json();
    #|      errorEl.textContent = data.message || 'Login failed';
    #|    }
    #|  } catch (err) {
    #|    errorEl.textContent = 'Network error';
    #|  }
    #|});
    #|document.getElementById('signup-form')?.addEventListener('submit', async (e) => {
    #|  e.preventDefault();
    #|  const form = e.target;
    #|  const name = form.name.value;
    #|  const email = form.email.value;
    #|  const password = form.password.value;
    #|  const errorEl = document.getElementById('signup-error');
    #|  const successEl = document.getElementById('signup-success');
    #|  try {
    #|    const res = await fetch('/api/auth/sign-up/email', {
    #|      method: 'POST',
    #|      headers: { 'Content-Type': 'application/json' },
    #|      credentials: 'include',
    #|      body: JSON.stringify({ name, email, password })
    #|    });
    #|    if (res.ok) {
    #|      successEl.textContent = 'Account created! Redirecting...';
    #|      errorEl.textContent = '';
    #|      setTimeout(() => window.location.href = '/profile', 1000);
    #|    } else {
    #|      const data = await res.json();
    #|      errorEl.textContent = data.message || 'Signup failed';
    #|      successEl.textContent = '';
    #|    }
    #|  } catch (err) {
    #|    errorEl.textContent = 'Network error';
    #|    successEl.textContent = '';
    #|  }
    #|});
  "<script>\n\{js}\n</script>"
}

///|
fn auth_styles() -> String {
  let css =
    #|.auth-form {
    #|  max-width: 400px;
    #|  padding: 1rem;
    #|  border: 1px solid #ddd;
    #|  border-radius: 8px;
    #|}
    #|.auth-form .form-group {
    #|  margin-bottom: 1rem;
    #|}
    #|.auth-form .form-group label {
    #|  display: block;
    #|  margin-bottom: 0.25rem;
    #|  font-weight: 500;
    #|}
    #|.auth-form .form-group input {
    #|  width: 100%;
    #|  padding: 0.5rem;
    #|  border: 1px solid #ccc;
    #|  border-radius: 4px;
    #|  box-sizing: border-box;
    #|}
    #|.auth-form button[type="submit"] {
    #|  background: #0070f3;
    #|  color: white;
    #|  border: none;
    #|  padding: 0.5rem 1rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|}
    #|.auth-form button[type="submit"]:hover {
    #|  background: #0060df;
    #|}
  "<style>\n\{css}\n</style>"
}

///|
fn profile_script() -> String {
  let js =
    #|document.getElementById('signout-form')?.addEventListener('submit', async (e) => {
    #|  e.preventDefault();
    #|  try {
    #|    const res = await fetch('/api/auth/sign-out', {
    #|      method: 'POST',
    #|      headers: { 'Content-Type': 'application/json' },
    #|      credentials: 'include',
    #|      body: '{}'
    #|    });
    #|    if (res.ok) {
    #|      window.location.href = '/login';
    #|    }
    #|  } catch (err) {
    #|    console.error('Sign out failed', err);
    #|  }
    #|});
  "<script>\n\{js}\n</script>"
}

///|
fn profile_styles() -> String {
  let css =
    #|.profile-card {
    #|  max-width: 400px;
    #|  padding: 1.5rem;
    #|  border: 1px solid #ddd;
    #|  border-radius: 8px;
    #|  background: #f9f9f9;
    #|}
    #|.profile-card h2 {
    #|  margin-top: 0;
    #|}
  "<style>\n\{css}\n</style>"
}
