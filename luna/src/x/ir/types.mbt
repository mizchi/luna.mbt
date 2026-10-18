/// @aspect/type-ir - Language-agnostic type intermediate representation
///
/// This module defines a universal type system that can represent types from
/// multiple programming languages (MoonBit, TypeScript, Rust, Go, etc.)

// =============================================================================
// Schema: Top-level container
// =============================================================================

///|
/// A schema is a collection of type definitions
pub struct Schema {
  /// Schema version for compatibility
  version : String
  /// Named type definitions
  definitions : Map[String, TypeDef]
  /// Source file information (optional)
  source : SourceInfo?
} derive(Eq, Debug)

///|
pub extend Schema with @debug.Debug::{to_repr}

///|
pub extend Schema with Eq::{not_equal, equal}

///|
/// Source file metadata
pub struct SourceInfo {
  file : String
  lang : SourceLang
} derive(Eq, Debug)

///|
pub extend SourceInfo with @debug.Debug::{to_repr}

///|
pub extend SourceInfo with Eq::{not_equal, equal}

///|
/// Supported source languages
pub enum SourceLang {
  MoonBit
  TypeScript
  Rust
  Go
  Unknown(String)
} derive(Eq, Debug)

///|
pub extend SourceLang with @debug.Debug::{to_repr}

///|
pub extend SourceLang with Eq::{not_equal, equal}

// =============================================================================
// Type Definitions
// =============================================================================

///|
/// A named type definition
pub enum TypeDef {
  /// Struct/Record type
  Struct(StructDef)
  /// Enum/Union type
  Enum(EnumDef)
  /// Type alias
  Alias(AliasDef)
} derive(Eq, Debug)

///|
pub extend TypeDef with @debug.Debug::{to_repr}

///|
pub extend TypeDef with Eq::{not_equal, equal}

///|
/// Struct definition
pub struct StructDef {
  /// Type name
  name : String
  /// Documentation comment
  doc : String?
  /// Generic type parameters
  type_params : Array[TypeParam]
  /// Fields
  fields : Array[Field]
  /// Derive attributes (e.g., Serialize, Eq)
  derives : Array[String]
} derive(Eq, Debug)

///|
pub extend StructDef with @debug.Debug::{to_repr}

///|
pub extend StructDef with Eq::{not_equal, equal}

///|
/// Enum definition
pub struct EnumDef {
  /// Type name
  name : String
  /// Documentation comment
  doc : String?
  /// Generic type parameters
  type_params : Array[TypeParam]
  /// Variants
  variants : Array[EnumVariant]
  /// Derive attributes
  derives : Array[String]
} derive(Eq, Debug)

///|
pub extend EnumDef with @debug.Debug::{to_repr}

///|
pub extend EnumDef with Eq::{not_equal, equal}

///|
/// Enum variant
pub struct EnumVariant {
  /// Variant name
  name : String
  /// Documentation comment
  doc : String?
  /// Payload type (None for unit variants)
  payload : TypeRef?
} derive(Eq, Debug)

///|
pub extend EnumVariant with @debug.Debug::{to_repr}

///|
pub extend EnumVariant with Eq::{not_equal, equal}

///|
/// Type alias definition
pub struct AliasDef {
  /// Alias name
  name : String
  /// Documentation comment
  doc : String?
  /// Generic type parameters
  type_params : Array[TypeParam]
  /// Target type
  target : TypeRef
} derive(Eq, Debug)

///|
pub extend AliasDef with @debug.Debug::{to_repr}

///|
pub extend AliasDef with Eq::{not_equal, equal}

// =============================================================================
// Fields
// =============================================================================

///|
/// A struct field
pub struct Field {
  /// Field name
  name : String
  /// Documentation comment
  doc : String?
  /// Field type
  type_ : TypeRef
  /// Is this field optional?
  optional : Bool
  /// Default value (JSON-serializable)
  default : Json?
  /// Field attributes/annotations
  attrs : Map[String, String]
} derive(Eq, Debug)

///|
pub extend Field with @debug.Debug::{to_repr}

///|
pub extend Field with Eq::{not_equal, equal}

// =============================================================================
// Type References
// =============================================================================

///|
/// A reference to a type
pub enum TypeRef {
  /// Primitive types
  Primitive(PrimitiveType)
  /// Array/List type
  Array(TypeRef)
  /// Map/Dictionary type
  Map(TypeRef, TypeRef) // key, value
  /// Tuple type
  Tuple(Array[TypeRef])
  /// Option/Nullable type
  Option(TypeRef)
  /// Reference to a named type
  Named(String)
  /// Generic type application
  Applied(String, Array[TypeRef]) // name, type args
  /// Type parameter reference
  Param(String)
  /// Literal type (for union literals)
  Literal(LiteralType)
  /// Union of types (TypeScript union)
  Union(Array[TypeRef])
  /// Function type
  Function(FunctionType)
  /// Unknown/Any type
  Unknown
} derive(Eq, Debug)

