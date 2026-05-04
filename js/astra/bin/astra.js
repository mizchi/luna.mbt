#!/usr/bin/env node
// Workspace dev shim. js/astra/bin/astra.js -> three levels up to
// workspace root, then into _build/js/release/build/mizchi/astra/cli/main/main.js.
//
// For npm-published builds, bundle the moonbit CLI output into ./dist/
// via a release script (TODO: see js/astra/scripts/build-release.mjs).
import "../../../_build/js/release/build/mizchi/astra/cli/main/main.js";
