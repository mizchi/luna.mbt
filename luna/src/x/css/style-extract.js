// Shared by the standalone Mooncake extractor and the bundled npm extractor.
// This scanner deliberately accepts literal rule calls, not arbitrary MoonBit
// evaluation. Unsupported calls produce diagnostics rather than missing CSS.
import { propertyNames } from "./property-names.js";
import { pseudoNames } from "./pseudo-names.js";

const names = new Set(["rule", "rule_on", "rule_media", "rule_when", "create_theme"]);

export function tokenize(source) {
  const tokens = [];
  let i = 0;
  while (i < source.length) {
    if (/\s/.test(source[i])) { i++; continue; }
    // MoonBit multiline string lines contain text, not executable calls.
    if (source.startsWith("#|", i) || source.startsWith("$|", i)) {
      const end = source.indexOf("\n", i);
      i = end < 0 ? source.length : end;
      continue;
    }
    if (source.startsWith("//", i)) {
      const end = source.indexOf("\n", i);
      i = end < 0 ? source.length : end;
      continue;
    }
    if (source.startsWith("/*", i)) {
      let depth = 1;
      i += 2;
      while (i < source.length && depth > 0) {
        if (source.startsWith("/*", i)) { depth++; i += 2; }
        else if (source.startsWith("*/", i)) { depth--; i += 2; }
        else i++;
      }
      continue;
    }
    const start = i;
    if (source[i] === '"' || source[i] === "'") {
      const quote = source[i++];
      while (i < source.length) {
        if (source[i] === "\\") { i += 2; continue; }
        if (source[i++] === quote) break;
      }
      const text = source.slice(start, i);
      let value;
      if (quote === '"') {
        try { value = JSON.parse(text); } catch { /* unsupported literal */ }
      }
      tokens.push({ text, value, start, end: i });
    } else if (/[a-zA-Z_]/.test(source[i])) {
      while (i < source.length && /[a-zA-Z0-9_]/.test(source[i])) i++;
      tokens.push({ text: source.slice(start, i), start, end: i });
    } else {
      tokens.push({ text: source[i++], start, end: i });
    }
  }
  return tokens;
}

export function readArguments(tokens, start) {
  const args = [];
  let arg = [];
  let depth = 0;
  for (let i = start; i < tokens.length; i++) {
    const token = tokens[i];
    if (token.text === ")" && depth === 0) {
      if (arg.length) args.push(arg);
      return { args, end: i };
    }
    if (token.text === "," && depth === 0) {
      args.push(arg);
      arg = [];
    } else {
      if (["(", "[", "{"].includes(token.text)) depth++;
      if ([")", "]", "}"].includes(token.text)) depth--;
      arg.push(token);
    }
  }
  return null;
}

export function themePairs(tokens) {
  if (tokens?.[0]?.text !== "[" || tokens.at(-1)?.text !== "]") return null;
  const pairs = [];
  let i = 1;
  while (i < tokens.length - 1) {
    if (tokens[i]?.text !== "(" || typeof tokens[i + 1]?.value !== "string" ||
        tokens[i + 2]?.text !== "," || typeof tokens[i + 3]?.value !== "string" ||
        tokens[i + 4]?.text !== ")") return null;
    if (!/^--[a-zA-Z0-9_-]+$/.test(tokens[i + 1].value)) return null;
    pairs.push([tokens[i + 1].value, tokens[i + 3].value]);
    i += 5;
    if (i < tokens.length - 1 && tokens[i++]?.text !== ",") return null;
  }
  return pairs;
}

export function propertyName(tokens) {
  if (tokens.length === 1 && typeof tokens[0].value === "string") return tokens[0].value;
  // Bare, Property::Color, @alias.Color, and @alias.Property::Color.
  const name = tokens.map(token => token.text).join("");
  const match = name.match(/^(?:@[a-zA-Z_]\w*\.)?(?:Property::)?([A-Z]\w*)$/);
  return match && Object.hasOwn(propertyNames, match[1]) ? propertyNames[match[1]] : undefined;
}

export function pseudoSelector(tokens) {
  if (tokens.length === 1 && typeof tokens[0].value === "string") return tokens[0].value;
  const paren = tokens.findIndex(token => token.text === "(");
  const constructor = (paren < 0 ? tokens : tokens.slice(0, paren)).map(token => token.text).join("");
  const match = constructor.match(/^(?:@[a-zA-Z_]\w*\.)?(?:Pseudo::)?([A-Z]\w*)$/);
  if (!match || !Object.hasOwn(pseudoNames, match[1])) return undefined;
  const { selector, functional } = pseudoNames[match[1]];
  if (!functional) return paren < 0 ? selector : undefined;
  if (paren < 0) return undefined;
  const call = readArguments(tokens, paren + 1);
  if (!call || call.end !== tokens.length - 1 || call.args.length !== 1 ||
      call.args[0].length !== 1 || typeof call.args[0][0].value !== "string") return undefined;
  return `${selector}(${call.args[0][0].value})`;
}

