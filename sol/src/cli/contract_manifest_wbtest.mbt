///| Whitebox tests for explicit Sol contract manifests

///|
fn sample_contract_manifest_json() -> String {
  (
    #|{
    #|  "routes": [
    #|    {
    #|      "path": "/api/items/:id",
    #|      "query": [
    #|        { "name": "include", "optional": true }
    #|      ]
    #|    },
    #|    "/about"
    #|  ],
    #|  "actions": [
    #|    {
    #|      "id": "submit-contact",
    #|      "request": {
    #|        "name": "SubmitContactRequest",
    #|        "fields": [{ "name": "email", "type": "String" }]
    #|      },
    #|      "response": {
    #|        "name": "SubmitContactResponse",
    #|        "fields": [{ "name": "ok", "type": "Bool" }]
    #|      }
    #|    },
    #|    "delete-todo"
    #|  ],
    #|  "apis": [
    #|    {
    #|      "method": "POST",
    #|      "path": "/api/items/:id",
    #|      "request": {
    #|        "name": "CreateItemRequest",
    #|        "fields": [{ "name": "title", "type": "String" }]
    #|      },
    #|      "response": {
    #|        "name": "ItemResponse",
    #|        "fields": [{ "name": "id", "type": "String" }]
    #|      }
    #|    }
    #|  ],
    #|  "clientAssets": [
    #|    { "component": "counter", "url": "/assets/counter.abc123.js" }
    #|  ],
    #|  "components": [
    #|    {
    #|      "name": "counter",
    #|      "package": "app/client",
    #|      "importAlias": "client",
    #|      "props": {
    #|        "name": "CounterProps",
    #|        "fields": [
    #|          { "name": "initial", "type": "Int" },
    #|          { "name": "label", "type": "String" }
    #|        ]
    #|      }
    #|    }
    #|  ]
    #|}
  )
}

///|
test "parse_contract_manifest_json: routes actions and client assets" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json())
  assert_true(manifest.is_some())
  let m = manifest.unwrap()
  assert_eq(m.routes.length(), 2)
  assert_eq(m.routes[0].path, "/api/items/:id")
  assert_eq(m.routes[0].query.length(), 1)
  assert_eq(m.routes[0].query[0].name, "include")
  assert_true(m.routes[0].query[0].optional)
  assert_eq(m.routes[1].path, "/about")
  assert_eq(m.actions.length(), 2)
  assert_eq(m.actions[0].id, "submit-contact")
  assert_eq(m.actions[0].request_type, Some("SubmitContactRequest"))
  assert_eq(m.actions[0].response_type, Some("SubmitContactResponse"))
  assert_eq(m.actions[1].id, "delete-todo")
  assert_eq(m.apis.length(), 1)
  assert_eq(m.apis[0].method_name, "POST")
  assert_eq(m.apis[0].path, "/api/items/:id")
  assert_eq(m.apis[0].request_type, Some("CreateItemRequest"))
  assert_eq(m.apis[0].response_type, Some("ItemResponse"))
  assert_eq(m.contract_shapes.length(), 4)
  assert_eq(m.client_assets.length(), 1)
  assert_eq(m.client_assets[0].component, "counter")
  assert_eq(m.client_assets[0].url, "/assets/counter.abc123.js")
  assert_eq(m.components.length(), 1)
  assert_eq(m.components[0].name, "counter")
  assert_eq(m.components[0].props.name, "CounterProps")
  assert_eq(m.components[0].props.fields.length(), 2)
  assert_eq(m.components[0].props.fields[0].name, "initial")
  assert_eq(m.components[0].props.fields[0].type_name, "Int")
}

