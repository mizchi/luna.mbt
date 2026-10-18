name = "mizchi/astra"

version = "0.23.3"

import {
  "mizchi/js_core@0.13.0",
  "mizchi/js_node@0.13.0",
  "mizchi/luna@0.25.1",
  "mizchi/mars@0.3.13",
  "mizchi/markdown@0.8.3",
  "mizchi/js@0.13.0",
  "mizchi/npm_typed@0.1.18",
  "mizchi/process_pool@0.1.4",
  // Keep markdown/moomaid's transitive dependencies on releases using moon.mod.
  "mizchi/font@0.7.4",
  "mizchi/image@0.4.3",
  "mizchi/pixelmatch@0.6.2",
  "mizchi/tui@0.10.2",
  "mizchi/tui-terminal-buffer@0.1.4",
  "mizchi/svg@0.2.3",
  "mizchi/zlib@0.4.10",
  "mizchi/syntree@0.2.4",
  "mizchi/x@0.6.1",
  "moonbitlang/async@0.22.5",
  "moonbitlang/x@0.5.5",
}

readme = "README.md"

repository = "https://github.com/mizchi/luna.mbt"

license = "MIT"

keywords = [ "astra", "ssg", "mars", "moonbit", "middleware" ]

description = "Mountable Mars middleware for static site generation"

source = "src"

preferred_target = "js"
