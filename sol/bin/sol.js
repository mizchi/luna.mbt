#!/usr/bin/env node
// Workspace layout: outputs go to <workspace>/_build/js/release/build/<owner>/<package>/...
// This shim is at sol/bin/sol.js, so workspace root is two dirs above.
import "../../_build/js/release/build/mizchi/sol/cmd/sol/sol.js";
