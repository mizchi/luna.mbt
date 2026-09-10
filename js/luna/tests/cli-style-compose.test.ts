import { afterEach, describe, expect, test } from "vitest";
import { copyFileSync, mkdtempSync, mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve, join } from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import { extract, extractFromContent, generateCSS, extractSplit, detectWarnings } from "../src/css/extract.js";

const dirs: string[] = [];
function fixture() {
  const dir = mkdtempSync(join(tmpdir(), "luna-style-extract-"));
  dirs.push(dir);
  return dir;
}
afterEach(() => { for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true }); });

const source = `
let base = @css.create([
  @css.rule("display", "flex"),
  @css.rule("width", "var(--width)"),
  @css.rule_on(":hover", "color", "blue"),
  @css.rule_media("min-width:768px", "padding", "2rem"),
  @css.rule_when("min-width:768px", ":hover", "color", "purple"),
])
let theme = @css.create_theme([("--surface", "white"), ("--text", "black")])
`;

describe("composable styles extraction", () => {
  test("typed pseudo selectors extract with literal functional arguments", () => {
    const typed = `
      @css.rule_on(@css.Hover, @css.Color, "blue")
      @css.rule_on(@css.Pseudo::FocusVisible, @css.Outline, "2px solid blue")
      @css.rule_on(Pseudo::Disabled, @css.Opacity, "0.5")
      @css.rule_on(@css.NthChild("2n"), @css.Color, "red")
      @css.rule_on(@css.Pseudo::Not(":disabled"), @css.Cursor, "pointer")
      @css.rule_on(@css.Before, @css.Content, "''")
      @css.rule_on(@css.Part("label"), @css.Color, "purple")
      @css.rule_when("min-width:768px", @css.Hover, @css.Color, "green")
    `;
    const strings = typed
      .replaceAll("@css.Hover", '":hover"')
      .replaceAll("@css.Pseudo::FocusVisible", '":focus-visible"')
      .replaceAll("Pseudo::Disabled", '":disabled"')
      .replaceAll('@css.NthChild("2n")', '":nth-child(2n)"')
      .replaceAll('@css.Pseudo::Not(":disabled")', '":not(:disabled)"')
      .replaceAll("@css.Before", '"::before"')
      .replaceAll('@css.Part("label")', '"::part(label)"');
    expect(generateCSS(extractFromContent(typed))).toEqual(generateCSS(extractFromContent(strings)));
    expect(detectWarnings(typed, "typed.mbt")).toEqual([]);
    const dir = fixture();
    writeFileSync(join(dir, "styles.mbt"), typed);
    const standalone = JSON.parse(execFileSync(process.execPath, [resolve("luna/src/x/css/extract.js"), dir, "--json", "--strict"], { encoding: "utf8" }));
    expect(standalone.css).toBe(extract(dir, { strict: true }).css);
  });

  test("unknown and dynamic pseudo selectors produce strict diagnostics", () => {
    for (const pseudo of ["@css.Hovre", "@css.NthChild", "@css.Hover(\"x\")", "@css.NthChild(n)", "@css.Not(\":hover\", \":focus\")", "Other::Hover"]) {
      const input = `@css.rule_on(${pseudo}, @css.Color, "red")`;
      expect(detectWarnings(input, "typed.mbt"), pseudo).toHaveLength(1);
      expect(generateCSS(extractFromContent(input)).css).toBe("");
    }
  });

  test("MoonBit checks public property and pseudo constructors and their arguments", () => {
    const dir = fixture();
    // Isolate the CSS package from unrelated workspace dependencies.
    mkdirSync(join(dir, "css"));
    mkdirSync(join(dir, "consumer"));
    writeFileSync(join(dir, "moon.mod"), 'name = "tests/css-property"\n');
    for (const file of readdirSync(resolve("luna/src/x/css"))) {
      if (file === "moon.pkg" || (file.endsWith(".mbt") && !file.endsWith("_test.mbt"))) {
        copyFileSync(resolve("luna/src/x/css", file), join(dir, "css", file));
      }
    }
    writeFileSync(join(dir, "consumer/moon.pkg"), 'import { "tests/css-property/css" }\n');
    const file = join(dir, "consumer/check.mbt");
    const check = () => spawnSync("moon", ["check", "--target", "js"], { cwd: dir, encoding: "utf8" });
    writeFileSync(file, 'pub fn example() -> @css.Style { @css.create([@css.rule(@css.Color, "red"), @css.rule(@css.Property::Display, "flex"), @css.rule_on(@css.Hover, @css.Color, "blue"), @css.rule_on(@css.Pseudo::NthChild("2n"), @css.Opacity, "0.5"), @css.rule_on(@css.Before, @css.Content, "none")]) }\n');
    const good = check();
    expect(good.status, good.stdout + good.stderr).toBe(0);
    writeFileSync(file, 'pub fn example() -> @css.StyleRule { @css.rule(@css.Colro, "red") }\n');
    const bad = check();
    expect(bad.status).not.toBe(0);
    expect(bad.stdout + bad.stderr).toMatch(/Colro/);
    expect(bad.stdout + bad.stderr).toMatch(/Error:/);
    for (const pseudo of ["@css.Hovre", "@css.NthChild(2)"]) {
      writeFileSync(file, `pub fn example() -> @css.StyleRule { @css.rule_on(${pseudo}, @css.Color, "red") }\n`);
      const invalid = check();
      expect(invalid.status, pseudo).not.toBe(0);
      expect(invalid.stdout + invalid.stderr).toMatch(/Error:/);
    }
  });

  test("typed property constructors extract identically to strings", () => {
    const typed = `
      @css.rule(@css.Display, "flex")
      @css.rule(Property::Width, "var(--width)")
      @css.rule_on(":hover", @css.Property::Color, "blue")
      @css.rule_media("min-width:768px", Padding, "2rem")
      @css.rule_when("min-width:768px", ":hover", Color, "purple")
      @css.create_theme([("--surface", "white"), ("--text", "black")])
    `;
    expect(generateCSS(extractFromContent(typed))).toEqual(generateCSS(extractFromContent(source)));
    expect(detectWarnings(typed, "typed.mbt")).toEqual([]);
    const dir = fixture();
    writeFileSync(join(dir, "styles.mbt"), typed);
    const standalone = JSON.parse(execFileSync(process.execPath, [resolve("luna/src/x/css/extract.js"), dir, "--json", "--strict"], { encoding: "utf8" }));
    expect(standalone.css).toBe(extract(dir, { strict: true }).css);
  });

  test("unknown or computed typed properties produce strict diagnostics", () => {
    for (const prop of ["@css.Colro", "Property::Colro", "some_property", "get_property()", "Other::Color"]) {
      const input = `@css.rule(${prop}, "red")`;
      expect(detectWarnings(input, "typed.mbt")).toHaveLength(1);
      expect(generateCSS(extractFromContent(input)).css).toBe("");
    }
    // Constructors are recognized only in the property argument.
    expect(detectWarnings('@css.rule(@css.Color, @css.Display)', "typed.mbt")).toHaveLength(1);
  });

  test("extracts declarations, combined conditions and theme defaults", () => {
    const result = generateCSS(extractFromContent(source));
    expect(result.css).toContain("display:flex");
    expect(result.css).toContain("width:var(--width)");
    expect(result.css).toContain(":hover{color:blue}");
    expect(result.css).toContain(":hover{color:purple}");
    expect(result.css).toContain("--surface:white");
    expect(result.mapping["@media(min-width:768px):padding:2rem"]).toBe("_m2bz");
    expect(result.mapping["@media(min-width:768px)::hover:color:purple"]).toBeTruthy();
  });

  test("does not extract examples in comments or strings and decodes escapes", () => {
    const input = String.raw`
// @css.rule("color", "red")
/* nested /* @css.rule("color", "green") */ comment */
let text = "@css.rule(\"color\", \"purple\")"
let raw =
  #| @css.rule("color", "orange")
let content = @css.rule_on("::before", "content", "\"hello\"")
`;
    const result = generateCSS(extractFromContent(input));
    expect(result.css).toContain('::before{content:"hello"}');
    expect(result.css).not.toContain("color:");
    expect(detectWarnings(input, "test.mbt")).toEqual([]);
  });

  test("strict extraction rejects nonliteral rules without requiring verbose output", () => {
    const dir = fixture();
    writeFileSync(join(dir, "styles.mbt"), 'let s = @css.create([@css.rule("width", dynamic_width)])');
    expect(() => extract(dir, { strict: true })).toThrow(/Strict mode/);
    expect(() => extract(dir, { strict: true, warn: false })).toThrow(/Strict mode/);
    expect(detectWarnings('let theme = @css.create_theme(tokens)', "test.mbt")).toHaveLength(1);
  });

  test("shared split extraction preserves pseudo selectors and values with colons", () => {
    const dir = fixture();
    for (const name of ["a", "b", "c"]) {
      mkdirSync(join(dir, name));
      writeFileSync(join(dir, name, "styles.mbt"), source + '\nlet s = @css.rule_on("::before", "content", "\'a:b\'")');
    }
    const split = extractSplit(dir, "dir");
    expect(split.shared.css).toContain("::before{content:'a:b'}");
    expect(split.shared.css).toContain(":hover{color:purple}");
    expect(split.shared.css).toContain("--surface:white");
    for (const chunk of split.chunks.values()) expect(chunk.css).toBe("");
    expect(split.combined).toBe(generateCSS(extractFromContent(source + '\nlet s = @css.rule_on("::before", "content", "\'a:b\'")')).css);
  });

  test("the standalone Mooncake extractor and npm extractor agree", () => {
    const dir = fixture();
    writeFileSync(join(dir, "styles.mbt"), source);
    const legacy = JSON.parse(execFileSync(process.execPath, [resolve("luna/src/x/css/extract.js"), dir, "--json"], { encoding: "utf8" }));
    expect(legacy.css).toBe(extract(dir).css);
    expect(legacy.mapping).toEqual(extract(dir).mapping);
    writeFileSync(join(dir, "styles.mbt"), '@css.rule("width", dynamic_width)');
    expect(() => execFileSync(process.execPath, [resolve("luna/src/x/css/extract.js"), dir, "--strict"], { stdio: "pipe" })).toThrow();
    expect(() => execFileSync(process.execPath, [resolve("luna/src/x/css/extract.js"), dir, "--split", "--strict", "--no-warn"], { stdio: "pipe" })).toThrow();
  });
});
