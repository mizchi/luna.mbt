import test from "node:test";
import assert from "node:assert/strict";
import { build } from "esbuild";
import { runInNewContext } from "node:vm";
import { postProcessMoonbitJs } from "../../luna/scripts/strip-moonbit-abort-loc.mjs";

const source = `function _M0DTPExampleUnused(param0) {
  this._0 = param0;
}
_M0DTPExampleUnused.prototype.$tag = 7;
function _M0DTPExampleUsed(param0) {
  this._0 = param0;
}
_M0DTPExampleUsed.prototype.$tag = 3;
function _M0DTPExampleNone() {
}
_M0DTPExampleNone.prototype.$tag = 0;
let unusedNone = new _M0DTPExampleNone();
function _M0TPExampleRecord(param0) {
  this.val = param0;
}
let unusedRecord = new _M0TPExampleRecord(42);
export function make(value) { return new _M0DTPExampleUsed(value); }
`;

async function bundle(input, format = "esm") {
  const result = await build({
    stdin: { contents: input, sourcefile: "generated-moonbit.js" },
    bundle: true,
    write: false,
    format,
    treeShaking: true,
    minifySyntax: true,
  });
  return result.outputFiles[0].text;
}

test("unused MoonBit enum tags and record allocations can be tree-shaken", async () => {
  const { output } = postProcessMoonbitJs(source);
  const code = await bundle(output);
  assert.doesNotMatch(code, /ExampleUnused|ExampleNone|ExampleRecord/);
  assert.match(code, /ExampleUsed/);
});

test("used constructors keep a shared prototype, enum tag, and payload", async () => {
  const { output } = postProcessMoonbitJs(source);
  const code = await bundle(output);
  const { make } = await import(
    `data:text/javascript;base64,${Buffer.from(code).toString("base64")}`
  );
  const payload = {};
  const first = make(payload);
  const second = make(1);
  assert.equal(first.$tag, 3);
  assert.equal(first._0, payload);
  assert.equal(first.constructor, second.constructor);
  assert.ok(first instanceof second.constructor);
  assert.equal(Object.getPrototypeOf(first), first.constructor.prototype);
});

test("constructor cleanup preserves argument effects and ignores effectful constructors", async () => {
  const input =
    source +
    `
const ignoredArgument = new _M0TPExampleRecord(console.log('argument effect'));
function _M0DTPExampleEffectful(param0) {
  console.log('constructor effect');
  this._0 = param0;
}
_M0DTPExampleEffectful.prototype.$tag = 9;
new _M0DTPExampleEffectful(1);
new TextDecoder();
`;
  const code = await bundle(postProcessMoonbitJs(input).output, "cjs");
  assert.match(code, /argument effect/);
  assert.match(code, /constructor effect/);
  assert.match(code, /new TextDecoder/);
  const effects = [];
  runInNewContext(code, {
    module: { exports: {} },
    console: { log: (message) => effects.push(message) },
    TextDecoder: class {
      constructor() {
        effects.push("TextDecoder");
      }
    },
  });
  assert.deepEqual(effects, ["argument effect", "constructor effect", "TextDecoder"]);
});

test("constructor annotations are idempotent", () => {
  const once = postProcessMoonbitJs(source);
  const twice = postProcessMoonbitJs(once.output);
  assert.equal(twice.output, once.output);
  assert.equal(twice.replaced, 0);
});

test("FFI strings containing generated-looking code remain unchanged", () => {
  const input = `const ffiSource = ${JSON.stringify(source)};\nexport { ffiSource };`;
  assert.equal(postProcessMoonbitJs(input).output, input);
});

test("forward references retain constructor hoisting", async () => {
  const input = `export const instance = new _M0DTPExampleForward(42);
function _M0DTPExampleForward(param0) {
  this._0 = param0;
}
_M0DTPExampleForward.prototype.$tag = 2;
`;
  const { output } = postProcessMoonbitJs(input);
  assert.equal(output, input);
  const { instance } = await import(
    `data:text/javascript;base64,${Buffer.from(await bundle(output)).toString("base64")}`
  );
  assert.equal(instance._0, 42);
  assert.equal(instance.$tag, 2);
});

test("reassigned constructor bindings retain allocation effects", async () => {
  const input = `function _M0TPExampleMutable(param0) {
  this.val = param0;
}
_M0TPExampleMutable = function() { console.log('replacement constructor'); };
const unused = new _M0TPExampleMutable(42);
`;
  const { output } = postProcessMoonbitJs(input);
  assert.equal(output, input);
  const effects = [];
  runInNewContext(await bundle(output, "cjs"), {
    console: { log: (message) => effects.push(message) },
  });
  assert.deepEqual(effects, ["replacement constructor"]);
});
