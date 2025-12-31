/// JSON serialization for IR types
///
/// The JSON format is designed for cross-language compatibility.
/// All types serialize to a canonical JSON structure.

// =============================================================================
// Schema Serialization
// =============================================================================

pub impl ToJson for Schema with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["version"] = self.version.to_json()

  let defs : Map[String, Json] = {}
  for name, def in self.definitions {
    defs[name] = def.to_json()
  }
  obj["definitions"] = defs.to_json()

  match self.source {
    Some(s) => obj["source"] = s.to_json()
    None => ()
  }

  obj.to_json()
}

pub impl ToJson for SourceInfo with to_json(self) {
  {
    "file": self.file.to_json(),
    "lang": self.lang.to_json(),
  }.to_json()
}

pub impl ToJson for SourceLang with to_json(self) {
  match self {
    MoonBit => "moonbit".to_json()
    TypeScript => "typescript".to_json()
    Rust => "rust".to_json()
    Go => "go".to_json()
    Unknown(s) => s.to_json()
  }
}

// =============================================================================
// TypeDef Serialization
// =============================================================================

pub impl ToJson for TypeDef with to_json(self) {
  match self {
    Struct(s) => {
      let obj = s.to_json_obj()
      obj["kind"] = "struct".to_json()
      obj.to_json()
    }
    Enum(e) => {
      let obj = e.to_json_obj()
      obj["kind"] = "enum".to_json()
      obj.to_json()
    }
    Alias(a) => {
      let obj = a.to_json_obj()
      obj["kind"] = "alias".to_json()
      obj.to_json()
    }
  }
}

fn StructDef::to_json_obj(self : StructDef) -> Map[String, Json] {
  let obj : Map[String, Json] = {}
  obj["name"] = self.name.to_json()
  match self.doc {
    Some(d) => obj["doc"] = d.to_json()
    None => ()
  }
  if self.type_params.length() > 0 {
    obj["typeParams"] = self.type_params.to_json()
  }
  obj["fields"] = self.fields.to_json()
  if self.derives.length() > 0 {
    obj["derives"] = self.derives.to_json()
  }
  obj
}

fn EnumDef::to_json_obj(self : EnumDef) -> Map[String, Json] {
  let obj : Map[String, Json] = {}
  obj["name"] = self.name.to_json()
  match self.doc {
    Some(d) => obj["doc"] = d.to_json()
    None => ()
  }
  if self.type_params.length() > 0 {
    obj["typeParams"] = self.type_params.to_json()
  }
  obj["variants"] = self.variants.to_json()
  if self.derives.length() > 0 {
    obj["derives"] = self.derives.to_json()
  }
  obj
}

fn AliasDef::to_json_obj(self : AliasDef) -> Map[String, Json] {
  let obj : Map[String, Json] = {}
  obj["name"] = self.name.to_json()
  match self.doc {
    Some(d) => obj["doc"] = d.to_json()
    None => ()
  }
  if self.type_params.length() > 0 {
    obj["typeParams"] = self.type_params.to_json()
  }
  obj["target"] = self.target.to_json()
  obj
}

// =============================================================================
// Field & Variant Serialization
// =============================================================================

pub impl ToJson for Field with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["name"] = self.name.to_json()
  match self.doc {
    Some(d) => obj["doc"] = d.to_json()
    None => ()
  }
  obj["type"] = self.type_.to_json()
  if self.optional {
    obj["optional"] = true.to_json()
  }
  match self.default {
    Some(d) => obj["default"] = d
    None => ()
  }
  if self.attrs.length() > 0 {
    obj["attrs"] = self.attrs.to_json()
  }
  obj.to_json()
}

pub impl ToJson for EnumVariant with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["name"] = self.name.to_json()
  match self.doc {
    Some(d) => obj["doc"] = d.to_json()
    None => ()
  }
  match self.payload {
    Some(p) => obj["payload"] = p.to_json()
    None => ()
  }
  obj.to_json()
}

// =============================================================================
// TypeRef Serialization
// =============================================================================

pub impl ToJson for TypeRef with to_json(self) {
  match self {
    Primitive(p) => {
      { "kind": "primitive".to_json(), "type": p.to_json() }.to_json()
    }
    Array(elem) => {
      { "kind": "array".to_json(), "element": elem.to_json() }.to_json()
    }
    Map(key, value) => {
      { "kind": "map".to_json(), "key": key.to_json(), "value": value.to_json() }.to_json()
    }
    Tuple(elems) => {
      { "kind": "tuple".to_json(), "elements": elems.to_json() }.to_json()
    }
    Option(inner) => {
      { "kind": "option".to_json(), "inner": inner.to_json() }.to_json()
    }
    Named(name) => {
      { "kind": "named".to_json(), "name": name.to_json() }.to_json()
    }
    Applied(name, args) => {
      { "kind": "applied".to_json(), "name": name.to_json(), "args": args.to_json() }.to_json()
    }
    Param(name) => {
      { "kind": "param".to_json(), "name": name.to_json() }.to_json()
    }
    Literal(lit) => {
      { "kind": "literal".to_json(), "value": lit.to_json() }.to_json()
    }
    Union(types) => {
      { "kind": "union".to_json(), "types": types.to_json() }.to_json()
    }
    Function(f) => {
      { "kind": "function".to_json(), "params": f.params.to_json(), "return": f.return_.to_json() }.to_json()
    }
    Unknown => {
      { "kind": "unknown".to_json() }.to_json()
    }
  }
}

pub impl ToJson for PrimitiveType with to_json(self) {
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

pub impl ToJson for LiteralType with to_json(self) {
  match self {
    BoolLit(b) => { "type": "bool".to_json(), "value": b.to_json() }.to_json()
    IntLit(i) => { "type": "int".to_json(), "value": i.to_json() }.to_json()
    StringLit(s) => { "type": "string".to_json(), "value": s.to_json() }.to_json()
  }
}

// =============================================================================
// TypeParam Serialization
// =============================================================================

pub impl ToJson for TypeParam with to_json(self) {
  let obj : Map[String, Json] = {}
  obj["name"] = self.name.to_json()
  match self.constraint {
    Some(c) => obj["constraint"] = c.to_json()
    None => ()
  }
  match self.default {
    Some(d) => obj["default"] = d.to_json()
    None => ()
  }
  obj.to_json()
}

// =============================================================================
// Annotation Serialization
// =============================================================================

pub impl ToJson for Annotation with to_json(self) {
  {
    "name": self.name.to_json(),
    "args": self.args.to_json(),
  }.to_json()
}
