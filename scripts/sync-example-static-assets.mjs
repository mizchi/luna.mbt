import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

const mappings = [
  {
    source: path.join(root, "src", "ssg", "assets", "scripts", "loader.js"),
    targets: [
      path.join(root, "examples", "sol_app", "static", "loader.js"),
      path.join(root, "examples", "sol_auth", "static", "loader.js"),
      path.join(root, "examples", "sol_todo", "static", "loader.js"),
    ],
  },
  {
    source: path.join(root, "src", "ssg", "assets", "scripts", "wc-loader.js"),
    targets: [
      path.join(root, "examples", "sol_app", "static", "wc-loader.js"),
      path.join(root, "examples", "sol_auth", "static", "wc-loader.js"),
    ],
  },
  {
    source: path.join(root, "src", "ssg", "assets", "scripts", "sol-nav.js"),
    targets: [
      path.join(root, "examples", "sol_app", "static", "sol-nav.js"),
      path.join(root, "examples", "sol_auth", "static", "sol-nav.js"),
      path.join(root, "examples", "sol_todo", "static", "sol-nav.js"),
    ],
  },
  {
    source: path.join(root, "src", "ssg", "assets", "scripts", "lib.js"),
    targets: [
      path.join(root, "examples", "sol_app", "static", "lib.js"),
      path.join(root, "examples", "sol_auth", "static", "lib.js"),
    ],
  },
];

function copyFile(source, target) {
  const content = fs.readFileSync(source, "utf-8");
  fs.writeFileSync(target, content);
  return path.relative(root, target);
}

for (const mapping of mappings) {
  for (const target of mapping.targets) {
    const rel = copyFile(mapping.source, target);
    console.log(`synced ${rel}`);
  }
}
