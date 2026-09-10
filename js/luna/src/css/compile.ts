/** Static preprocessing of the literal subset of Luna's composable CSS API. */
import fs from "node:fs";
import path from "node:path";
import {
  tokenize, readArguments, propertyName, pseudoSelector, themePairs,
  className, generateStyleCSS, type StyleToken, type ExtractedStyleCall,
} from "../../../../luna/src/x/css/style-extract.js";

export interface StyleCompileOptions {
  /** Import alias of mizchi/luna/x/css in this package. Defaults to css. */
  cssAlias?: string;
}
export interface StyleCompileResult {
  code: string;
  css: string;
  mapping: Record<string, string>;
  stats: { folded: number; precompiled: number };
  /** Literal declarations, including inactive variants, for canonical asset output. */
  rules: StyleDeclaration[];
}
export interface StyleDeclaration { property: string; value: string | null; pseudo: string; condition: string }
type Rule = StyleDeclaration;
interface StaticStyle { kind: "style"; rules: Rule[] }
type Evaluated = StaticStyle | { kind: "rule"; rule: Rule } | { kind: "attrs"; className: string } | { kind: "sheet"; css: string };
const declarations = new Set(["rule", "rule_on", "rule_media", "rule_when", "unset", "create_theme"]);
const functions = new Set([...declarations, "create", "compose", "attrs", "stylesheet"]);
const key = (rule: Rule) => (rule.condition ? `@media(${rule.condition}):` : "") + (rule.pseudo ? `${rule.pseudo}:` : "") + `${rule.property}:${rule.value}`;
const scope = (rule: Rule) => {
  const start = rule.pseudo.indexOf("::");
  if (start < 0) return "";
  const tail = rule.pseudo.slice(start + 2);
  const end = tail.indexOf(":");
  return "::" + (end < 0 ? tail : tail.slice(0, end));
};
const group = (rule: Rule) => JSON.stringify([scope(rule), rule.property]);
const literal = (tokens: StyleToken[]) => tokens.length === 1 ? tokens[0].value : undefined;

function normalize(rules: Rule[]): Rule[] {
  const slots = new Map<string, Rule>();
  for (const rule of rules) {
    if (rule.value === null) for (const [slot, existing] of slots) {
      if (group(existing) === group(rule)) slots.delete(slot);
    }
    slots.set(JSON.stringify([rule.property, rule.pseudo, rule.condition]), rule);
  }
  return [...slots.values()];
}
function compose(styles: StaticStyle[]): Rule[] {
  const groups = new Map<string, Rule[]>();
  for (const style of styles) {
    const incoming = new Map<string, Rule[]>();
    for (const rule of style.rules) {
      const id = group(rule);
      const rules = incoming.get(id) ?? [];
      rules.push(rule);
      incoming.set(id, rules);
    }
    for (const [id, rules] of incoming) groups.set(id, rules);
  }
  return [...groups.values()].flat();
}
function extracted(rules: Rule[]): ExtractedStyleCall {
  const result: ExtractedStyleCall = { base: new Set(), pseudo: [], media: [], warnings: [] };
  for (const rule of rules) {
    if (rule.value === null) continue;
    const declaration = { ...rule, value: rule.value };
    if (rule.condition) result.media.push(declaration);
    else if (rule.pseudo) result.pseudo.push(declaration);
    else result.base.add(`${rule.property}:${rule.value}`);
  }
  return result;
}
// Write a MoonBit string literal, including control characters and backslashes.
function quote(value: string): string {
  return '"' + [...value].map(ch => {
    if (ch === '"' || ch === "\\") return "\\" + ch;
    if (ch === "\n") return "\\n";
    if (ch === "\r") return "\\r";
    if (ch === "\t") return "\\t";
    return ch.charCodeAt(0) < 32 ? `\\u{${ch.charCodeAt(0).toString(16)}}` : ch;
  }).join("") + '"';
}
function arrayItems(tokens: StyleToken[]): StyleToken[][] | null {
  if (tokens[0]?.text !== "[" || tokens.at(-1)?.text !== "]") return null;
  // Reuse the balanced argument reader with a synthetic closing parenthesis.
  const inner = [...tokens.slice(1, -1), { ...tokens.at(-1)!, text: ")" }];
  const result = readArguments(inner, 0);
  return result && result.end === inner.length - 1 ? result.args : null;
}

