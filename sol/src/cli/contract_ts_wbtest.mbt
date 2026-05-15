///| Whitebox tests for TypeScript props interface contract generation.

///|
fn sample_ts_props_source() -> String {
  (
    #|export interface CounterProps {
    #|  initial: int;
    #|  label: string;
    #|  enabled: boolean;
    #|  tags: string[];
    #|  note?: string;
    #|}
  )
}

///|
test "contract_manifest_from_ts_source: converts TS props interface into Sol manifest" {
  let result = contract_manifest_from_ts_source(sample_ts_props_source(), [
    {
      props_interface: "CounterProps",
      package_path: "app/client",
      import_alias: Some("client"),
      client_url: Some("/assets/counter.js"),
    },
  ])
  guard result is Ok(manifest) else { panic() }
  assert_eq(manifest.routes.length(), 0)
  assert_eq(manifest.actions.length(), 0)
  assert_eq(manifest.client_assets.length(), 1)
  assert_eq(manifest.client_assets[0].component, "counter")
  assert_eq(manifest.client_assets[0].url, "/assets/counter.js")
  assert_eq(manifest.components.length(), 1)
  assert_eq(manifest.components[0].name, "counter")
  assert_eq(manifest.components[0].package_path, "app/client")
  assert_eq(manifest.components[0].import_alias, "client")
  assert_eq(manifest.components[0].props.name, "CounterProps")
  assert_eq(manifest.components[0].props.fields.length(), 5)
  assert_eq(manifest.components[0].props.fields[0].name, "initial")
  assert_eq(manifest.components[0].props.fields[0].type_name, "Int")
  assert_eq(manifest.components[0].props.fields[1].type_name, "String")
  assert_eq(manifest.components[0].props.fields[2].type_name, "Bool")
  assert_eq(manifest.components[0].props.fields[3].type_name, "Array[String]")
  assert_eq(manifest.components[0].props.fields[4].type_name, "String?")
}

///|
test "load_contract_ts_manifest_with_fs: reads configured TS sources" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let mem = fs.memfs()
  mem.mkdirSync("/project/app/client", recursive=true)
  mem.writeFileSync("/project/app/client/props.ts", sample_ts_props_source())
  let result = load_contract_ts_manifest_with_fs(fs, "/project", [
    {
      input: "app/client/props.ts",
      props_interface: "CounterProps",
      package_path: "app/client",
      import_alias: Some("client"),
      client_url: Some("/assets/counter.js"),
    },
  ])
  guard result is Ok(manifest) else { panic() }
  assert_eq(manifest.client_assets.length(), 1)
  assert_eq(manifest.client_assets[0].component, "counter")
  assert_eq(manifest.components.length(), 1)
  assert_eq(manifest.components[0].props.name, "CounterProps")
}

///|
test "contract_manifest_json_from_ts_source: emits parseable Sol contract manifest JSON" {
  let result = contract_manifest_json_from_ts_source(sample_ts_props_source(), [
    {
      props_interface: "CounterProps",
      package_path: "app/client",
      import_alias: None,
      client_url: None,
    },
  ])
  guard result is Ok(json_source) else { panic() }
  assert_true(parse_contract_manifest_json(json_source).is_some())
  let json : Json = @json.parse(json_source) catch { _ => panic() }
  guard json is Object(obj) else { panic() }
  guard obj.get("components") is Some(Array(components)) else { panic() }
  guard components[0] is Object(component) else { panic() }
  assert_true(component.get("name") == Some("counter".to_json()))
  assert_true(component.get("package") == Some("app/client".to_json()))
  assert_true(component.get("importAlias") == Some("client".to_json()))
}

///|
test "contract_manifest_from_ts_source: rejects any fields" {
  let result = contract_manifest_from_ts_source(
    (
      #|export interface CounterProps {
      #|  payload: any;
      #|}
    ),
    [
      {
        props_interface: "CounterProps",
        package_path: "app/client",
        import_alias: None,
        client_url: None,
      },
    ],
  )
  guard result is Err(error) else { panic() }
  guard error is UnsupportedFieldType("CounterProps", "payload", "Any") else {
    panic()
  }
}

///|
test "contract_manifest_from_ts_source: rejects function fields" {
  let result = contract_manifest_from_ts_source(
    (
      #|export interface CounterProps {
      #|  onClick: () => void;
      #|}
    ),
    [
      {
        props_interface: "CounterProps",
        package_path: "app/client",
        import_alias: None,
        client_url: None,
      },
    ],
  )
  guard result is Err(error) else { panic() }
  guard error
    is UnsupportedFieldType("CounterProps", "onClick", "Func([], Void)") else {
    panic()
  }
}

///|
test "contract_manifest_from_ts_source: rejects missing interfaces" {
  let result = contract_manifest_from_ts_source(sample_ts_props_source(), [
    {
      props_interface: "MissingProps",
      package_path: "app/client",
      import_alias: None,
      client_url: None,
    },
  ])
  guard result is Err(error) else { panic() }
  guard error is InterfaceNotFound("MissingProps") else { panic() }
}
