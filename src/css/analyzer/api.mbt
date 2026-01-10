/// CSS Static Analyzer - Public API
///
/// Entry points for JavaScript integration.

///|
/// Main entry point (required for is-main package)
fn main {
  // No-op: functions are exported via link.exports
}

///|
/// Analyze a single source file and return JSON result
pub fn analyze_file_json(source : String, file : String) -> String {
  let result = analyze_source(source, file)
  result_to_json(result)
}

///|
/// Convert FileAnalysisResult to JSON
fn result_to_json(result : FileAnalysisResult) -> String {
  let mut json = "{\n"

  // cooccurrences
  json = json + "  \"cooccurrences\": [\n"
  for i, co in result.cooccurrences {
    json = json + "    {\n"
    json = json + "      \"classes\": " + array_to_json(co.classes) + ",\n"
    json = json + "      \"file\": \"" + escape_json(co.file) + "\",\n"
    json = json + "      \"line\": " + co.line.to_string() + ",\n"
    json = json +
      "      \"isStatic\": " +
      (if co.is_static { "true" } else { "false" }) +
      "\n"
    json = json + "    }"
    if i < result.cooccurrences.length() - 1 {
      json = json + ","
    }
    json = json + "\n"
  }
  json = json + "  ],\n"

  // warnings
  json = json + "  \"warnings\": [\n"
  for i, w in result.warnings {
    json = json + "    {\n"
    json = json +
      "      \"kind\": \"" +
      warning_kind_to_string(w.kind) +
      "\",\n"
    json = json + "      \"file\": \"" + escape_json(w.file) + "\",\n"
    json = json + "      \"line\": " + w.line.to_string() + ",\n"
    json = json + "      \"message\": \"" + escape_json(w.message) + "\"\n"
    json = json + "    }"
    if i < result.warnings.length() - 1 {
      json = json + ","
    }
    json = json + "\n"
  }
  json = json + "  ]\n"
  json = json + "}"
  json
}

///|
fn warning_kind_to_string(kind : WarningKind) -> String {
  match kind {
    DynamicConditional => "dynamic_conditional"
    DynamicFunctionCall => "dynamic_function_call"
    UntraceableVariable => "untraceable_variable"
    DynamicArrayConstruction => "dynamic_array_construction"
  }
}

///|
fn array_to_json(arr : Array[String]) -> String {
  let mut json = "["
  for i, s in arr {
    json = json + "\"" + escape_json(s) + "\""
    if i < arr.length() - 1 {
      json = json + ", "
    }
  }
  json + "]"
}

///|
fn escape_json(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => result = result + c.to_string()
    }
  }
  result
}
