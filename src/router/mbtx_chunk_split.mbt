// MBTX Chunk Splitting
//
// Extracts shared top-level declarations across multiple .mbtx JS outputs
// into a shared ESM module, reducing bundle size when multiple .mbtx
// routes share common MoonBit standard library code.

///|
/// Input entry for chunk splitting
pub(all) struct MbtxEntry {
  /// Unique ID (e.g., "hello", "counter")
  id : String
  /// Raw JS code from moon build
  code : String
}

///|
/// Result of chunk splitting
pub(all) struct MbtxChunkResult {
  /// Shared module code (empty if nothing shared)
  shared_code : String
  /// Per-entry ESM modules with imports from shared
  entries : Array[MbtxChunkEntry]
}

///|
/// A single entry after chunk splitting
pub(all) struct MbtxChunkEntry {
  id : String
  code : String
}

///|
/// Extract shared declarations across multiple .mbtx JS outputs.
/// Declarations appearing in 2+ files are moved to a shared module.
/// Each entry is rewritten to import from the shared module.
pub fn split_mbtx_chunks(
  entries : Array[MbtxEntry],
  shared_path? : String = "./_mbtx_shared.mjs",
) -> MbtxChunkResult {
  if entries.length() <= 1 {
    // Single entry: no sharing possible, just transform to ESM
    let result_entries = entries.map(fn(e) {
      MbtxChunkEntry::{ id: e.id, code: transform_mbtx_to_esm(e.code) }
    })
    return { shared_code: "", entries: result_entries }
  }
  ffi_split_mbtx_chunks(entries, shared_path)
}

///|
/// JS implementation of chunk splitting.
/// Parses top-level declarations, finds duplicates, and rewrites.
extern "js" fn ffi_split_mbtx_chunks(
  entries : Array[MbtxEntry],
  shared_path : String,
) -> MbtxChunkResult =
  #| (entries, sharedPath) => {
  #|   // Parse top-level declarations from JS code
  #|   // Handles: function Name(...) { ... } and const Name = ...;
  #|   function parseDecls(code) {
  #|     const decls = [];
  #|     const lines = code.split('\n');
  #|     let i = 0;
  #|     while (i < lines.length) {
  #|       const line = lines[i];
  #|       // function declaration
  #|       const fnMatch = line.match(/^function\s+(_M\w+)\s*\(/);
  #|       if (fnMatch) {
  #|         let depth = 0, start = i;
  #|         for (; i < lines.length; i++) {
  #|           for (const ch of lines[i]) { if (ch === '{') depth++; if (ch === '}') depth--; }
  #|           if (depth === 0) { i++; break; }
  #|         }
  #|         const body = lines.slice(start, i).join('\n');
  #|         decls.push({ name: fnMatch[1], body, start, end: i });
  #|         continue;
  #|       }
  #|       // const declaration
  #|       const constMatch = line.match(/^const\s+(_M\w+)\s*=/);
  #|       if (constMatch) {
  #|         let depth = 0, start = i;
  #|         for (; i < lines.length; i++) {
  #|           for (const ch of lines[i]) { if (ch === '{') depth++; if (ch === '}') depth--; }
  #|           if (depth <= 0 && lines[i].includes(';')) { i++; break; }
  #|         }
  #|         const body = lines.slice(start, i).join('\n');
  #|         decls.push({ name: constMatch[1], body, start, end: i });
  #|         continue;
  #|       }
  #|       i++;
  #|     }
  #|     return decls;
  #|   }
  #|
  #|   // Parse all entries
  #|   const parsed = entries.map(e => ({ id: e.id, code: e.code, decls: parseDecls(e.code) }));
  #|
  #|   // Count occurrences of each declaration body
  #|   const bodyCount = new Map();
  #|   const bodyToName = new Map();
  #|   for (const p of parsed) {
  #|     for (const d of p.decls) {
  #|       const key = d.body;
  #|       bodyCount.set(key, (bodyCount.get(key) || 0) + 1);
  #|       bodyToName.set(key, d.name);
  #|     }
  #|   }
  #|
  #|   // Shared = appears in 2+ entries
  #|   const sharedBodies = new Set();
  #|   const sharedNames = new Set();
  #|   for (const [body, count] of bodyCount) {
  #|     if (count >= 2) {
  #|       sharedBodies.add(body);
  #|       sharedNames.add(bodyToName.get(body));
  #|     }
  #|   }
  #|
  #|   if (sharedBodies.size === 0) {
  #|     // Nothing shared
  #|     return {
  #|       shared_code: '',
  #|       entries: parsed.map(p => ({
  #|         id: p.id,
  #|         code: transformToEsm(p.code),
  #|       })),
  #|     };
  #|   }
  #|
  #|   // Build shared module
  #|   const sharedLines = [];
  #|   for (const body of sharedBodies) {
  #|     // Replace leading 'function' or 'const' with 'export function' / 'export const'
  #|     const exported = body.replace(/^(function|const)\s/, 'export $1 ');
  #|     sharedLines.push(exported);
  #|   }
  #|   const shared_code = sharedLines.join('\n') + '\n';
  #|
  #|   // Rewrite each entry: remove shared decls, add import
  #|   const resultEntries = parsed.map(p => {
  #|     const lines = p.code.split('\n');
  #|     // Remove shared declarations
  #|     const removeRanges = [];
  #|     for (const d of p.decls) {
  #|       if (sharedBodies.has(d.body)) {
  #|         removeRanges.push([d.start, d.end]);
  #|       }
  #|     }
  #|     // Build filtered code
  #|     const kept = [];
  #|     let skip = 0;
  #|     for (let i = 0; i < lines.length; i++) {
  #|       const inRange = removeRanges.some(([s, e]) => i >= s && i < e);
  #|       if (!inRange) kept.push(lines[i]);
  #|     }
  #|     // Add import statement
  #|     const names = p.decls.filter(d => sharedBodies.has(d.body)).map(d => d.name);
  #|     const importLine = `import { ${[...new Set(names)].join(', ')} } from '${sharedPath}';`;
  #|     const rewritten = importLine + '\n' + kept.join('\n');
  #|     return { id: p.id, code: transformToEsm(rewritten) };
  #|   });
  #|
  #|   return { shared_code, entries: resultEntries };
  #|
  #|   function transformToEsm(code) {
  #|     return code
  #|       .replace(/\(\(\) => \{/, 'export default function render(env) { globalThis.__MBTX_ENV__ = env; globalThis.__MBTX_RESPONSE__ = undefined;')
  #|       .replace(/\}\)\(\);?\s*$/, ' return globalThis.__MBTX_RESPONSE__; }\n');
  #|   }
  #| }