///|
pub extend TypeRef with @debug.Debug::{to_repr}

///|
pub extend TypeRef with Eq::{not_equal, equal}

///|
pub extend TypeRef with Show::{to_string, output}

///|
pub impl Show for TypeRef with fn output(self, logger) {
  logger.write_string(self.to_moonbit())
}

///|
/// Primitive types
pub enum PrimitiveType {
  Bool
  Int
  Int64
  Float
  Float64
  String
  Unit
  Never
} derive(Eq, Debug)

///|
pub extend PrimitiveType with @debug.Debug::{to_repr}

///|
pub extend PrimitiveType with Eq::{not_equal, equal}

///|
/// Literal type values
pub enum LiteralType {
  BoolLit(Bool)
  IntLit(Int)
  StringLit(String)
} derive(Eq, Debug)

///|
pub extend LiteralType with @debug.Debug::{to_repr}

///|
pub extend LiteralType with Eq::{not_equal, equal}

///|
/// Function type
pub struct FunctionType {
  params : Array[TypeRef]
  return_ : TypeRef
} derive(Eq, Debug)

///|
pub extend FunctionType with @debug.Debug::{to_repr}

///|
pub extend FunctionType with Eq::{not_equal, equal}

// =============================================================================
// Generics
// =============================================================================

///|
/// Generic type parameter
pub struct TypeParam {
  /// Parameter name (e.g., "T", "K", "V")
  name : String
  /// Constraint/bound (optional)
  constraint : TypeRef?
  /// Default type (optional)
  default : TypeRef?
} derive(Eq, Debug)

///|
pub extend TypeParam with @debug.Debug::{to_repr}

///|
pub extend TypeParam with Eq::{not_equal, equal}

// =============================================================================
// Annotations/Attributes
// =============================================================================

///|
/// Annotation on a type or field
pub struct Annotation {
  /// Annotation name
  name : String
  /// Annotation arguments
  args : Map[String, Json]
} derive(Eq, Debug)

///|
pub extend Annotation with @debug.Debug::{to_repr}

///|
pub extend Annotation with Eq::{not_equal, equal}

// =============================================================================
// Constructors
// =============================================================================

///|
/// Create an empty schema
pub fn Schema::empty() -> Schema {
  { version: "1.0", definitions: {}, source: None, }
}

///|
/// Create a new schema
pub fn Schema::new(version : String) -> Schema {
  { version, definitions: {}, source: None, }
}

///|
/// Create a struct definition
pub fn StructDef::new(name : String) -> StructDef {
  { name, doc: None, type_params: [], fields: [], derives: [], }
}

///|
/// Create a field
pub fn Field::new(name : String, type_ : TypeRef) -> Field {
  { name, doc: None, type_, optional: false, default: None, attrs: {}, }
}

///|
/// Create an optional field
pub fn Field::optional(name : String, type_ : TypeRef) -> Field {
  { name, doc: None, type_, optional: true, default: None, attrs: {}, }
}

// =============================================================================
// Type Reference Helpers
// =============================================================================

///|
/// Create a Bool type reference
pub fn TypeRef::bool_() -> TypeRef {
  Primitive(PrimitiveType::Bool)
}

///|
/// Create an Int type reference
pub fn TypeRef::int() -> TypeRef {
  Primitive(PrimitiveType::Int)
}

///|
/// Create a Float type reference
pub fn TypeRef::float() -> TypeRef {
  Primitive(PrimitiveType::Float)
}

///|
/// Create a String type reference
pub fn TypeRef::string() -> TypeRef {
  Primitive(PrimitiveType::String)
}

///|
/// Create a Unit type reference
pub fn TypeRef::unit() -> TypeRef {
  Primitive(PrimitiveType::Unit)
}

///|
/// Create an Array type reference
pub fn TypeRef::array(element : TypeRef) -> TypeRef {
  Array(element)
}

///|
/// Create a Map type reference
pub fn TypeRef::map(key : TypeRef, value : TypeRef) -> TypeRef {
  Map(key, value)
}

///|
/// Create an Option type reference
pub fn TypeRef::option(inner : TypeRef) -> TypeRef {
  Option(inner)
}

///|
/// Create a named type reference
pub fn TypeRef::named(name : String) -> TypeRef {
  Named(name)
}

///|
/// Create a type parameter reference
pub fn TypeRef::param(name : String) -> TypeRef {
  Param(name)
}

///|
/// Create a string literal type
pub fn TypeRef::string_lit(value : String) -> TypeRef {
  Literal(LiteralType::StringLit(value))
}

///|
/// Create a union type
pub fn TypeRef::union(types : Array[TypeRef]) -> TypeRef {
  Union(types)
}
