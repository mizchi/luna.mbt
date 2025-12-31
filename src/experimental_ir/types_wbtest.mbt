/// Tests for IR types and serialization

test "Schema::empty creates empty schema" {
  let schema = Schema::empty()
  assert_eq(schema.version, "1.0")
  assert_eq(schema.definitions.length(), 0)
}

test "StructDef serialization" {
  let def = StructDef::new("UserProps")
  let struct_def : StructDef = {
    ..def,
    doc: Some("User component props"),
    fields: [
      Field::new("name", TypeRef::string()),
      Field::optional("age", TypeRef::int()),
      {
        ..Field::new("active", TypeRef::bool_()),
        default: Some(true.to_json()),
      },
    ],
    derives: ["Serialize", "Eq"],
  }

  let json = struct_def.to_json_obj().to_json()
  let json_str = json.stringify()

  // Verify it contains expected fields
  assert_true(json_str.contains("UserProps"))
  assert_true(json_str.contains("name"))
  assert_true(json_str.contains("age"))
  assert_true(json_str.contains("active"))
}

test "TypeRef primitives" {
  let bool_ref = TypeRef::bool_()
  let int_ref = TypeRef::int()
  let str_ref = TypeRef::string()

  assert_eq(bool_ref.to_json().stringify(), "{\"kind\":\"primitive\",\"type\":\"bool\"}")
  assert_eq(int_ref.to_json().stringify(), "{\"kind\":\"primitive\",\"type\":\"int\"}")
  assert_eq(str_ref.to_json().stringify(), "{\"kind\":\"primitive\",\"type\":\"string\"}")
}

test "TypeRef array" {
  let arr = TypeRef::array(TypeRef::string())
  let json = arr.to_json().stringify()
  assert_true(json.contains("array"))
  assert_true(json.contains("string"))
}

test "TypeRef option" {
  let opt = TypeRef::option(TypeRef::int())
  let json = opt.to_json().stringify()
  assert_true(json.contains("option"))
  assert_true(json.contains("int"))
}

test "TypeRef named" {
  let named = TypeRef::named("SwitchProps")
  let json = named.to_json().stringify()
  assert_true(json.contains("named"))
  assert_true(json.contains("SwitchProps"))
}

test "TypeRef union" {
  let union = TypeRef::union([
    TypeRef::string_lit("open"),
    TypeRef::string_lit("closed"),
  ])
  let json = union.to_json().stringify()
  assert_true(json.contains("union"))
  assert_true(json.contains("open"))
  assert_true(json.contains("closed"))
}

test "Full schema serialization" {
  let switch_props = StructDef::new("SwitchProps")
  let switch_def : StructDef = {
    ..switch_props,
    fields: [
      Field::new("checked", TypeRef::bool_()),
      Field::optional("disabled", TypeRef::bool_()),
      Field::new("label", TypeRef::string()),
    ],
  }

  let defs : Map[String, TypeDef] = {}
  defs["SwitchProps"] = Struct(switch_def)

  let schema : Schema = {
    version: "1.0",
    definitions: defs,
    source: Some({ file: "switch.mbt", lang: MoonBit }),
  }

  let json = schema.to_json().stringify()
  assert_true(json.contains("SwitchProps"))
  assert_true(json.contains("checked"))
  assert_true(json.contains("moonbit"))
}

// =============================================================================
// MoonBit Code Generator Tests
// =============================================================================

test "TypeRef::to_moonbit primitives" {
  assert_eq(TypeRef::bool_().to_moonbit(), "Bool")
  assert_eq(TypeRef::int().to_moonbit(), "Int")
  assert_eq(TypeRef::string().to_moonbit(), "String")
  assert_eq(TypeRef::float().to_moonbit(), "Float")
  assert_eq(TypeRef::unit().to_moonbit(), "Unit")
}

test "TypeRef::to_moonbit compound types" {
  let arr = TypeRef::array(TypeRef::string())
  assert_eq(arr.to_moonbit(), "Array[String]")

  let opt = TypeRef::option(TypeRef::int())
  assert_eq(opt.to_moonbit(), "Int?")

  let map = TypeRef::map(TypeRef::string(), TypeRef::int())
  assert_eq(map.to_moonbit(), "Map[String, Int]")
}

