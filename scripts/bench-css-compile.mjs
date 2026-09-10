// Node 24 can load the compiler's erasable TypeScript directly.
import { compileStyles, compileStyleDirectory } from "../js/luna/src/css/compile.ts";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const count = Number(process.argv[2] ?? 1000);
if (!Number.isSafeInteger(count) || count < 1) throw new Error("Expected a positive file count");
const sources = Array.from({ length: count }, (_, i) => `
pub fn component_${i}() -> @css.StyleAttrs {
  @css.attrs([
    @css.create([
      @css.rule(@css.Display, "flex"),
      @css.rule(@css.Width, "var(--width)"),
      @css.rule(@css.Padding, "${i % 16}px"),
      @css.rule_on(@css.Hover, @css.Color, "blue"),
      @css.rule_media("min-width:768px", @css.FontSize, "18px"),
    ]),
    @css.create([@css.rule(@css.Color, "red")]),
  ])
}
`);
for (const source of sources.slice(0, 100)) compileStyles(source);
const timings = [];
for (let run = 0; run < 7; run++) {
  const start = performance.now();
  for (const source of sources) compileStyles(source);
  timings.push(performance.now() - start);
}
const dir = mkdtempSync(join(tmpdir(), "luna-css-bench-"));
try {
  const input = join(dir, "input");
  const outputDir = join(dir, "output");
  mkdirSync(input);
  writeFileSync(join(input, "moon.pkg"), 'import { "mizchi/luna/x/css" }\n');
  sources.forEach((source, i) => writeFileSync(join(input, `component_${i}.mbt`), source));
  const cold = compileStyleDirectory(input, { outputDir });
  const repeated = compileStyleDirectory(input, { outputDir });
  console.log(JSON.stringify({
    files: count,
    declarations: count * 6,
    sourceBytes: sources.reduce((sum, source) => sum + Buffer.byteLength(source), 0),
    inMemoryMedianMs: +timings.sort((a, b) => a - b)[3].toFixed(1),
    stageMs: +cold.elapsedMs.toFixed(1),
    unchangedStageMs: +repeated.elapsedMs.toFixed(1),
    unchangedFilesWritten: repeated.written,
  }, null, 2));
} finally {
  rmSync(dir, { recursive: true, force: true });
}
