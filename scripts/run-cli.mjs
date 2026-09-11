#!/usr/bin/env node
import { buildWorkspaceCli } from "./lib/workspace-cli.mjs";

// Keep the caller's working directory and CLI arguments for dev/build/generate.
const [name] = process.argv.splice(2, 1);
await import(buildWorkspaceCli(name));