/**
 * Compile qualified literal CSS calls without evaluating arbitrary MoonBit.
 * Dynamic composition/when/with_vars remain ordinary MoonBit expressions.
 * Dynamic declarations fail explicitly: use literal var(--name) + with_vars.
 */
export function compileStyles(source: string, options: StyleCompileOptions = {}): StyleCompileResult {
  const alias = options.cssAlias ?? "css";
  if (!/^[a-zA-Z_]\w*$/.test(alias)) throw new Error("Invalid CSS package alias");
  const tokens = tokenize(source);
  const collected: Rule[] = [];
  const stats = { folded: 0, precompiled: 0 };
  const callAt = (input: StyleToken[], start: number) => {
    if (input[start]?.text !== "@" || input[start + 1]?.text !== alias || input[start + 2]?.text !== "." || input[start + 4]?.text !== "(") return null;
    const name = input[start + 3].text;
    if (!functions.has(name)) return null;
    const call = readArguments(input, start + 5);
    return call ? { name, ...call } : null;
  };
  const error = (input: StyleToken[]) => new Error(`CSS declaration must be static: ${source.slice(input[0].start, input.at(-1)!.end)}. Use var(--name) and with_vars for dynamic values.`);
  const evaluate = (input: StyleToken[]): Evaluated | null => {
    const call = callAt(input, 0);
    if (!call || call.end !== input.length - 1) return null;
    const { name, args } = call;
    if (name === "create_theme") {
      const pairs = args.length === 1 ? themePairs(args[0]) : null;
      if (!pairs) throw error(input);
      const rules = pairs.map(([property, value]) => ({ property, value, pseudo: "", condition: "" }));
      collected.push(...rules);
      return { kind: "style", rules: normalize(rules) };
    }
    if (declarations.has(name)) {
      const count = name === "unset" ? 1 : name === "rule" ? 2 : name === "rule_when" ? 4 : 3;
      const propIndex = name === "unset" ? 0 : count - 2;
      const property = args[propIndex] && propertyName(args[propIndex]);
      const value = name === "unset" ? null : args[count - 1] && literal(args[count - 1]);
      const pseudoIndex = name === "rule_on" ? 0 : name === "rule_when" ? 1 : -1;
      const pseudo = pseudoIndex < 0 ? "" : args[pseudoIndex] && pseudoSelector(args[pseudoIndex]);
      const condition = name === "rule_media" || name === "rule_when" ? args[0] && literal(args[0]) : "";
      // A constructor from another package may implement a different trait.
      const foreign = [args[propIndex], pseudoIndex < 0 ? [] : args[pseudoIndex]].some(arg => arg?.some((t, i) => t.text === "@" && arg[i + 1]?.text !== alias));
      if (args.length !== count || property === undefined || value === undefined || pseudo === undefined || condition === undefined || foreign) throw error(input);
      const rule = { property, value, pseudo, condition };
      collected.push(rule);
      return { kind: "rule", rule };
    }
    const items = args.length === 1 ? arrayItems(args[0]) : null;
    if (!items) return null;
    const values = items.map(evaluate);
    if (name === "create") {
      if (values.some(v => v?.kind !== "rule")) return null;
      return { kind: "style", rules: normalize(values.map(v => (v as {kind: "rule"; rule: Rule}).rule)) };
    }
    if (values.some(v => v?.kind !== "style")) return null;
    const styles = values as StaticStyle[];
    if (name === "stylesheet") return { kind: "sheet", css: generateStyleCSS(extracted(styles.flatMap(s => s.rules))).css };
    const rules = compose(styles);
    if (name === "compose") return { kind: "style", rules };
    return { kind: "attrs", className: [...new Set(rules.filter(r => r.value !== null).map(r => className(key(r))))].sort().join(" ") };
  };
  const emitRule = (r: Rule) => `@${alias}.precompiled_rule(${quote(r.property)}, ${r.value === null ? "None" : `Some(${quote(r.value)})`}, ${quote(r.pseudo)}, ${quote(r.condition)}, ${quote(r.value === null ? "" : className(key(r)))})`;
  const emit = (value: Evaluated) => {
    switch (value.kind) {
      case "rule": return emitRule(value.rule);
      case "style": return `@${alias}.precompiled_style([${value.rules.map(emitRule).join(", ")}])`;
      case "sheet": return quote(value.css);
      case "attrs": return `({ class_name: ${quote(value.className)}, style: "" } : @${alias}.StyleAttrs)`;
    }
  };
  const edits: { start: number; end: number; value: string }[] = [];
  for (let i = 0; i < tokens.length; i++) {
    const call = callAt(tokens, i);
    if (!call) continue;
    const value = evaluate(tokens.slice(i, call.end + 1));
    if (!value) continue; // Descend on following iterations to compile literal children.
    edits.push({ start: tokens[i].start, end: tokens[call.end].end, value: emit(value) });
    if (value.kind === "attrs" || value.kind === "sheet") stats.folded++;
    else stats.precompiled++;
    i = call.end;
  }
  let code = source;
  for (const edit of edits.reverse()) code = code.slice(0, edit.start) + edit.value + code.slice(edit.end);
  return { code, ...generateStyleCSS(extracted(collected)), stats, rules: collected };
}

