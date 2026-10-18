name = "mizchi/sol"

version = "0.23.5"

import {
  "mizchi/js_core@0.13.0",
  "mizchi/js_node@0.13.0",
  "mizchi/js_web@0.13.1",
  "moonbitlang/yacc@0.7.25",
  "mizchi/astra@0.23.4",
  "mizchi/luna@0.25.2",
  "moonbitlang/async@0.22.5",
  "moonbitlang/x@0.5.5",
  "moonbitlang/parser@0.4.5",
  "moonbitlang/moon_config@0.4.4",
  "mizchi/npm_typed@0.1.18",
  "mizchi/js@0.13.0",
  "mizchi/js_browser@0.13.0",
  "mizchi/mars@0.3.13",
  "mizchi/ts@0.6.0",
  "mizchi/wite@0.11.3",
  // Override wite's lower bound with the release using moon.mod.
  "mizchi/oci_wasm@0.5.1",
  "mizchi/mwac@0.2.2",
  "mizchi/x@0.6.1",
  "moonbitlang/lexer@0.4.3",
  "mizchi/wit@0.3.3",
}

readme = "README.md"

repository = "https://github.com/mizchi/luna.mbt"

license = "MIT"

keywords = [ "sol", "mars", "moonbit", "ssg", "ssr", "islands", "routing" ]

description = "Thin Mars wrapper for file-based routing, SSR, and asset loading"

source = "src"

warnings = "-6-67"

preferred_target = "js"