test "Field::to_moonbit" {
  let field = Field::new("name", TypeRef::string())
  assert_eq(field.to_moonbit(), "name : String")

  let opt_field = Field::optional("age", TypeRef::int())
  assert_eq(opt_field.to_moonbit(), "age : Int?")
}

test "StructDef::to_moonbit" {
  let def = StructDef::new("UserProps")
  let struct_def : StructDef = {
    ..def,
    doc: Some("User component props"),
    fields: [
      Field::new("name", TypeRef::string()),
      Field::optional("age", TypeRef::int()),
    ],
    derives: ["Eq", "Show"],
  }

  let code = struct_def.to_moonbit()
  assert_true(code.contains("/// User component props"))
  assert_true(code.contains("pub struct UserProps"))
  assert_true(code.contains("name : String"))
  assert_true(code.contains("age : Int?"))
  assert_true(code.contains("derive(Eq, Show)"))
}

test "Schema::to_moonbit" {
  let switch_props = StructDef::new("SwitchProps")
  let switch_def : StructDef = {
    ..switch_props,
    fields: [
      Field::new("checked", TypeRef::bool_()),
      Field::optional("label", TypeRef::string()),
    ],
  }

  let defs : Map[String, TypeDef] = {}
  defs["SwitchProps"] = Struct(switch_def)

  let schema : Schema = {
    version: "1.0",
    definitions: defs,
    source: Some({ file: "switch.mbt", lang: MoonBit }),
  }

  let code = schema.to_moonbit()
  assert_true(code.contains("Generated from IR Schema v1.0"))
  assert_true(code.contains("Source: switch.mbt"))
  assert_true(code.contains("pub struct SwitchProps"))
  assert_true(code.contains("checked : Bool"))
  assert_true(code.contains("label : String?"))
}

// =============================================================================
// TypeScript Code Generator Tests
// =============================================================================

test "TypeRef::to_typescript primitives" {
  assert_eq(TypeRef::bool_().to_typescript(), "boolean")
  assert_eq(TypeRef::int().to_typescript(), "number")
  assert_eq(TypeRef::string().to_typescript(), "string")
  assert_eq(TypeRef::unit().to_typescript(), "void")
}

test "TypeRef::to_typescript compound types" {
  let arr = TypeRef::array(TypeRef::string())
  assert_eq(arr.to_typescript(), "string[]")

  let opt = TypeRef::option(TypeRef::int())
  assert_eq(opt.to_typescript(), "number | null")

  let map = TypeRef::map(TypeRef::string(), TypeRef::int())
  assert_eq(map.to_typescript(), "Record<string, number>")
}

test "TypeRef::to_typescript union" {
  let union = TypeRef::union([
    TypeRef::string_lit("open"),
    TypeRef::string_lit("closed"),
  ])
  assert_eq(union.to_typescript(), "\"open\" | \"closed\"")
}

test "Field::to_typescript" {
  let field = Field::new("name", TypeRef::string())
  assert_eq(field.to_typescript(), "name: string")

  let opt_field = Field::optional("age", TypeRef::int())
  assert_eq(opt_field.to_typescript(), "age?: number")
}

test "StructDef::to_typescript" {
  let def = StructDef::new("UserProps")
  let struct_def : StructDef = {
    ..def,
    doc: Some("User component props"),
    fields: [
      Field::new("name", TypeRef::string()),
      Field::optional("age", TypeRef::int()),
    ],
  }

  let code = struct_def.to_typescript()
  assert_true(code.contains("/**"))
  assert_true(code.contains("User component props"))
  assert_true(code.contains("export interface UserProps"))
  assert_true(code.contains("name: string"))
  assert_true(code.contains("age?: number"))
}

