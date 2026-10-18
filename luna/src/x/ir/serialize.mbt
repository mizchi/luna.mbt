///|
/// JSON serialization for IR types
///
/// The JSON format is designed for cross-language compatibility.
/// All types serialize to a canonical JSON structure.

// =============================================================================
// Schema Serialization
// =============================================================================

///|
pub extend Schema with ToJson::{to_json}

///|
pub impl ToJson for Schema with fn to_json(self) {
  let obj : Map[String, Json] = Map([])
  obj["version"] = ToJson::to_json(self.version)
  let defs : Map[String, Json] = Map([])
  for name, def in self.definitions {
    defs[name] = ToJson::to_json(def)
  }
  obj["definitions"] = ToJson::to_json(defs)
  match self.source {
    Some(s) => obj["source"] = ToJson::to_json(s)
    None => ()
  }
  ToJson::to_json(obj)
}

///|
pub extend SourceInfo with ToJson::{to_json}

///|
pub impl ToJson for SourceInfo with fn to_json(self) {
  Json({
    "file": ToJson::to_json(self.file),
    "lang": ToJson::to_json(self.lang),
  })
}

///|
pub extend SourceLang with ToJson::{to_json}

///|
pub impl ToJson for SourceLang with fn to_json(self) {
  match self {
    MoonBit => Json("moonbit")
    TypeScript => Json("typescript")
    Rust => Json("rust")
    Go => Json("go")
    Unknown(s) => ToJson::to_json(s)
  }
}

// =============================================================================
// TypeDef Serialization
// =============================================================================

///|
pub extend TypeDef with ToJson::{to_json}

///|
pub impl ToJson for TypeDef with fn to_json(self) {
  match self {
    Struct(s) => {
      let obj = s.to_json_obj()
      obj["kind"] = Json("struct")
      ToJson::to_json(obj)
    }
    Enum(e) => {
      let obj = e.to_json_obj()
      obj["kind"] = Json("enum")
      ToJson::to_json(obj)
    }
    Alias(a) => {
      let obj = a.to_json_obj()
      obj["kind"] = Json("alias")
      ToJson::to_json(obj)
    }
  }
}

///|
fn StructDef::to_json_obj(self : StructDef) -> Map[String, Json] {
  let obj : Map[String, Json] = Map([])
  obj["name"] = ToJson::to_json(self.name)
  match self.doc {
    Some(d) => obj["doc"] = ToJson::to_json(d)
    None => ()
  }
  if self.type_params.length() > 0 {
    obj["typeParams"] = ToJson::to_json(self.type_params)
  }
  obj["fields"] = ToJson::to_json(self.fields)
  if self.derives.length() > 0 {
    obj["derives"] = ToJson::to_json(self.derives)
  }
  obj
}

///|
fn EnumDef::to_json_obj(self : EnumDef) -> Map[String, Json] {
  let obj : Map[String, Json] = Map([])
  obj["name"] = ToJson::to_json(self.name)
  match self.doc {
    Some(d) => obj["doc"] = ToJson::to_json(d)
    None => ()
  }
  if self.type_params.length() > 0 {
    obj["typeParams"] = ToJson::to_json(self.type_params)
  }
  obj["variants"] = ToJson::to_json(self.variants)
  if self.derives.length() > 0 {
    obj["derives"] = ToJson::to_json(self.derives)
  }
  obj
}

///|
fn AliasDef::to_json_obj(self : AliasDef) -> Map[String, Json] {
  let obj : Map[String, Json] = Map([])
  obj["name"] = ToJson::to_json(self.name)
  match self.doc {
    Some(d) => obj["doc"] = ToJson::to_json(d)
    None => ()
  }
  if self.type_params.length() > 0 {
    obj["typeParams"] = ToJson::to_json(self.type_params)
  }
  obj["target"] = ToJson::to_json(self.target)
  obj
}

// =============================================================================
// Field & Variant Serialization
// =============================================================================

///|
pub extend Field with ToJson::{to_json}

