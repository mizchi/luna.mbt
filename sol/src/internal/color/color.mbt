///| Minimal colorette-compatible ANSI helpers for installable CLI output.

///|
let reset : String = "\u001b[0m"

///|
fn wrap(code : String, text : String) -> String {
  if is_color_supported() {
    "\u001b[" + code + "m" + text + reset
  } else {
    text
  }
}

///|
fn is_color_supported() -> Bool {
  ffi_is_color_supported()
}

///|
extern "js" fn ffi_is_color_supported() -> Bool =
  #| () => {
  #|   const env = globalThis?.process?.env ?? {};
  #|   if ("NO_COLOR" in env || env.FORCE_COLOR === "0") return false;
  #|   if (env.FORCE_COLOR != null && env.FORCE_COLOR !== "") return true;
  #|   return !!globalThis?.process?.stdout?.isTTY;
  #| }

///|
pub fn red(text : String) -> String {
  wrap("31", text)
}

///|
pub fn green(text : String) -> String {
  wrap("32", text)
}

///|
pub fn yellow(text : String) -> String {
  wrap("33", text)
}

///|
pub fn cyan(text : String) -> String {
  wrap("36", text)
}

///|
pub fn gray(text : String) -> String {
  wrap("90", text)
}