test "Schema::to_typescript" {
  let switch_props = StructDef::new("SwitchProps")
  let switch_def : StructDef = {
    ..switch_props,
    fields: [
      Field::new("checked", TypeRef::bool_()),
      Field::optional("label", TypeRef::string()),
    ],
  }

  let defs : Map[String, TypeDef] = {}
  defs["SwitchProps"] = Struct(switch_def)

  let schema : Schema = {
    version: "1.0",
    definitions: defs,
    source: Some({ file: "switch.tsx", lang: TypeScript }),
  }

  let code = schema.to_typescript()
  assert_true(code.contains("Generated from IR Schema v1.0"))
  assert_true(code.contains("Source: switch.tsx"))
  assert_true(code.contains("export interface SwitchProps"))
  assert_true(code.contains("checked: boolean"))
  assert_true(code.contains("label?: string"))
}

// =============================================================================
// MoonBit Parser Tests
// =============================================================================

test "parse_moonbit - simple struct" {
  let source =
    #|/// @island
    #|pub struct SwitchProps {
    #|  checked : Bool
    #|  label : String?
    #|}

  let result = parse_moonbit(source)
  assert_eq(result.errors.length(), 0)
  assert_eq(result.schema.definitions.length(), 1)

  guard result.schema.definitions.get("SwitchProps") is Some(type_def) else {
    fail("Expected SwitchProps to exist")
  }
  guard type_def is Struct(def) else {
    fail("Expected struct SwitchProps")
  }
  assert_eq(def.name, "SwitchProps")
  assert_eq(def.fields.length(), 2)
  assert_eq(def.fields[0].name, "checked")
  assert_eq(def.fields[1].name, "label")
  assert_eq(def.fields[1].optional, true)
}

test "parse_moonbit - struct with doc comment" {
  let source =
    #|/// Switch component props
    #|/// @island
    #|pub struct SwitchProps {
    #|  checked : Bool
    #|}

  let result = parse_moonbit(source)
  assert_eq(result.errors.length(), 0)

  guard result.schema.definitions.get("SwitchProps") is Some(type_def) else {
    fail("Expected SwitchProps to exist")
  }
  guard type_def is Struct(def) else {
    fail("Expected struct SwitchProps")
  }
  assert_eq(def.doc, Some("Switch component props"))
}

test "parse_moonbit - skips non-island structs" {
  let source =
    #|pub struct RegularStruct {
    #|  value : Int
    #|}
    #|
    #|/// @island
    #|pub struct IslandProps {
    #|  name : String
    #|}

  let result = parse_moonbit(source)
  assert_eq(result.errors.length(), 0)
  assert_eq(result.schema.definitions.length(), 1)
  assert_true(result.schema.definitions.contains("IslandProps"))
  assert_true(not(result.schema.definitions.contains("RegularStruct")))
}

test "parse_type_ref - primitives" {
  assert_eq(parse_type_ref("Bool"), Primitive(PrimitiveType::Bool))
  assert_eq(parse_type_ref("Int"), Primitive(PrimitiveType::Int))
  assert_eq(parse_type_ref("String"), Primitive(PrimitiveType::String))
}

test "parse_type_ref - compound types" {
  let arr = parse_type_ref("Array[String]")
  assert_true(arr is Array(_))

  let opt = parse_type_ref("Int?")
  assert_true(opt is Option(_))

  let map = parse_type_ref("Map[String, Int]")
  assert_true(map is Map(_, _))
}

test "parse_type_ref - function type" {
  let func = parse_type_ref("(Bool) -> Unit")
  guard func is Function(f) else { fail("Expected function type") }
  assert_eq(f.params.length(), 1)
  assert_eq(f.return_, Primitive(PrimitiveType::Unit))
}

test "parse_moonbit - roundtrip struct" {
  let source =
    #|/// @island
    #|pub struct CounterProps {
    #|  initial : Int
    #|  on_change : (Int) -> Unit
    #|}

  let result = parse_moonbit(source)
  assert_eq(result.errors.length(), 0)

  // Generate MoonBit code from parsed schema
  let generated = result.schema.to_moonbit()
  assert_true(generated.contains("pub struct CounterProps"))
  assert_true(generated.contains("initial : Int"))
}

// =============================================================================
// TypeScript Parser Tests
// =============================================================================

