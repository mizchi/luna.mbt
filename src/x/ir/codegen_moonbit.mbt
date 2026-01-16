/// MoonBit code generator from IR Schema
///
/// Generates MoonBit source code from the IR type definitions.

// =============================================================================
// Main Generator
// =============================================================================

///|
/// Generate MoonBit source code from a schema
pub fn Schema::to_moonbit(self : Schema) -> String {
  let buf = StringBuilder::new()

  // Add header comment
  buf.write_string("// Generated from IR Schema v")
  buf.write_string(self.version)
  buf.write_string("\n")
  match self.source {
    Some(src) => {
      buf.write_string("// Source: ")
      buf.write_string(src.file)
      buf.write_string(" (")
      buf.write_string(src.lang.to_string())
      buf.write_string(")\n")
    }
    None => ()
  }
  buf.write_string("\n")

  // Generate each definition
  for name, def in self.definitions {
    let code = def.to_moonbit()
    buf.write_string(code)
    buf.write_string("\n")
    let _ = name

  }
  buf.to_string()
}

// =============================================================================
// TypeDef Generator
// =============================================================================

///|
/// Generate MoonBit code for a type definition
pub fn TypeDef::to_moonbit(self : TypeDef) -> String {
  match self {
    Struct(s) => s.to_moonbit()
    Enum(e) => e.to_moonbit()
    Alias(a) => a.to_moonbit()
  }
}

///|
/// Generate MoonBit code for a struct definition
pub fn StructDef::to_moonbit(self : StructDef) -> String {
  let buf = StringBuilder::new()

  // Doc comment
  match self.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }

  // Struct declaration
  buf.write_string("pub struct ")
  buf.write_string(self.name)

  // Type parameters
  if self.type_params.length() > 0 {
    buf.write_string("[")
    for i, param in self.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(param.to_moonbit())
    }
    buf.write_string("]")
  }
  buf.write_string(" {\n")

  // Fields
  for field in self.fields {
    buf.write_string("  ")
    buf.write_string(field.to_moonbit())
    buf.write_string("\n")
  }
  buf.write_string("}")

  // Derive clause
  if self.derives.length() > 0 {
    buf.write_string(" derive(")
    for i, d in self.derives {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(d)
    }
    buf.write_string(")")
  }
  buf.write_string("\n")
  buf.to_string()
}

///|
/// Generate MoonBit code for an enum definition
pub fn EnumDef::to_moonbit(self : EnumDef) -> String {
  let buf = StringBuilder::new()

  // Doc comment
  match self.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }

  // Enum declaration
  buf.write_string("pub enum ")
  buf.write_string(self.name)

  // Type parameters
  if self.type_params.length() > 0 {
    buf.write_string("[")
    for i, param in self.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(param.to_moonbit())
    }
    buf.write_string("]")
  }
  buf.write_string(" {\n")

  // Variants
  for variant in self.variants {
    buf.write_string("  ")
    buf.write_string(variant.to_moonbit())
    buf.write_string("\n")
  }
  buf.write_string("}")

  // Derive clause
  if self.derives.length() > 0 {
    buf.write_string(" derive(")
    for i, d in self.derives {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(d)
    }
    buf.write_string(")")
  }
  buf.write_string("\n")
  buf.to_string()
}

///|
/// Generate MoonBit code for a type alias
pub fn AliasDef::to_moonbit(self : AliasDef) -> String {
  let buf = StringBuilder::new()

  // Doc comment
  match self.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }

  // Type alias declaration
  buf.write_string("pub typealias ")
  buf.write_string(self.name)

  // Type parameters
  if self.type_params.length() > 0 {
    buf.write_string("[")
    for i, param in self.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(param.to_moonbit())
    }
    buf.write_string("]")
  }
  buf.write_string(" = ")
  buf.write_string(self.target.to_moonbit())
  buf.write_string("\n")
  buf.to_string()
}

// =============================================================================
// Field & Variant Generator
// =============================================================================

///|
/// Generate MoonBit code for a field
pub fn Field::to_moonbit(self : Field) -> String {
  let buf = StringBuilder::new()

  // Field name
  buf.write_string(self.name)
  buf.write_string(" : ")

  // Field type (wrap in Option if optional)
  if self.optional {
    buf.write_string(self.type_.to_moonbit())
    buf.write_string("?")
  } else {
    buf.write_string(self.type_.to_moonbit())
  }
  buf.to_string()
}

///|
/// Generate MoonBit code for an enum variant
pub fn EnumVariant::to_moonbit(self : EnumVariant) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.name)
  match self.payload {
    Some(payload) => {
      buf.write_string("(")
      buf.write_string(payload.to_moonbit())
      buf.write_string(")")
    }
    None => ()
  }
  buf.to_string()
}

// =============================================================================
// TypeRef Generator
// =============================================================================

///|
/// Generate MoonBit code for a type reference
pub fn TypeRef::to_moonbit(self : TypeRef) -> String {
  match self {
    Primitive(p) => p.to_moonbit()
    Array(elem) => "Array[" + elem.to_moonbit() + "]"
    Map(key, value) =>
      "Map[" + key.to_moonbit() + ", " + value.to_moonbit() + "]"
    Tuple(elems) => {
      let parts : Array[String] = []
      for elem in elems {
        parts.push(elem.to_moonbit())
      }
      "(" + parts.join(", ") + ")"
    }
    Option(inner) => inner.to_moonbit() + "?"
    Named(name) => name
    Applied(name, args) => {
      let parts : Array[String] = []
      for arg in args {
        parts.push(arg.to_moonbit())
      }
      name + "[" + parts.join(", ") + "]"
    }
    Param(name) => name
    Literal(_) => "String" // MoonBit doesn't have literal types, use String
    Union(_) => "Json" // MoonBit doesn't have union types, use Json
    Function(f) => {
      let params : Array[String] = []
      for param in f.params {
        params.push(param.to_moonbit())
      }
      "(" + params.join(", ") + ") -> " + f.return_.to_moonbit()
    }
    Unknown => "Json"
  }
}

///|
/// Generate MoonBit code for a primitive type
pub fn PrimitiveType::to_moonbit(self : PrimitiveType) -> String {
  match self {
    Bool => "Bool"
    Int => "Int"
    Int64 => "Int64"
    Float => "Float"
    Float64 => "Double"
    String => "String"
    Unit => "Unit"
    Never => "Unit" // MoonBit uses Unit for never-returning
  }
}

// =============================================================================
// TypeParam Generator
// =============================================================================

///|
/// Generate MoonBit code for a type parameter
pub fn TypeParam::to_moonbit(self : TypeParam) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.name)
  match self.constraint {
    Some(constraint) => {
      buf.write_string(" : ")
      buf.write_string(constraint.to_moonbit())
    }
    None => ()
  }
  buf.to_string()
}

// =============================================================================
// SourceLang Helper
// =============================================================================

///|
fn SourceLang::to_string(self : SourceLang) -> String {
  match self {
    MoonBit => "moonbit"
    TypeScript => "typescript"
    Rust => "rust"
    Go => "go"
    Unknown(s) => s
  }
}
