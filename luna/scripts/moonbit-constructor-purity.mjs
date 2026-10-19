import { parseSync, Visitor } from "rolldown/utils";

const CONSTRUCTOR_NAME = /^_M\d+(?:D)?TP\w+$/;

// Only compiler-owned constructors that copy arguments into fresh instance fields.
function isDataConstructor(node) {
  if (
    node.type !== "FunctionDeclaration" ||
    node.async ||
    node.generator ||
    !CONSTRUCTOR_NAME.test(node.id?.name)
  )
    return false;
  if (!node.params.every((param) => param.type === "Identifier")) return false;
  const params = new Set(node.params.map((param) => param.name));
  return node.body.body.every((statement) => {
    if (statement.type !== "ExpressionStatement") return false;
    const assignment = statement.expression;
    return (
      assignment.type === "AssignmentExpression" &&
      assignment.operator === "=" &&
      assignment.left.type === "MemberExpression" &&
      !assignment.left.computed &&
      assignment.left.object.type === "ThisExpression" &&
      assignment.left.property.type === "Identifier" &&
      assignment.left.property.name !== "__proto__" &&
      assignment.right.type === "Identifier" &&
      params.has(assignment.right.name)
    );
  });
}

function isEnumTag(statement, name) {
  if (statement?.type !== "ExpressionStatement") return false;
  const assignment = statement.expression;
  if (
    assignment.type !== "AssignmentExpression" ||
    assignment.operator !== "=" ||
    assignment.right.type !== "Literal" ||
    !Number.isInteger(assignment.right.value)
  )
    return false;
  const member = assignment.left;
  return (
    member.type === "MemberExpression" &&
    !member.computed &&
    member.property.name === "$tag" &&
    member.object.type === "MemberExpression" &&
    !member.object.computed &&
    member.object.property.name === "prototype" &&
    member.object.object.type === "Identifier" &&
    member.object.object.name === name
  );
}

/** Keep enum tags with their constructor so bundlers can drop the whole definition. */
export function annotateConstructorPurity(source) {
  const parsed = parseSync("generated-moonbit.js", source);
  if (parsed.errors.length)
    throw new Error(`Cannot parse MoonBit output: ${parsed.errors[0].message}`);
  const firstReference = new Map();
  const reassigned = new Set();
  const declarations = new Map();
  const recordDeclaration = (node) => {
    if (node.id?.type === "Identifier")
      declarations.set(node.id.name, (declarations.get(node.id.name) ?? 0) + 1);
  };
  new Visitor({
    FunctionDeclaration: recordDeclaration,
    FunctionExpression: recordDeclaration,
    VariableDeclarator: recordDeclaration,
    AssignmentExpression(node) {
      if (node.left.type === "Identifier") reassigned.add(node.left.name);
    },
    UpdateExpression(node) {
      if (node.argument.type === "Identifier") reassigned.add(node.argument.name);
    },
    Identifier(node) {
      if (CONSTRUCTOR_NAME.test(node.name))
        firstReference.set(
          node.name,
          Math.min(firstReference.get(node.name) ?? Infinity, node.start),
        );
    },
  }).visit(parsed.program);

  const constructors = new Set();
  const edits = [];
  let constructorsWrapped = 0;
  let allocationsAnnotated = 0;
  const statements = parsed.program.body;
  for (let index = 0; index < statements.length; index++) {
    const declaration = statements[index];
    if (!isDataConstructor(declaration)) continue;
    const name = declaration.id.name;
    if (reassigned.has(name) || declarations.get(name) !== 1) continue;
    // Preserve function hoisting if an earlier statement references this binding.
    if (firstReference.get(name) < declaration.start) continue;
    constructors.add(name);
    const tag = statements[index + 1];
    if (!isEnumTag(tag, name)) continue;
    const body = source.slice(declaration.start, tag.end).replace(/^/gm, "  ");
    edits.push({
      start: declaration.start,
      end: tag.end,
      text: `const ${name} = /* @__PURE__ */ (() => {\n${body}\n  return ${name};\n})();`,
    });
    constructorsWrapped++;
  }

  // MoonBit hoists singleton enums and constant records. Unused allocations must
  // be removable too. Restrict this to top-level declarations, leaving FFI code alone.
  for (const statement of statements) {
    if (statement.type !== "VariableDeclaration") continue;
    for (const { init } of statement.declarations) {
      if (
        init?.type !== "NewExpression" ||
        init.callee.type !== "Identifier" ||
        !constructors.has(init.callee.name)
      )
        continue;
      if (
        /\/\*\s*[@#]__PURE__\s*\*\/\s*$/.test(
          source.slice(Math.max(0, init.start - 40), init.start),
        )
      )
        continue;
      edits.push({ start: init.start, end: init.start, text: "/* @__PURE__ */ " });
      allocationsAnnotated++;
    }
  }

  let output = source;
  for (const edit of edits.sort((a, b) => b.start - a.start)) {
    output = output.slice(0, edit.start) + edit.text + output.slice(edit.end);
  }
  return { output, constructorsWrapped, allocationsAnnotated };
}
