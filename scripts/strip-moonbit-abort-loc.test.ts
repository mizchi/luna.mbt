import { describe, expect, test } from "vitest";
import { stripAbortLocFunctions } from "./strip-moonbit-abort-loc.mjs";

describe("strip-moonbit-abort-loc", () => {
  test("replaces builtin abort wrappers with direct panic", () => {
    const input = `
function _M0FP311moonbitlang4core7builtin5abortGRP46mizchi4luna2js12api__signals3AnyE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGRP46mizchi4luna2js12api__signals3AnyE(\`\${string}\\n  at \${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\\n\`);
}
function untouched() {
  return 1;
}
`;
    const out = stripAbortLocFunctions(input);
    expect(out.replaced).toBe(1);
    expect(out.output).toContain(
      "function _M0FP311moonbitlang4core7builtin5abortGRP46mizchi4luna2js12api__signals3AnyE(string, loc) {\n  return $panic();\n}"
    );
    expect(out.output).not.toContain(
      "_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE"
    );
    expect(out.output).toContain("function untouched() {\n  return 1;\n}");
  });

  test("is idempotent", () => {
    const input = `
function _M0FP311moonbitlang4core7builtin5abortGWEuE(string, loc) {
  return $panic();
}
`;
    const once = stripAbortLocFunctions(input);
    const twice = stripAbortLocFunctions(once.output);
    expect(once.output).toBe(twice.output);
  });

  test("replaces array remove slow abort path", () => {
    const input = `
function _M0MP311moonbitlang4core5array5Array6removeGWEuE(self, index) {
  if (index >= 0 && index < self.length) {
    $bound_check(self, index);
    const value = self[index];
    _M0MP311moonbitlang4core7builtin7JSArray6splice(self, index, 1);
    return value;
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGWEuE(\`index out of bounds: \${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(index)}\`, "@moonbitlang/core/builtin:arraycore_js.mbt");
  }
}
`;
    const out = stripAbortLocFunctions(input);
    expect(out.output).toContain("return $panic();");
    expect(out.output).not.toContain(
      "_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE"
    );
  });

  test("removes bound_check body and call sites", () => {
    const input = `
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function read(arr, i) {
  $bound_check(arr, i);
  return arr[i];
}
`;
    const out = stripAbortLocFunctions(input);
    expect(out.output).toContain("function $bound_check(arr, index) {}");
    expect(out.output).not.toContain("Index out of bounds");
    expect(out.output).toContain("function read(arr, i) {\n  return arr[i];\n}");
  });
});
