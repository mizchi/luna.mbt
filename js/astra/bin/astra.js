#!/usr/bin/env node
// Workspace dev shim. js/astra/bin/astra.js -> three levels up to
// workspace root, then into _build/js/release/build/mizchi/astra/cmd/astra/astra.js.
//
// Primary install path is `moon install mizchi/astra/cmd/astra`; this
// npm wrapper exists for users who already have node but not moon.
// Published npm builds bundle the moonbit CLI output into ./dist/ via
// js/astra/scripts/build-release.mjs (TODO).
import "../../../_build/js/release/build/mizchi/astra/cmd/astra/astra.js";
