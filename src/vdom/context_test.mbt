///| Context API tests

///|
test "create context with default value" {
  let theme_context : Context[String] = create_context("light")
  inspect(theme_context.id, content="0")
  inspect(theme_context.default_value, content="light")
}

///|
test "get context returns default value initially" {
  let theme_context = create_context("light")
  let theme = get_context(theme_context)
  inspect(theme, content="light")
}

///|
test "set and get context value" {
  let theme_context = create_context("light")
  set_context(theme_context, "dark")
  let theme = get_context(theme_context)
  inspect(theme, content="dark")
}

///|
test "multiple contexts with different types" {
  let theme_context = create_context("light")
  let count_context = create_context(0)
  let user_context = create_context("anonymous")
  set_context(theme_context, "dark")
  set_context(count_context, 42)
  set_context(user_context, "Alice")
  inspect(get_context(theme_context), content="dark")
  inspect(get_context(count_context), content="42")
  inspect(get_context(user_context), content="Alice")
}

///|
test "clear context reverts to default" {
  let theme_context = create_context("light")
  set_context(theme_context, "dark")
  inspect(get_context(theme_context), content="dark")
  clear_context(theme_context)
  inspect(get_context(theme_context), content="light")
}

///|
test "update context value multiple times" {
  let count_context = create_context(0)
  set_context(count_context, 1)
  inspect(get_context(count_context), content="1")
  set_context(count_context, 2)
  inspect(get_context(count_context), content="2")
  set_context(count_context, 3)
  inspect(get_context(count_context), content="3")
}

///|
test "contexts are independent by ID" {
  let ctx1 = create_context("A")
  let ctx2 = create_context("B")
  set_context(ctx1, "X")
  set_context(ctx2, "Y")
  inspect(get_context(ctx1), content="X")
  inspect(get_context(ctx2), content="Y")

  // Verify IDs are different
  assert_eq(ctx1.id != ctx2.id, true)
}

///|
test "context with boolean type" {
  let flag_context = create_context(false)
  inspect(get_context(flag_context), content="false")
  set_context(flag_context, true)
  inspect(get_context(flag_context), content="true")
}

///|
test "context with complex default value" {
  struct User {
    name : String
    age : Int
  }
  let user = { name: "Bob", age: 30 }
  let user_context = create_context(user)
  let default_user = get_context(user_context)
  inspect(default_user.name, content="Bob")
  inspect(default_user.age, content="30")
  let new_user = { name: "Alice", age: 25 }
  set_context(user_context, new_user)
  let updated_user = get_context(user_context)
  inspect(updated_user.name, content="Alice")
  inspect(updated_user.age, content="25")
}
