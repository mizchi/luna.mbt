// User Scenario Tests for Resumable State
//
// These tests demonstrate real-world usage patterns from a user's perspective.

// =============================================================================
// Scenario 1: Simple Counter App
// =============================================================================

///|
/// A counter app that preserves count across page refresh
test "scenario: counter app state preservation" {
  // === SSR (Server) Phase ===
  // User visits the counter page
  // Server renders initial HTML with count = 5
  let server_state = ResumableState::new()
  let (count, count_id) = create_resumable_signal(server_state, 5)

  // Simulate: user clicks "+1" button during SSR (e.g., server component action)
  count.set(count.get() + 1) // count is now 6

  // Re-register to capture the updated value for serialization
  let final_state = ResumableState::new()
  let _ = register_signal(final_state, count)

  // Server embeds state in HTML
  let html = render_counter_html(count.get()) + state_to_script_tag(final_state)

  // === Client Phase ===
  // Browser receives HTML with embedded state
  // JavaScript (qwik-loader equivalent) extracts and resumes state
  match parse_state_from_html(html) {
    Some(client_state) => {
      // Client creates signal from server state - NO re-execution of server code!
      let client_count : @signal.Signal[Int] = resume_signal(
        client_state, count_id, 0,
      )

      // The count is already 6, not the initial value
      assert_eq(client_count.get(), 6)

      // Client can continue to update the signal
      client_count.set(client_count.get() + 1)
      assert_eq(client_count.get(), 7)
    }
    None => assert_true(false)
  }
}

///|
fn render_counter_html(count : Int) -> String {
  "<div class=\"counter\"><span>" +
  count.to_string() +
  "</span><button>+1</button></div>"
}

// =============================================================================
// Scenario 2: User Profile Form with Multiple Fields
// =============================================================================

