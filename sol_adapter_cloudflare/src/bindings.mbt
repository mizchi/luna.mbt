///| Typed Cloudflare binding contract helpers.

///|
/// Cloudflare binding category used for dev/test validation and docs.
pub(all) enum BindingKind {
  EnvVar
  Secret
  KV
  R2
  D1
  DurableObject
  Service
  AI
  Queue
}

///|
pub fn BindingKind::label(self : BindingKind) -> String {
  match self {
    EnvVar => "var"
    Secret => "secret"
    KV => "kv"
    R2 => "r2"
    D1 => "d1"
    DurableObject => "durable_object"
    Service => "service"
    AI => "ai"
    Queue => "queue"
  }
}

///|
/// One expected Cloudflare binding.
pub(all) struct BindingSpec {
  name : String
  kind : BindingKind
  optional : Bool
}

///|
/// Phantom-typed binding key for generated env contracts.
pub(all) struct BindingKey[T] {
  name : String
  kind : BindingKind
  optional : Bool
  _type : T?
}

///|
pub fn[T] BindingKey::name(self : BindingKey[T]) -> String {
  self.name
}

///|
pub fn[T] BindingKey::kind(self : BindingKey[T]) -> BindingKind {
  self.kind
}

///|
pub fn[T] BindingKey::optional(self : BindingKey[T]) -> Bool {
  self.optional
}

///|
/// A required binding that is missing from the Worker env.
pub(all) struct MissingBinding {
  name : String
  kind : BindingKind
}

///|
pub fn binding(
  name : String,
  kind : BindingKind,
  optional? : Bool = false,
) -> BindingSpec {
  { name, kind, optional }
}

///|
pub fn[T] binding_key(
  name : String,
  kind : BindingKind,
  optional? : Bool = false,
) -> BindingKey[T] {
  { name, kind, optional, _type: None }
}

///|
/// Required plain env var.
pub fn env_var(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, EnvVar, optional~)
}

///|
pub fn env_var_key(
  name : String,
  optional? : Bool = false,
) -> BindingKey[String] {
  binding_key(name, EnvVar, optional~)
}

///|
/// Required secret env var.
pub fn secret(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, Secret, optional~)
}

///|
pub fn secret_key(
  name : String,
  optional? : Bool = false,
) -> BindingKey[String] {
  binding_key(name, Secret, optional~)
}

///|
/// Required KV namespace binding.
pub fn kv_namespace(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, KV, optional~)
}

///|
/// Required R2 bucket binding.
pub fn r2_bucket(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, R2, optional~)
}

///|
/// Required D1 database binding.
pub fn d1_database(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, D1, optional~)
}

///|
/// Required Durable Object namespace binding.
pub fn durable_object(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, DurableObject, optional~)
}

///|
/// Required Service Binding.
pub fn service_binding(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, Service, optional~)
}

///|
/// Required Workers AI binding.
pub fn ai_binding(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, AI, optional~)
}

///|
/// Required Queue binding.
pub fn queue_binding(name : String, optional? : Bool = false) -> BindingSpec {
  binding(name, Queue, optional~)
}

///|
extern "js" fn ffi_env_has_binding(env : @mars.JsEnv, name : String) -> Bool =
  #| (env, name) => env != null && env[name] !== undefined && env[name] !== null

///|
/// Return all missing required bindings for a Cloudflare Worker env.
pub fn missing_required_bindings(
  env : @mars.JsEnv,
  specs : Array[BindingSpec],
) -> Array[MissingBinding] {
  let missing : Array[MissingBinding] = []
  for spec in specs {
    if !spec.optional && !ffi_env_has_binding(env, spec.name) {
      missing.push({ name: spec.name, kind: spec.kind })
    }
  }
  missing
}

///|
/// True when every required binding exists.
pub fn validate_bindings(env : @mars.JsEnv, specs : Array[BindingSpec]) -> Bool {
  missing_required_bindings(env, specs).is_empty()
}

///|
/// Human-readable validation error for missing bindings.
pub fn describe_missing_bindings(missing : Array[MissingBinding]) -> String {
  if missing.is_empty() {
    return "all required Cloudflare bindings are present"
  }
  let buf = StringBuilder::new()
  buf.write_string("missing Cloudflare bindings: ")
  for i, item in missing {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(item.name)
    buf.write_string(" (")
    buf.write_string(item.kind.label())
    buf.write_string(")")
  }
  buf.to_string()
}

///|
pub fn bindings_typescript_decl(
  specs : Array[BindingSpec],
  interface_name? : String = "CloudflareEnv",
) -> String {
  let buf = StringBuilder::new()
  buf.write_string(
    "// Auto-generated Cloudflare binding contract. Do not edit.\n\n",
  )
  buf.write_string("export interface \{interface_name} {\n")
  for spec in specs {
    let marker = if spec.optional { "?" } else { "" }
    buf.write_string(
      "  \{binding_typescript_property_key(spec.name)}\{marker}: \{binding_kind_typescript_type(spec.kind)};\n",
    )
  }
  buf.write_string("}\n")
  buf.to_string()
}

///|
fn binding_kind_typescript_type(kind : BindingKind) -> String {
  match kind {
    EnvVar | Secret => "string"
    KV => "KVNamespace"
    R2 => "R2Bucket"
    D1 => "D1Database"
    DurableObject => "DurableObjectNamespace"
    Service => "Fetcher"
    AI => "Ai"
    Queue => "Queue"
  }
}

///|
fn binding_typescript_property_key(value : String) -> String {
  if binding_is_typescript_identifier(value) {
    value
  } else {
    binding_typescript_string_literal(value)
  }
}

///|
fn binding_is_typescript_identifier(value : String) -> Bool {
  if value.is_empty() {
    return false
  }
  let chars = value.to_array()
  let first = chars[0]
  let first_ok = (first >= 'a' && first <= 'z') ||
    (first >= 'A' && first <= 'Z') ||
    first == '_' ||
    first == '$'
  if !first_ok {
    return false
  }
  for c in chars {
    let ok = (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '_' ||
      c == '$'
    if !ok {
      return false
    }
  }
  true
}

///|
fn binding_typescript_string_literal(value : String) -> String {
  let buf = StringBuilder::new()
  buf.write_char('"')
  for c in value {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  }
  buf.write_char('"')
  buf.to_string()
}