export function extractStyleCalls(source) {
  const result = { base: new Set(), pseudo: [], media: [], warnings: [] };
  const tokens = tokenize(source);
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (!names.has(token.text) || tokens[i + 1]?.text !== "(" || tokens[i - 1]?.text === "fn") continue;
    const call = readArguments(tokens, i + 2);
    if (!call) continue; // Invalid MoonBit is diagnosed by the compiler.
    const { args, end } = call;
    const values = args.map(arg => arg.length === 1 ? arg[0].value : undefined);
    let valid = false;
    if (token.text === "create_theme") {
      const pairs = args.length === 1 ? themePairs(args[0]) : null;
      if (pairs) {
        for (const [name, value] of pairs) result.base.add(`${name}:${value}`);
        valid = true;
      }
    } else {
      const count = token.text === "rule" ? 2 : token.text === "rule_when" ? 4 : 3;
      const propertyIndex = count - 2;
      if (args[propertyIndex]) values[propertyIndex] = propertyName(args[propertyIndex]);
      const pseudoIndex = token.text === "rule_on" ? 0 : token.text === "rule_when" ? 1 : -1;
      if (pseudoIndex >= 0 && args[pseudoIndex]) values[pseudoIndex] = pseudoSelector(args[pseudoIndex]);
      if (values.length === count && values.every(value => typeof value === "string")) {
        if (token.text === "rule") result.base.add(`${values[0]}:${values[1]}`);
        if (token.text === "rule_on") result.pseudo.push({ pseudo: values[0], property: values[1], value: values[2] });
        if (token.text === "rule_media") result.media.push({ condition: values[0], property: values[1], value: values[2] });
        if (token.text === "rule_when") result.media.push({ condition: values[0], pseudo: values[1], property: values[2], value: values[3] });
        valid = true;
      }
    }
    if (!valid) result.warnings.push({
      func: token.text,
      position: token.start,
      code: source.slice(token.start, tokens[end].end),
      reason: "Expected literal style declarations; use var(--name) and with_vars for runtime values",
    });
    i = end;
  }
  return result;
}

export function mediaKey({ condition, pseudo = "", property, value }) {
  return `@media(${condition}):${pseudo ? `${pseudo}:` : ""}${property}:${value}`;
}

const pseudoOrder = ["", ":link", ":visited", ":focus-within", ":hover", ":focus", ":focus-visible", ":active", ":disabled"];
const compare = (a, b) => a < b ? -1 : a > b ? 1 : 0;
const rank = pseudo => { const index = pseudoOrder.indexOf(pseudo); return index < 0 ? 9 : index; };

export function compareConditions(a, b) {
  if (a === b) return 0;
  if (a === "") return -1;
  if (b === "") return 1;
  const pattern = /^(min|max)-(width|height):\s*([0-9]+(?:\.[0-9]*)?|\.[0-9]+)(px|em|rem)\s*$/;
  const left = a.match(pattern);
  const right = b.match(pattern);
  if (left && right) {
    const feature = compare(left[1] + "-" + left[2], right[1] + "-" + right[2]);
    if (feature) return feature;
    const unit = compare(left[4], right[4]);
    if (unit) return unit;
    const delta = Number(left[3]) - Number(right[3]);
    if (delta !== 0) return left[1] === "min" ? delta : -delta;
  }
  if (left && !right) return -1;
  if (!left && right) return 1;
  return compare(a, b);
}

export function className(key) {
  let hash = 5381;
  for (let i = 0; i < key.length; i++) hash = ((hash << 5) + hash + key.charCodeAt(i)) >>> 0;
  return "_" + (hash & 0xffffff).toString(36);
}

export function generateStyleCSS(styles, { pretty = false } = {}) {
  const rules = [];
  for (const declaration of styles.base) {
    const colon = declaration.indexOf(":");
    rules.push({ property: declaration.slice(0, colon), value: declaration.slice(colon + 1), pseudo: "", condition: "" });
  }
  for (const rule of styles.pseudo) rules.push({ ...rule, condition: "" });
  for (const rule of styles.media) rules.push({ pseudo: "", ...rule });
  rules.sort((a, b) => compareConditions(a.condition, b.condition) || rank(a.pseudo) - rank(b.pseudo) ||
    compare(a.pseudo, b.pseudo) || compare(a.property, b.property) || compare(a.value, b.value));
  const mapping = Object.create(null);
  const parts = [];
  for (const rule of rules) {
    const { condition, pseudo, property, value } = rule;
    const declaration = `${pseudo ? `${pseudo}:` : ""}${property}:${value}`;
    const key = condition ? mediaKey(rule) : declaration;
    if (Object.hasOwn(mapping, key)) continue;
    const cls = className(key);
    mapping[key] = cls;
    const safeValue = value.replaceAll("<", "\\3c ");
    const css = pretty ? `.${cls}${pseudo} { ${property}: ${safeValue} }` : `.${cls}${pseudo}{${property}:${safeValue}}`;
    parts.push(condition ? (pretty ? `@media (${condition}) {\n  ${css}\n}` : `@media(${condition}){${css}}`) : css);
  }
  return { css: parts.join(pretty ? "\n" : ""), mapping };
}
