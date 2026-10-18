name = "mizchi/luna"

version = "0.25.1"

import {
  "mizchi/js_builtin@0.13.0",
  "mizchi/js_core@0.13.0",
  "mizchi/js_web@0.13.1",
  "moonbitlang/async@0.22.5",
  "moonbitlang/x@0.5.5",
  "mizchi/js@0.13.0",
  "mizchi/js_browser@0.13.0",
  "mizchi/npm_typed@0.1.18",
  "moonbitlang/parser@0.4.5",
  "mizchi/signals@0.6.6",
  "mizchi/x@0.6.1",
  // Override x's lower bound with the release using moon.mod.
  "moonbitlang/regexp@0.3.6",
  "moonbitlang/lexer@0.4.3",
}

readme = "README.md"

repository = "https://github.com/mizchi/luna.mbt"

license = "MIT"

keywords = [ "luna", "ui", "signals" ]

description = "Fine-grained reactive UI library for Moonbit/JS"

source = "src"

warnings = "-6-unused_trait_bound"

preferred_target = "js"
