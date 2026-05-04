#!/usr/bin/env node
// Workspace dev shim. js/sol/bin/sol.js -> three levels up to workspace
// root, then into _build/js/release/build/mizchi/sol/cli/cli.js.
//
// For npm-published builds, bundle the moonbit CLI output into ./dist/
// via a release script (TODO: see js/sol/scripts/build-release.mjs).
import "../../../_build/js/release/build/mizchi/sol/cli/cli.js";