///|
pub impl ToJson for Field with fn to_json(self) {
  let obj : Map[String, Json] = Map([])
  obj["name"] = ToJson::to_json(self.name)
  match self.doc {
    Some(d) => obj["doc"] = ToJson::to_json(d)
    None => ()
  }
  obj["type"] = ToJson::to_json(self.type_)
  if self.optional {
    obj["optional"] = ToJson::to_json(true)
  }
  match self.default {
    Some(d) => obj["default"] = d
    None => ()
  }
  if self.attrs.length() > 0 {
    obj["attrs"] = ToJson::to_json(self.attrs)
  }
  ToJson::to_json(obj)
}

///|
pub extend EnumVariant with ToJson::{to_json}

///|
pub impl ToJson for EnumVariant with fn to_json(self) {
  let obj : Map[String, Json] = Map([])
  obj["name"] = ToJson::to_json(self.name)
  match self.doc {
    Some(d) => obj["doc"] = ToJson::to_json(d)
    None => ()
  }
  match self.payload {
    Some(p) => obj["payload"] = ToJson::to_json(p)
    None => ()
  }
  ToJson::to_json(obj)
}

// =============================================================================
// TypeRef Serialization
// =============================================================================

///|
pub extend TypeRef with ToJson::{to_json}

///|
pub impl ToJson for TypeRef with fn to_json(self) {
  match self {
    Primitive(p) =>
      Json({ "kind": Json("primitive"), "type": ToJson::to_json(p) })
    Array(elem) =>
      Json({ "kind": Json("array"), "element": ToJson::to_json(elem) })
    Map(key, value) =>
      Json({
        "kind": Json("map"),
        "key": ToJson::to_json(key),
        "value": ToJson::to_json(value),
      })
    Tuple(elems) =>
      Json({ "kind": Json("tuple"), "elements": ToJson::to_json(elems) })
    Option(inner) =>
      Json({ "kind": Json("option"), "inner": ToJson::to_json(inner) })
    Named(name) =>
      Json({ "kind": Json("named"), "name": ToJson::to_json(name) })
    Applied(name, args) =>
      Json({
        "kind": Json("applied"),
        "name": ToJson::to_json(name),
        "args": ToJson::to_json(args),
      })
    Param(name) =>
      Json({ "kind": Json("param"), "name": ToJson::to_json(name) })
    Literal(lit) =>
      Json({ "kind": Json("literal"), "value": ToJson::to_json(lit) })
    Union(types) =>
      Json({ "kind": Json("union"), "types": ToJson::to_json(types) })
    Function(f) =>
      Json({
        "kind": Json("function"),
        "params": ToJson::to_json(f.params),
        "return": ToJson::to_json(f.return_),
      })
    Unknown => Json({ "kind": Json("unknown") })
  }
}

///|
pub extend PrimitiveType with ToJson::{to_json}

///|
pub impl ToJson for PrimitiveType with fn to_json(self) {
  match self {
    Bool => Json("bool")
    Int => Json("int")
    Int64 => Json("int64")
    Float => Json("float")
    Float64 => Json("float64")
    String => Json("string")
    Unit => Json("unit")
    Never => Json("never")
  }
}

///|
pub extend LiteralType with ToJson::{to_json}

///|
pub impl ToJson for LiteralType with fn to_json(self) {
  match self {
    BoolLit(b) => Json({ "type": Json("bool"), "value": ToJson::to_json(b) })
    IntLit(i) => Json({ "type": Json("int"), "value": ToJson::to_json(i) })
    StringLit(s) =>
      Json({ "type": Json("string"), "value": ToJson::to_json(s) })
  }
}

// =============================================================================
// TypeParam Serialization
// =============================================================================

///|
pub extend TypeParam with ToJson::{to_json}

///|
pub impl ToJson for TypeParam with fn to_json(self) {
  let obj : Map[String, Json] = Map([])
  obj["name"] = ToJson::to_json(self.name)
  match self.constraint {
    Some(c) => obj["constraint"] = ToJson::to_json(c)
    None => ()
  }
  match self.default {
    Some(d) => obj["default"] = ToJson::to_json(d)
    None => ()
  }
  ToJson::to_json(obj)
}

// =============================================================================
// Annotation Serialization
// =============================================================================

///|
pub extend Annotation with ToJson::{to_json}

///|
pub impl ToJson for Annotation with fn to_json(self) {
  Json({
    "name": ToJson::to_json(self.name),
    "args": ToJson::to_json(self.args),
  })
}
