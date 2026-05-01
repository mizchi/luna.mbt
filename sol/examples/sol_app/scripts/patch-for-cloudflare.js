#!/usr/bin/env node
// Cloudflare Workers向けパッチスクリプト
import { readFileSync, writeFileSync } from 'fs';

const file = process.argv[2];
if (!file) {
  console.error('Usage: node patch-for-cloudflare.js <file>');
  process.exit(1);
}

let content = readFileSync(file, 'utf-8');

// 1. random_seed をコメントアウトして固定値に置換
content = content.replace(
  /^(var moonbitlang\$core\$builtin\$\$seed = moonbitlang\$core\$builtin\$\$random_seed\(\);)$/m,
  '// $1\nvar moonbitlang$$core$$builtin$$$$seed = 123456789;'
);

// 2. run() の即時実行を削除
content = content.replace(
  /^\(\(\) => \{\s*mizchi\$luna\$sol\$\$run\([^)]+\);\s*\}\)\(\);$/m,
  '// run() removed for Cloudflare Workers'
);

writeFileSync(file, content);
console.log(`Patched: ${file}`);