test "parse_typescript - simple interface" {
  let source =
    #|/** @island */
    #|export interface SwitchProps {
    #|  checked: boolean;
    #|  label?: string;
    #|}

  let result = parse_typescript(source)
  assert_eq(result.errors.length(), 0)
  assert_eq(result.schema.definitions.length(), 1)

  guard result.schema.definitions.get("SwitchProps") is Some(type_def) else {
    fail("Expected SwitchProps to exist")
  }
  guard type_def is Struct(def) else {
    fail("Expected struct SwitchProps")
  }
  assert_eq(def.name, "SwitchProps")
  assert_eq(def.fields.length(), 2)
  assert_eq(def.fields[0].name, "checked")
  assert_eq(def.fields[0].optional, false)
  assert_eq(def.fields[1].name, "label")
  assert_eq(def.fields[1].optional, true)
}

test "parse_typescript - interface with JSDoc" {
  let source =
    #|/**
    #| * Switch component props
    #| * @island
    #| */
    #|export interface SwitchProps {
    #|  checked: boolean;
    #|}

  let result = parse_typescript(source)
  assert_eq(result.errors.length(), 0)

  guard result.schema.definitions.get("SwitchProps") is Some(type_def) else {
    fail("Expected SwitchProps to exist")
  }
  guard type_def is Struct(def) else {
    fail("Expected struct SwitchProps")
  }
  assert_eq(def.doc, Some("Switch component props"))
}

test "parse_typescript - skips non-island interfaces" {
  let source =
    #|export interface RegularInterface {
    #|  value: number;
    #|}
    #|
    #|/** @island */
    #|export interface IslandProps {
    #|  name: string;
    #|}

  let result = parse_typescript(source)
  assert_eq(result.errors.length(), 0)
  assert_eq(result.schema.definitions.length(), 1)
  assert_true(result.schema.definitions.contains("IslandProps"))
  assert_true(not(result.schema.definitions.contains("RegularInterface")))
}

test "parse_ts_type_ref - primitives" {
  assert_eq(parse_ts_type_ref("boolean"), Primitive(PrimitiveType::Bool))
  assert_eq(parse_ts_type_ref("number"), Primitive(PrimitiveType::Int))
  assert_eq(parse_ts_type_ref("string"), Primitive(PrimitiveType::String))
  assert_eq(parse_ts_type_ref("void"), Primitive(PrimitiveType::Unit))
}

test "parse_ts_type_ref - arrays" {
  let arr1 = parse_ts_type_ref("string[]")
  assert_true(arr1 is Array(_))

  let arr2 = parse_ts_type_ref("Array<number>")
  assert_true(arr2 is Array(_))
}

test "parse_ts_type_ref - Record" {
  let rec = parse_ts_type_ref("Record<string, number>")
  assert_true(rec is Map(_, _))
}

test "parse_ts_type_ref - function type" {
  let func = parse_ts_type_ref("(value: boolean) => void")
  guard func is Function(f) else { fail("Expected function type") }
  assert_eq(f.params.length(), 1)
  assert_eq(f.return_, Primitive(PrimitiveType::Unit))
}

test "parse_typescript - roundtrip interface" {
  let source =
    #|/** @island */
    #|export interface CounterProps {
    #|  initial: number;
    #|  onChange: (value: number) => void;
    #|}

  let result = parse_typescript(source)
  assert_eq(result.errors.length(), 0)

  // Generate TypeScript code from parsed schema
  let generated = result.schema.to_typescript()
  assert_true(generated.contains("export interface CounterProps"))
  assert_true(generated.contains("initial: number"))
}

test "parse_typescript_to_moonbit - cross-language codegen" {
  let ts_source =
    #|/** @island */
    #|export interface SwitchProps {
    #|  checked: boolean;
    #|  label?: string;
    #|}

  let result = parse_typescript(ts_source)
  assert_eq(result.errors.length(), 0)

  // Generate MoonBit code from TypeScript source
  let moonbit_code = result.schema.to_moonbit()
  assert_true(moonbit_code.contains("pub struct SwitchProps"))
  assert_true(moonbit_code.contains("checked : Bool"))
  assert_true(moonbit_code.contains("label : String?"))
}