///|
test "ContractManifest::to_route_info: feeds type generator without route source scanning" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json()).unwrap()
  let info = manifest.to_route_info()
  assert_eq(info.route_paths.length(), 2)
  assert_eq(info.route_paths[0], "/api/items/:id")
  assert_eq(info.route_queries.length(), 1)
  assert_eq(info.route_queries[0].path, "/api/items/:id")
  assert_eq(info.action_ids.length(), 2)
  assert_eq(info.action_ids[0], "submit-contact")
  assert_eq(info.action_ids[1], "delete-todo")
  assert_eq(info.action_contracts.length(), 2)
  assert_eq(info.api_contracts.length(), 1)
  assert_eq(info.contract_shapes.length(), 4)
}

///|
test "ContractManifest::client_asset_url: resolves component url" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json()).unwrap()
  assert_eq(
    manifest.client_asset_url("counter"),
    Some("/assets/counter.abc123.js"),
  )
  assert_eq(manifest.client_asset_url("missing"), None)
}

///|
test "ContractManifest::to_struct_exports: feeds type generator without Props source scanning" {
  let manifest = parse_contract_manifest_json(sample_contract_manifest_json()).unwrap()
  let structs = manifest.to_struct_exports()
  assert_eq(structs.length(), 1)
  assert_eq(structs[0].name, "CounterProps")
  assert_eq(structs[0].package_path, "app/client")
  assert_eq(structs[0].import_alias, "client")
  assert_true(
    structs[0].raw_definition.contains("pub(all) struct CounterProps"),
  )
  assert_true(structs[0].raw_definition.contains("initial : Int"))
  assert_true(structs[0].raw_definition.contains("label : String"))
}

///|
test "parse_contract_manifest_json: rejects invalid MoonBit props field identifier" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "components": [
      #|    {
      #|      "name": "counter",
      #|      "package": "app/client",
      #|      "props": {
      #|        "name": "CounterProps",
      #|        "fields": [
      #|          { "name": "bad-name", "type": "Int" }
      #|        ]
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects invalid MoonBit props field type" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "components": [
      #|    {
      #|      "name": "counter",
      #|      "package": "app/client",
      #|      "props": {
      #|        "name": "CounterProps",
      #|        "fields": [
      #|          { "name": "initial", "type": "Int }\n pub fn injected() -> Int { 1" }
      #|        ]
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects component name not matching props name" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "clientAssets": [
      #|    { "component": "todo_list", "url": "/assets/todo.js" }
      #|  ],
      #|  "components": [
      #|    {
      #|      "name": "todo_list",
      #|      "package": "app/client",
      #|      "props": {
      #|        "name": "CounterProps",
      #|        "fields": [
      #|          { "name": "initial", "type": "Int" }
      #|        ]
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects duplicate props names" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "components": [
      #|    {
      #|      "name": "counter",
      #|      "package": "app/client",
      #|      "props": { "name": "CounterProps", "fields": [] }
      #|    },
      #|    {
      #|      "name": "counter",
      #|      "package": "app/other",
      #|      "props": { "name": "CounterProps", "fields": [] }
      #|    }
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects route string literal injection" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "routes": [
      #|    "/ok",
      #|    "/bad\""
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects action IDs that cannot generate identifiers" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "actions": [
      #|    "submit contact"
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects malformed action contract shape" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "actions": [
      #|    {
      #|      "id": "submit-contact",
      #|      "request": {
      #|        "fields": [
      #|          { "name": "email", "type": "String" }
      #|        ]
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}

///|
test "parse_contract_manifest_json: rejects conflicting contract shape definitions" {
  let manifest = parse_contract_manifest_json(
    (
      #|{
      #|  "actions": [
      #|    {
      #|      "id": "submit-contact",
      #|      "request": {
      #|        "name": "SharedRequest",
      #|        "fields": [{ "name": "email", "type": "String" }]
      #|      }
      #|    }
      #|  ],
      #|  "apis": [
      #|    {
      #|      "method": "POST",
      #|      "path": "/api/contact",
      #|      "request": {
      #|        "name": "SharedRequest",
      #|        "fields": [{ "name": "id", "type": "String" }]
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  assert_true(manifest.is_none())
}
