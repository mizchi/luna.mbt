/// TypeScript code generator from IR Schema
///
/// Generates TypeScript source code from the IR type definitions.

// =============================================================================
// Main Generator
// =============================================================================

///|
/// Generate TypeScript source code from a schema
pub fn Schema::to_typescript(self : Schema) -> String {
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
    let code = def.to_typescript()
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
/// Generate TypeScript code for a type definition
pub fn TypeDef::to_typescript(self : TypeDef) -> String {
  match self {
    Struct(s) => s.to_typescript()
    Enum(e) => e.to_typescript()
    Alias(a) => a.to_typescript()
  }
}

///|
/// Generate TypeScript code for a struct definition (as interface)
pub fn StructDef::to_typescript(self : StructDef) -> String {
  let buf = StringBuilder::new()

  // JSDoc comment
  match self.doc {
    Some(doc) => {
      buf.write_string("/**\n * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }

  // Interface declaration
  buf.write_string("export interface ")
  buf.write_string(self.name)

  // Type parameters
  if self.type_params.length() > 0 {
    buf.write_string("<")
    for i, param in self.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(param.to_typescript())
    }
    buf.write_string(">")
  }
  buf.write_string(" {\n")

  // Fields
  for field in self.fields {
    buf.write_string("  ")
    buf.write_string(field.to_typescript())
    buf.write_string(";\n")
  }
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Generate TypeScript code for an enum definition
pub fn EnumDef::to_typescript(self : EnumDef) -> String {
  let buf = StringBuilder::new()

  // JSDoc comment
  match self.doc {
    Some(doc) => {
      buf.write_string("/**\n * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }

  // Check if it's a simple enum (no payloads) or a discriminated union
  let has_payloads = self.variants.iter().any(fn(v) { v.payload is Some(_) })
  if has_payloads {
    // Generate discriminated union
    buf.write_string("export type ")
    buf.write_string(self.name)
    if self.type_params.length() > 0 {
      buf.write_string("<")
      for i, param in self.type_params {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string(param.to_typescript())
      }
      buf.write_string(">")
    }
    buf.write_string(" =\n")
    for i, variant in self.variants {
      if i > 0 {
        buf.write_string("\n")
      }
      buf.write_string("  | { type: \"")
      buf.write_string(variant.name)
      buf.write_string("\"")
      match variant.payload {
        Some(payload) => {
          buf.write_string("; value: ")
          buf.write_string(payload.to_typescript())
        }
        None => ()
      }
      buf.write_string(" }")
    }
    buf.write_string(";\n")
  } else {
    // Generate string literal union
    buf.write_string("export type ")
    buf.write_string(self.name)
    buf.write_string(" =\n")
    for i, variant in self.variants {
      if i > 0 {
        buf.write_string("\n")
      }
      buf.write_string("  | \"")
      buf.write_string(variant.name)
      buf.write_string("\"")
    }
    buf.write_string(";\n")
  }
  buf.to_string()
}

///|
/// Generate TypeScript code for a type alias
pub fn AliasDef::to_typescript(self : AliasDef) -> String {
  let buf = StringBuilder::new()

  // JSDoc comment
  match self.doc {
    Some(doc) => {
      buf.write_string("/**\n * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }

  // Type alias declaration
  buf.write_string("export type ")
  buf.write_string(self.name)

  // Type parameters
  if self.type_params.length() > 0 {
    buf.write_string("<")
    for i, param in self.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(param.to_typescript())
    }
    buf.write_string(">")
  }
  buf.write_string(" = ")
  buf.write_string(self.target.to_typescript())
  buf.write_string(";\n")
  buf.to_string()
}

// =============================================================================
// Field Generator
// =============================================================================

///|
/// Generate TypeScript code for a field
pub fn Field::to_typescript(self : Field) -> String {
  let buf = StringBuilder::new()

  // Field name with optional marker
  buf.write_string(self.name)
  if self.optional {
    buf.write_string("?")
  }
  buf.write_string(": ")

  // Field type
  buf.write_string(self.type_.to_typescript())
  buf.to_string()
}

// =============================================================================
// TypeRef Generator
// =============================================================================

///|
/// Generate TypeScript code for a type reference
pub fn TypeRef::to_typescript(self : TypeRef) -> String {
  match self {
    Primitive(p) => p.to_typescript()
    Array(elem) => elem.to_typescript() + "[]"
    Map(key, value) =>
      "Record<" + key.to_typescript() + ", " + value.to_typescript() + ">"
    Tuple(elems) => {
      let parts : Array[String] = []
      for elem in elems {
        parts.push(elem.to_typescript())
      }
      "[" + parts.join(", ") + "]"
    }
    Option(inner) => inner.to_typescript() + " | null"
    Named(name) => name
    Applied(name, args) => {
      let parts : Array[String] = []
      for arg in args {
        parts.push(arg.to_typescript())
      }
      name + "<" + parts.join(", ") + ">"
    }
    Param(name) => name
    Literal(lit) => lit.to_typescript()
    Union(types) => {
      let parts : Array[String] = []
      for t in types {
        parts.push(t.to_typescript())
      }
      parts.join(" | ")
    }
    Function(f) => {
      let params : Array[String] = []
      for i, param in f.params {
        params.push("arg" + i.to_string() + ": " + param.to_typescript())
      }
      "(" + params.join(", ") + ") => " + f.return_.to_typescript()
    }
    Unknown => "unknown"
  }
}

///|
/// Generate TypeScript code for a primitive type
pub fn PrimitiveType::to_typescript(self : PrimitiveType) -> String {
  match self {
    Bool => "boolean"
    Int => "number"
    Int64 => "bigint"
    Float => "number"
    Float64 => "number"
    String => "string"
    Unit => "void"
    Never => "never"
  }
}

///|
/// Generate TypeScript code for a literal type
pub fn LiteralType::to_typescript(self : LiteralType) -> String {
  match self {
    BoolLit(b) => if b { "true" } else { "false" }
    IntLit(i) => i.to_string()
    StringLit(s) => "\"" + s + "\""
  }
}

// =============================================================================
// TypeParam Generator
// =============================================================================

///|
/// Generate TypeScript code for a type parameter
pub fn TypeParam::to_typescript(self : TypeParam) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.name)
  match self.constraint {
    Some(constraint) => {
      buf.write_string(" extends ")
      buf.write_string(constraint.to_typescript())
    }
    None => ()
  }
  match self.default {
    Some(default_type) => {
      buf.write_string(" = ")
      buf.write_string(default_type.to_typescript())
    }
    None => ()
  }
  buf.to_string()
}
