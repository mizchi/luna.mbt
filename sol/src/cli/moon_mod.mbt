///| Helpers for MoonBit module manifests.
///
/// New projects use `moon.mod`; older Sol projects may still have
/// `moon.mod.json`. CLI checks accept both, preferring `moon.mod` when both
/// are present.

///|
fn[FS : @env.FileSystem] find_moon_mod_path_with_fs(
  fs : FS,
  cwd : String,
) -> String? {
  let moon_mod_path = @path.join2(cwd, "moon.mod")
  if fs.exists_sync(moon_mod_path) {
    return Some(moon_mod_path)
  }
  let legacy_path = @path.join2(cwd, "moon.mod.json")
  if fs.exists_sync(legacy_path) {
    return Some(legacy_path)
  }
  None
}

///|
fn[FS : @env.FileSystem] has_moon_mod_with_fs(fs : FS, cwd : String) -> Bool {
  find_moon_mod_path_with_fs(fs, cwd).is_some()
}

///|
fn[FS : @env.FileSystem] read_mod_info_from_cwd_with_fs(
  fs : FS,
  cwd : String,
) -> (String, String) {
  match find_moon_mod_path_with_fs(fs, cwd) {
    Some(path) => read_mod_info_from_path_with_fs(fs, path)
    None => ("", "")
  }
}

///|
fn[FS : @env.FileSystem] read_mod_info_from_path_with_fs(
  fs : FS,
  mod_path : String,
) -> (String, String) {
  let content : String = fs.read_file_sync(mod_path) catch {
    _ => return ("", "")
  }
  if content.length() == 0 {
    return ("", "")
  }
  if mod_path.has_suffix(".json") || content.trim_start().has_prefix("{") {
    read_mod_info_from_json(content)
  } else {
    let name = moon_mod_string_field(content, "name").unwrap_or("")
    let source = moon_mod_string_field(content, "source").unwrap_or("")
    (name, source)
  }
}

///|
fn read_mod_info_from_json(content : String) -> (String, String) {
  let json = @json.parse(content.view()) catch { _ => return ("", "") }
  match json {
    Object(obj) => {
      let name = match obj.get("name") {
        Some(String(n)) => n
        _ => ""
      }
      let source = match obj.get("source") {
        Some(String(s)) => s
        _ => ""
      }
      (name, source)
    }
    _ => ("", "")
  }
}

///|
fn moon_mod_string_field(content : String, field : String) -> String? {
  for raw_line in content.split("\n") {
    let line = strip_moon_mod_comment(raw_line.to_owned()).trim().to_owned()
    match line.split_once("=") {
      Some((left, right)) =>
        if left.trim().to_owned() == field {
          return parse_moon_mod_string_literal(right.to_owned())
        }
      None => ()
    }
  }
  None
}

///|
fn strip_moon_mod_comment(line : String) -> String {
  match line.find("//") {
    Some(idx) => line[:idx].to_owned()
    None => line
  }
}

///|
fn parse_moon_mod_string_literal(raw : String) -> String? {
  let s = raw.trim().to_owned()
  if !s.has_prefix("\"") {
    return None
  }
  let tail = s[1:].to_owned()
  match tail.find("\"") {
    Some(end) => Some(tail[:end].to_owned())
    None => None
  }
}
