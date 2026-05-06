#!/usr/bin/env node
// Workspace dev shim. js/sol/bin/sol.js -> three levels up to workspace
// root, then into _build/js/release/build/mizchi/sol/cmd/sol/sol.js.
//
// Primary install path is `moon install mizchi/sol/cmd/sol`; this
// npm wrapper exists for users who already have node but not moon.
// Published npm builds bundle the moonbit CLI output into ./dist/ via
// js/sol/scripts/build-release.mjs (TODO).
import "../../../_build/js/release/build/mizchi/sol/cmd/sol/sol.js";
