///|
/// JSON serialization for IR types
///
/// The JSON format is designed for cross-language compatibility.
/// All types serialize to a canonical JSON structure.

// =============================================================================
// Schema Serialization
// =============================================================================

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
pub impl ToJson for SourceInfo with fn to_json(self) {
  { "file": ToJson::to_json(self.file), "lang": ToJson::to_json(self.lang) }.to_json()
}

///|
pub impl ToJson for SourceLang with fn to_json(self) {
  match self {
    MoonBit => "moonbit".to_json()
    TypeScript => "typescript".to_json()
    Rust => "rust".to_json()
    Go => "go".to_json()
    Unknown(s) => ToJson::to_json(s)
  }
}

// =============================================================================
// TypeDef Serialization
// =============================================================================

///|
pub impl ToJson for TypeDef with fn to_json(self) {
  match self {
    Struct(s) => {
      let obj = s.to_json_obj()
      obj["kind"] = "struct".to_json()
      ToJson::to_json(obj)
    }
    Enum(e) => {
      let obj = e.to_json_obj()
      obj["kind"] = "enum".to_json()
      ToJson::to_json(obj)
    }
    Alias(a) => {
      let obj = a.to_json_obj()
      obj["kind"] = "alias".to_json()
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
pub impl ToJson for TypeRef with fn to_json(self) {
  match self {
    Primitive(p) =>
      { "kind": "primitive".to_json(), "type": ToJson::to_json(p) }.to_json()
    Array(elem) =>
      { "kind": "array".to_json(), "element": ToJson::to_json(elem) }.to_json()
    Map(key, value) =>
      {
        "kind": "map".to_json(),
        "key": ToJson::to_json(key),
        "value": ToJson::to_json(value),
      }.to_json()
    Tuple(elems) =>
      { "kind": "tuple".to_json(), "elements": ToJson::to_json(elems) }.to_json()
    Option(inner) =>
      { "kind": "option".to_json(), "inner": ToJson::to_json(inner) }.to_json()
    Named(name) =>
      { "kind": "named".to_json(), "name": ToJson::to_json(name) }.to_json()
    Applied(name, args) =>
      {
        "kind": "applied".to_json(),
        "name": ToJson::to_json(name),
        "args": ToJson::to_json(args),
      }.to_json()
    Param(name) =>
      { "kind": "param".to_json(), "name": ToJson::to_json(name) }.to_json()
    Literal(lit) =>
      { "kind": "literal".to_json(), "value": ToJson::to_json(lit) }.to_json()
    Union(types) =>
      { "kind": "union".to_json(), "types": ToJson::to_json(types) }.to_json()
    Function(f) =>
      {
        "kind": "function".to_json(),
        "params": ToJson::to_json(f.params),
        "return": ToJson::to_json(f.return_),
      }.to_json()
    Unknown => { "kind": "unknown".to_json() }.to_json()
  }
}

///|
pub impl ToJson for PrimitiveType with fn to_json(self) {
  match self {
    Bool => "bool".to_json()
    Int => "int".to_json()
    Int64 => "int64".to_json()
    Float => "float".to_json()
    Float64 => "float64".to_json()
    String => "string".to_json()
    Unit => "unit".to_json()
    Never => "never".to_json()
  }
}

///|
pub impl ToJson for LiteralType with fn to_json(self) {
  match self {
    BoolLit(b) => { "type": "bool".to_json(), "value": ToJson::to_json(b) }.to_json()
    IntLit(i) => { "type": "int".to_json(), "value": ToJson::to_json(i) }.to_json()
    StringLit(s) =>
      { "type": "string".to_json(), "value": ToJson::to_json(s) }.to_json()
  }
}

// =============================================================================
// TypeParam Serialization
// =============================================================================

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
pub impl ToJson for Annotation with fn to_json(self) {
  { "name": ToJson::to_json(self.name), "args": ToJson::to_json(self.args) }.to_json()
}
