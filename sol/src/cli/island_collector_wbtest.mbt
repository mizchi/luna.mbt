// Whitebox tests for island_collector.mbt pure functions

// =============================================================================
// extract_island_name
// =============================================================================

///|
test "extract_island_name - removes island_client_ prefix" {
  assert_eq(extract_island_name("island_client_counter"), "counter")
}

///|
test "extract_island_name - removes island_ prefix" {
  assert_eq(extract_island_name("island_counter"), "counter")
}

///|
test "extract_island_name - prefers island_client_ over island_ prefix" {
  // island_client_ prefix is checked first
  assert_eq(extract_island_name("island_client_my_widget"), "my_widget")
}

///|
test "extract_island_name - no prefix returns name unchanged" {
  assert_eq(extract_island_name("counter"), "counter")
}

///|
test "extract_island_name - empty string returns empty" {
  assert_eq(extract_island_name(""), "")
}

///|
test "extract_island_name - island_ prefix only extracts suffix" {
  assert_eq(extract_island_name("island_contact_form"), "contact_form")
}

// =============================================================================
// generate_import_alias
// =============================================================================

///|
test "generate_import_alias - island category prefixes with island_" {
  let import_alias = generate_import_alias(
    "myproject/islands/counter", "island",
  )
  assert_eq(import_alias, "island_counter")
}

///|
test "generate_import_alias - page category prefixes with page_" {
  let import_alias = generate_import_alias("myproject/pages/home", "page")
  assert_eq(import_alias, "page_home")
}

///|
test "generate_import_alias - unknown category uses last segment" {
  let import_alias = generate_import_alias("myproject/components", "other")
  assert_eq(import_alias, "components")
}

///|
test "generate_import_alias - single segment path" {
  let import_alias = generate_import_alias("counter", "island")
  assert_eq(import_alias, "island_counter")
}

// =============================================================================
// generate_export_name
// =============================================================================

///|
test "generate_export_name - island category, hydrate fn returns import_alias" {
  let name = generate_export_name("hydrate", "island_counter", "island")
  assert_eq(name, "island_counter")
}

///|
test "generate_export_name - island category, other fn appended" {
  let name = generate_export_name("init", "island_counter", "island")
  assert_eq(name, "island_counter_init")
}

///|
test "generate_export_name - page category, page fn returns import_alias" {
  let name = generate_export_name("page", "page_home", "page")
  assert_eq(name, "page_home")
}

///|
test "generate_export_name - page category, other fn appended" {
  let name = generate_export_name("layout", "page_home", "page")
  assert_eq(name, "page_home_layout")
}

///|
test "generate_export_name - unknown category returns fn_name unchanged" {
  let name = generate_export_name("my_fn", "some_alias", "other")
  assert_eq(name, "my_fn")
}

// =============================================================================
// extract_component_name_from_props
// =============================================================================

///|
test "extract_component_name_from_props - removes Props suffix and snake_cases" {
  assert_eq(extract_component_name_from_props("CounterProps"), "counter")
}

///|
test "extract_component_name_from_props - multi-word PascalCase" {
  assert_eq(extract_component_name_from_props("MyWidgetProps"), "my_widget")
}

///|
test "extract_component_name_from_props - no Props suffix unchanged but snake_cased" {
  assert_eq(extract_component_name_from_props("Counter"), "counter")
}

///|
test "extract_component_name_from_props - three-word component name" {
  assert_eq(
    extract_component_name_from_props("ContactFormProps"),
    "contact_form",
  )
}

///|
test "extract_component_name_from_props - WebComponent prefix" {
  assert_eq(extract_component_name_from_props("WcButtonProps"), "wc_button")
}

///|
test "extract_component_name_from_props - single uppercase letter" {
  assert_eq(extract_component_name_from_props("AProps"), "a")
}

// =============================================================================
// is_web_component
// =============================================================================

///|
test "is_web_component - true for wc_ prefix" {
  assert_true(is_web_component("wc_button"))
}

///|
test "is_web_component - false without wc_ prefix" {
  assert_false(is_web_component("counter"))
}

///|
test "is_web_component - false for partial match" {
  assert_false(is_web_component("my_wc_button"))
}

///|
test "is_web_component - false for empty string" {
  assert_false(is_web_component(""))
}

// =============================================================================
// func_export_from_name
// =============================================================================

///|
test "func_export_from_name - generates Props type from snake_case name" {
  let fe = func_export_from_name("counter", "app/client")
  assert_eq(fe.contract.props_type, Some("CounterProps"))
}

///|
test "func_export_from_name - multi-word snake_case to PascalCase Props" {
  let fe = func_export_from_name("contact_form", "app/client")
  assert_eq(fe.contract.props_type, Some("ContactFormProps"))
}

///|
test "func_export_from_name - sets name from argument" {
  let fe = func_export_from_name("counter", "app/client")
  assert_eq(fe.name, "counter")
}

///|
test "func_export_from_name - source_pattern matches argument" {
  let fe = func_export_from_name("counter", "app/islands")
  assert_eq(fe.source_pattern, "app/islands")
  assert_eq(fe.package_path, "app/islands")
}

///|
test "func_export_from_name - import_alias is last path segment" {
  let fe = func_export_from_name("counter", "app/client")
  assert_eq(fe.import_alias, "client")
}

///|
test "func_export_from_name - contract has DomNode return type" {
  let fe = func_export_from_name("counter", "app/client")
  assert_eq(fe.contract.return_kind, ClientReturnDomNode)
}

// =============================================================================
// ClientComponentContract
// =============================================================================

///|
test "client_component_contract_from_signature - accepts Props to DomNode" {
  let contract = client_component_contract_from_signature(
    "(CounterProps) -> DomNode",
  )
  assert_eq(contract.props_type, Some("CounterProps"))
  assert_eq(contract.return_kind, ClientReturnDomNode)
  assert_true(contract.can_hydrate())
}

///|
test "client_component_contract_from_signature - accepts Props to Luna node" {
  let contract = client_component_contract_from_signature(
    "(CounterProps) -> @luna.Node[Unit, String]",
  )
  assert_eq(contract.props_type, Some("CounterProps"))
  assert_eq(contract.return_kind, ClientReturnVNode)
  assert_true(contract.can_hydrate())
}

///|
test "client_component_contract_from_signature - rejects non Props parameter" {
  let contract = client_component_contract_from_signature(
    "(CounterState) -> DomNode",
  )
  assert_eq(contract.props_type, None)
  assert_eq(contract.return_kind, ClientReturnDomNode)
  assert_false(contract.can_hydrate())
}

///|
test "client_component_contract_from_signature - rejects names that only contain Props" {
  let contract = client_component_contract_from_signature(
    "(CounterPropsFactory) -> DomNode",
  )
  assert_eq(contract.props_type, None)
  assert_false(contract.can_hydrate())
}