///|
/// A user profile form that preserves form state
test "scenario: form state preservation with multiple fields" {
  // === SSR Phase ===
  // Server renders a profile form with pre-filled data from database
  let server_state = ResumableState::new()

  // Create signals for form fields (simulating data from database)
  let (username, _) = create_resumable_signal(server_state, "alice")
  let (email, _) = create_resumable_signal(server_state, "alice@example.com")
  let (age, _) = create_resumable_signal(server_state, 25)
  let (newsletter, _) = create_resumable_signal(server_state, true)

  // User edits the form during SSR phase (edge case: server action)
  username.set("alice_updated")
  age.set(26)

  // Capture final state
  let final_state = ResumableState::new()
  let username_id = register_signal(final_state, username)
  let email_id = register_signal(final_state, email)
  let age_id = register_signal(final_state, age)
  let newsletter_id = register_signal(final_state, newsletter)
  let html = "<form>...</form>" + state_to_script_tag(final_state)

  // === Client Phase ===
  match parse_state_from_html(html) {
    Some(client_state) => {
      // All form fields are restored with their current values
      let c_username : @signal.Signal[String] = resume_signal(
        client_state, username_id, "",
      )
      let c_email : @signal.Signal[String] = resume_signal(
        client_state, email_id, "",
      )
      let c_age : @signal.Signal[Int] = resume_signal(client_state, age_id, 0)
      let c_newsletter : @signal.Signal[Bool] = resume_signal(
        client_state, newsletter_id, false,
      )
      assert_eq(c_username.get(), "alice_updated")
      assert_eq(c_email.get(), "alice@example.com")
      assert_eq(c_age.get(), 26)
      assert_eq(c_newsletter.get(), true)
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Scenario 3: Shopping Cart
// =============================================================================

///|
/// Shopping cart that preserves items and total across hydration
test "scenario: shopping cart state" {
  // === SSR Phase ===
  let server_state = ResumableState::new()

  // Cart state
  let (item_count, _) = create_resumable_signal(server_state, 3)
  let (total_price, _) = create_resumable_signal(server_state, 99.99)
  let (coupon_code, _) = create_resumable_signal(server_state, "SAVE10")
  let (is_checkout_enabled, _) = create_resumable_signal(server_state, true)

  // Capture state for HTML embedding
  let final_state = ResumableState::new()
  let item_count_id = register_signal(final_state, item_count)
  let total_id = register_signal(final_state, total_price)
  let coupon_id = register_signal(final_state, coupon_code)
  let checkout_id = register_signal(final_state, is_checkout_enabled)
  let html = "<div class=\"cart\">...</div>" + state_to_script_tag(final_state)

  // === Client Phase ===
  match parse_state_from_html(html) {
    Some(client_state) => {
      let c_items : @signal.Signal[Int] = resume_signal(
        client_state, item_count_id, 0,
      )
      let c_total : @signal.Signal[Double] = resume_signal(
        client_state, total_id, 0.0,
      )
      let c_coupon : @signal.Signal[String] = resume_signal(
        client_state, coupon_id, "",
      )
      let c_checkout : @signal.Signal[Bool] = resume_signal(
        client_state, checkout_id, false,
      )
      assert_eq(c_items.get(), 3)
      // Float comparison with tolerance
      assert_true(c_total.get() > 99.0 && c_total.get() < 100.0)
      assert_eq(c_coupon.get(), "SAVE10")
      assert_eq(c_checkout.get(), true)

      // User can interact with cart immediately
      c_items.set(c_items.get() + 1) // Add item
      assert_eq(c_items.get(), 4)
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Scenario 4: Tab Component with Active State
// =============================================================================

///|
/// Tab component that remembers which tab was active
test "scenario: tab component active state" {
  // === SSR Phase ===
  // User was viewing the "Settings" tab (index 2)
  let server_state = ResumableState::new()
  let (active_tab, _) = create_resumable_signal(server_state, 2)
  let (tab_names, _) = create_resumable_signal(
    server_state, "Home,Profile,Settings",
  )
  let final_state = ResumableState::new()
  let tab_id = register_signal(final_state, active_tab)
  let names_id = register_signal(final_state, tab_names)
  let html = "<div class=\"tabs\">...</div>" + state_to_script_tag(final_state)

  // === Client Phase ===
  match parse_state_from_html(html) {
    Some(client_state) => {
      let c_tab : @signal.Signal[Int] = resume_signal(client_state, tab_id, 0)
      let c_names : @signal.Signal[String] = resume_signal(
        client_state, names_id, "",
      )

      // User sees "Settings" tab still selected
      assert_eq(c_tab.get(), 2)
      assert_eq(c_names.get(), "Home,Profile,Settings")

      // User clicks on "Profile" tab
      c_tab.set(1)
      assert_eq(c_tab.get(), 1)
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Scenario 5: No Server State (Fresh Client Render)
// =============================================================================

///|
/// When there's no server state, client uses default values
test "scenario: fresh client without server state" {
  // HTML without any embedded state (e.g., client-only app)
  let html = "<div id=\"app\"></div>"
  match parse_state_from_html(html) {
    Some(_) => assert_true(false) // Should not find state
    None => {
      // Client creates signals with default values
      let count = @signal.signal(0)
      let name = @signal.signal("Guest")
      assert_eq(count.get(), 0)
      assert_eq(name.get(), "Guest")
    }
  }
}

// =============================================================================
// Scenario 6: Partial State Recovery
// =============================================================================

///|
/// When some state IDs don't exist, fallback to defaults
test "scenario: partial state recovery with missing values" {
  // Server only saved count, but client expects both count and name
  let server_state = ResumableState::new()
  let _ = server_state.register_int(42)
  let html = "<div>...</div>" + state_to_script_tag(server_state)
  match parse_state_from_html(html) {
    Some(client_state) => {
      // ID 0 exists - restored
      let count : @signal.Signal[Int] = resume_signal(client_state, 0, 0)
      assert_eq(count.get(), 42)

      // ID 1 doesn't exist - uses default
      let name : @signal.Signal[String] = resume_signal(
        client_state, 1, "default",
      )
      assert_eq(name.get(), "default")

      // ID 99 doesn't exist - uses default
      let flag : @signal.Signal[Bool] = resume_signal(client_state, 99, false)
      assert_eq(flag.get(), false)
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Scenario 7: Modal Dialog State
// =============================================================================

///|
/// Modal dialog that preserves open/closed state and content
test "scenario: modal dialog state preservation" {
  // === SSR Phase ===
  // User opened a confirmation modal
  let server_state = ResumableState::new()
  let (is_open, _) = create_resumable_signal(server_state, true)
  let (modal_title, _) = create_resumable_signal(server_state, "Confirm Delete")
  let (modal_message, _) = create_resumable_signal(
    server_state, "Are you sure you want to delete this item?",
  )
  let final_state = ResumableState::new()
  let open_id = register_signal(final_state, is_open)
  let title_id = register_signal(final_state, modal_title)
  let msg_id = register_signal(final_state, modal_message)
  let html = "<div class=\"modal\">...</div>" + state_to_script_tag(final_state)

  // === Client Phase ===
  match parse_state_from_html(html) {
    Some(client_state) => {
      let c_open : @signal.Signal[Bool] = resume_signal(
        client_state, open_id, false,
      )
      let c_title : @signal.Signal[String] = resume_signal(
        client_state, title_id, "",
      )
      let c_msg : @signal.Signal[String] = resume_signal(
        client_state, msg_id, "",
      )

      // Modal is still open with same content
      assert_eq(c_open.get(), true)
      assert_eq(c_title.get(), "Confirm Delete")
      assert_true(c_msg.get().contains("delete"))

      // User closes modal
      c_open.set(false)
      assert_eq(c_open.get(), false)
    }
    None => assert_true(false)
  }
}

// =============================================================================
// Scenario 8: Theme Preference
// =============================================================================

///|
/// Dark/Light theme preference that persists
test "scenario: theme preference persistence" {
  // === SSR Phase ===
  // Server detected user prefers dark mode
  let server_state = ResumableState::new()
  let (is_dark_mode, _) = create_resumable_signal(server_state, true)
  let (font_size, _) = create_resumable_signal(server_state, 16)
  let final_state = ResumableState::new()
  let theme_id = register_signal(final_state, is_dark_mode)
  let font_id = register_signal(final_state, font_size)
  let html = "<body class=\"dark\">...</body>" +
    state_to_script_tag(final_state)

  // === Client Phase ===
  match parse_state_from_html(html) {
    Some(client_state) => {
      let c_dark : @signal.Signal[Bool] = resume_signal(
        client_state, theme_id, false,
      )
      let c_font : @signal.Signal[Int] = resume_signal(
        client_state, font_id, 14,
      )

      // Theme is preserved
      assert_eq(c_dark.get(), true)
      assert_eq(c_font.get(), 16)

      // User toggles theme
      c_dark.set(not(c_dark.get()))
      assert_eq(c_dark.get(), false) // Now light mode
    }
    None => assert_true(false)
  }
}