export interface StyleDirectoryOptions {
  outputDir: string;
  /** CSS package path used to resolve aliases from moon.pkg. */
  cssPackage?: string;
}
export interface StyleDirectoryResult {
  outputDir: string;
  files: number;
  stats: StyleCompileResult["stats"];
  elapsedMs: number;
  written: number;
}

export const styleCompileIgnoredDirectories = [".git", ".mooncakes", "node_modules", "_build", "target", "dist"] as const;

/** Stage a complete source directory. Input is never overwritten. */
export function compileStyleDirectory(inputDir: string, options: StyleDirectoryOptions): StyleDirectoryResult {
  const start = performance.now();
  const input = fs.realpathSync(inputDir);
  // Resolve existing ancestors too, so a symlink cannot hide an output inside input.
  const canonical = (file: string): string => fs.existsSync(file) ? fs.realpathSync(file) : path.join(canonical(path.dirname(file)), path.basename(file));
  const output = canonical(path.resolve(options.outputDir));
  const relative = path.relative(input, output);
  if (!relative || (!relative.startsWith(".." + path.sep) && relative !== ".." && !path.isAbsolute(relative))) throw new Error("Output directory must be outside the input directory");
  const marker = ".luna-css-build.json";
  let previous: string[] = [];
  if (fs.existsSync(output)) {
    const markerFile = path.join(output, marker);
    if (!fs.existsSync(markerFile) || fs.lstatSync(markerFile).isSymbolicLink()) throw new Error("Output directory is not managed by the CSS compiler");
    const manifest = JSON.parse(fs.readFileSync(markerFile, "utf8"));
    if (manifest.source !== input || manifest.version !== 1 || !Array.isArray(manifest.files) || manifest.files.some((file: unknown) => typeof file !== "string" || path.isAbsolute(file) || file.split(/[\\/]/).some(part => part === ".." || part === "." || part === ""))) throw new Error("Invalid CSS build manifest");
    previous = manifest.files;
  }
  const packageName = options.cssPackage ?? "mizchi/luna/x/css";
  const previousFiles = new Set(previous);
  const pending: { relative: string; content: Buffer | string; mode?: number }[] = [];
  const stats = { folded: 0, precompiled: 0 };
  let files = 0;
  const skipped = new Set<string>(styleCompileIgnoredDirectories);
  const walk = (dir: string) => {
    let alias: string | undefined;
    const manifest = path.join(dir, "moon.pkg");
    if (fs.existsSync(manifest)) {
      const ts = tokenize(fs.readFileSync(manifest, "utf8"));
      for (let i = 0; i < ts.length; i++) if (ts[i].value === packageName) {
        alias = ts[i + 1]?.text === "@" ? ts[i + 2]?.text : packageName.split("/").at(-1);
      }
    } else if (fs.existsSync(path.join(dir, "moon.pkg.json"))) {
      const pkg = JSON.parse(fs.readFileSync(path.join(dir, "moon.pkg.json"), "utf8"));
      for (const imp of pkg.import ?? []) {
        if ((typeof imp === "string" ? imp : imp.path) === packageName) alias = typeof imp === "string" ? packageName.split("/").at(-1) : imp.alias ?? packageName.split("/").at(-1);
      }
    }
    for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      if (skipped.has(entry.name)) continue;
      const file = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`Cannot stage symbolic link: ${file}`);
      if (entry.isDirectory()) { walk(file); continue; }
      if (!entry.isFile()) continue;
      let content: Buffer | string = fs.readFileSync(file);
      if (entry.name.endsWith(".mbt") && !entry.name.endsWith("_test.mbt") && alias) {
        let result: StyleCompileResult;
        try {
          result = compileStyles(content.toString("utf8"), { cssAlias: alias });
        } catch (cause) {
          throw new Error(`${file}: ${cause instanceof Error ? cause.message : String(cause)}`, { cause });
        }
        content = result.code;
        compiledSheets.push(result);
        stats.folded += result.stats.folded;
        stats.precompiled += result.stats.precompiled;
        files++;
      }
      pending.push({ relative: path.relative(input, file), content, mode: fs.statSync(file).mode });
    }
  };
  const compiledSheets: StyleCompileResult[] = [];
  walk(input);
  const css = generateStyleCSS(extracted(compiledSheets.flatMap(result => result.rules))).css;
  if (pending.some(file => file.relative === "luna.css" || file.relative === marker)) throw new Error("Input contains generated CSS build artifacts; compile the original source directory");
  pending.push({ relative: "luna.css", content: css });
  const next = pending.map(file => file.relative);
  const nextFiles = new Set(next);
  // Validate all destinations before mutating the previous successful output.
  for (const relative of new Set([...previous, ...next, marker])) {
    const dest = path.join(output, relative);
    for (let current = dest; current !== output; current = path.dirname(current)) {
      if (fs.existsSync(current) && fs.lstatSync(current).isSymbolicLink()) throw new Error(`Output contains a symbolic link: ${current}`);
    }
    if (relative !== marker && !previousFiles.has(relative) && fs.existsSync(dest)) throw new Error(`Output contains an unmanaged file: ${dest}`);
  }
  pending.push({ relative: marker, content: JSON.stringify({ version: 1, source: input, files: next }, null, 2) + "\n" });
  let written = 0;
  for (const file of pending) {
    const dest = path.join(output, file.relative);
    const bytes = Buffer.isBuffer(file.content) ? file.content : Buffer.from(file.content);
    if (fs.existsSync(dest) && fs.readFileSync(dest).equals(bytes)) continue;
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.writeFileSync(dest, bytes);
    if (file.mode !== undefined) fs.chmodSync(dest, file.mode);
    written++;
  }
  for (const relative of previous) if (!nextFiles.has(relative)) fs.rmSync(path.join(output, relative), { force: true });
  return { outputDir: output, files, stats, written, elapsedMs: performance.now() - start };
}
