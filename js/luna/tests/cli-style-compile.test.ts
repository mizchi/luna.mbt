import { afterEach, describe, expect, test } from "vitest";
import { mkdtempSync, mkdirSync, readFileSync, readdirSync, copyFileSync, cpSync, writeFileSync, rmSync, existsSync, statSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { execFileSync } from "node:child_process";
import { compileStyles, compileStyleDirectory } from "../src/css/compile.js";
import { extractFromContent, generateCSS } from "../src/css/extract.js";

const dirs: string[] = [];
const temp = () => { const dir = mkdtempSync(join(tmpdir(), "luna-style-compile-")); dirs.push(dir); return dir; };
afterEach(() => { for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true }); });

const base = '@css.create([@css.rule(@css.Color, "red"), @css.rule_on(@css.Hover, @css.Color, "blue"), @css.rule(@css.Display, "flex")])';
const override = '@css.create([@css.rule(@css.Color, "green")])';
const source = `pub fn result() -> @css.StyleAttrs { @css.attrs([${base}, ${override}]) }`;

describe("static style compilation", () => {
  test("static compilation folds static attributes with property-group overrides", () => {
    const result = compileStyles(source);
    const css = generateCSS(extractFromContent(source));
    expect(result.code).not.toMatch(/@css\.(attrs|create|rule|rule_on)\(/);
    expect(result.code).toContain([css.mapping["display:flex"], css.mapping["color:green"]].sort().join(" "));
    expect(result.code).not.toContain(css.mapping[":hover:color:blue"]);
    expect(result.css).toBe(css.css);
    expect(result.stats.folded).toBe(1);
  });

  test("static compilation precompiles definitions while leaving dynamic choices and variables", () => {
    const input = `fn style() -> @css.Style { ${base} }\nfn result(active : Bool, width : String) -> @css.StyleAttrs raise { @css.attrs([style().when(active).with_vars([("--width", width)])]) }`;
    const result = compileStyles(input);
    expect(result.code).toContain("@css.precompiled_style(");
    expect(result.code).not.toContain("@css.Hover");
    expect(result.code).toContain("style().when(active).with_vars");
    expect(result.code).toContain("@css.attrs(");
  });

  test("static stylesheet folding preserves canonical media order and raw-text escaping", () => {
    const input = '@css.stylesheet([@css.create([@css.rule_media("min-width:1024px", @css.Color, "red"), @css.rule_media("min-width:768px", @css.Color, "blue"), @css.rule_on(@css.Before, @css.Content, "\\\"</style>\\\"")])])';
    const result = compileStyles(input);
    expect(result.code).not.toContain("@css.");
    expect(result.css).toBe(generateCSS(extractFromContent(input)).css);
    expect(result.css).not.toContain("</style>");
  });

  test("static compilation rejects dynamic declarations and ignores unrelated calls and text", () => {
    expect(() => compileStyles('@css.rule(@css.Color, runtime_color)')).toThrow(/runtime_color/);
    expect(() => compileStyles('@css.rule_on(@css.NthChild(n), @css.Color, "red")')).toThrow(/NthChild/);
    const input = '// @css.rule(@css.Color, runtime_color)\nlet text = "@css.rule(x, y)"\nlet foreign = @other.create([@other.rule("x", value)])';
    expect(compileStyles(input).code).toBe(input);
  });

  test("directory compilation stages source without modifying the original and rejects unsafe output", () => {
    const dir = temp();
    const input = join(dir, "input");
    mkdirSync(input);
    writeFileSync(join(input, "demo.mbt"), source);
    writeFileSync(join(input, "moon.pkg"), 'import { "mizchi/luna/x/css" }\n');
    const out = join(dir, "optimized");
    compileStyleDirectory(input, { outputDir: out });
    expect(readFileSync(join(input, "demo.mbt"), "utf8")).toBe(source);
    expect(readFileSync(join(out, "demo.mbt"), "utf8")).not.toContain("@css.attrs(");
    expect(readFileSync(join(out, "luna.css"), "utf8")).toContain("color:green");
    const mtime = statSync(join(out, "demo.mbt")).mtimeMs;
    expect(compileStyleDirectory(input, { outputDir: out }).written).toBe(0);
    expect(statSync(join(out, "demo.mbt")).mtimeMs).toBe(mtime);
    expect(() => compileStyleDirectory(input, { outputDir: input })).toThrow();
    writeFileSync(join(input, "bad.mbt"), '@css.rule(@css.Color, runtime_color)');
    expect(() => compileStyleDirectory(input, { outputDir: join(dir, "invalid") })).toThrow();
    expect(existsSync(join(dir, "invalid"))).toBe(false);
    expect(() => compileStyleDirectory(input, { outputDir: out })).toThrow();
    expect(statSync(join(out, "demo.mbt")).mtimeMs).toBe(mtime);
    rmSync(join(input, "bad.mbt"));
    rmSync(join(input, "demo.mbt"));
    compileStyleDirectory(input, { outputDir: out });
    expect(existsSync(join(out, "demo.mbt"))).toBe(false);
    const link = join(dir, "redirect");
    symlinkSync(input, link);
    expect(() => compileStyleDirectory(input, { outputDir: join(link, "generated") })).toThrow();
  });

  test("directory CSS has global deterministic ordering and recognizes import aliases", () => {
    const dir = temp();
    const input = join(dir, "input");
    mkdirSync(input);
    writeFileSync(join(input, "moon.pkg"), 'import { "mizchi/luna/x/css" @style }\n');
    const a = '@style.rule_media("min-width:1024px", @style.Color, "red")';
    const b = '@style.rule_media("min-width:768px", @style.Color, "blue")';
    writeFileSync(join(input, "a.mbt"), a);
    writeFileSync(join(input, "b.mbt"), b);
    const out = join(dir, "output");
    compileStyleDirectory(input, { outputDir: out });
    expect(readFileSync(join(out, "luna.css"), "utf8")).toBe(generateCSS(extractFromContent(a + "\n" + b)).css);
    expect(readFileSync(join(out, "a.mbt"), "utf8")).toContain("@style.precompiled_rule");
  });

  test("MoonBit runtime and optimized builds agree and fully static output drops the CSS runtime", () => {
    const dir = temp();
    const input = join(dir, "input");
    mkdirSync(input);
    mkdirSync(join(input, "css"));
    mkdirSync(join(input, "app"));
    writeFileSync(join(input, "moon.mod"), 'name = "tests/style-modes"\n');
    for (const file of readdirSync(resolve("luna/src/x/css"))) {
      if (file === "moon.pkg" || (file.endsWith(".mbt") && !file.endsWith("_test.mbt"))) copyFileSync(resolve("luna/src/x/css", file), join(input, "css", file));
    }
    writeFileSync(join(input, "app/moon.pkg"), 'import { "tests/style-modes/css" }\noptions(link: { "js": { "exports": ["result"], "format": "esm" } })\n');
    const cases = [
      `@css.attrs([${base}, ${override}]).class_name`,
      `@css.attrs([${base}, @css.compose([${override}, @css.create([@css.unset(@css.Color)])])]).class_name`,
      '@css.attrs([@css.create([@css.rule_on(@css.Before, @css.Color, "blue"), @css.rule_on(@css.Hover, @css.Color, "red")]), @css.create([@css.unset(@css.Color)])]).class_name',
      '@css.attrs([@css.create([@css.rule_on(@css.Hover, @css.Color, "red"), @css.unset(@css.Color), @css.rule(@css.Color, "green"), @css.rule(@css.Color, "blue")])]).class_name',
      '@css.stylesheet([@css.create([@css.rule_on(@css.Before, @css.Content, "\\\"日本語😀</style>\\\"")])])',
    ];
    writeFileSync(join(input, "app/demo.mbt"), `pub fn result() -> String { ${cases.join(' + "|" + ')} }\n`);
    const outputs: {value: string; code: string}[] = [];
    for (const mode of ["runtime", "optimized"] as const) {
      const out = join(dir, mode);
      if (mode === "runtime") cpSync(input, out, { recursive: true });
      else compileStyleDirectory(input, { outputDir: out, cssPackage: "tests/style-modes/css" });
      execFileSync("moon", ["build", "--target", "js", "--release", "app"], { cwd: out, stdio: "pipe" });
      const code = readFileSync(join(out, "_build/js/release/build/app/app.js"), "utf8");
      const value = execFileSync(process.execPath, ["--input-type=module", "-e", `const m = await import(${JSON.stringify(`data:text/javascript;base64,${Buffer.from(code).toString("base64")}`)}); console.log(m.result());`], {encoding: "utf8"}).trim();
      outputs.push({ value, code });
    }
    expect(outputs[1].value).toBe(outputs[0].value);
    expect(outputs[1].code).not.toMatch(/djb2|hash_class_name|StyleRule|Property|css9Style/);
    expect(outputs[1].code.length).toBeLessThan(outputs[0].code.length);
  });
});
