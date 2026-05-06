#!/usr/bin/env node
// Workspace layout: outputs go to <workspace>/_build/js/release/build/<owner>/<package>/...
// This shim is at astra/bin/astra.js, so workspace root is one dir above astra/.
import "../../_build/js/release/build/mizchi/astra/cmd/astra/astra.js";
