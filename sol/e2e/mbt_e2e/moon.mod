name = "sol_e2e"

version = "0.1.0"

import {
  "mizchi/playwright@0.3.9",
  // playwright's lower bound still selects a legacy moon.mod.json archive.
  "mizchi/webdriver@0.2.7",
  "moonbitlang/regexp@0.3.6",
  "moonbitlang/async@0.22.5",
}

source = "src"

preferred_target = "js"

supported_targets = "js"
