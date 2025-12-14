# cov-reporter

MoonBit/JavaScript 混合プロジェクト向けの統合カバレッジレポーター。

ソースマップを使用して、JavaScript カバレッジデータを元の MoonBit ソースファイルにマッピングします。

## 特徴

- **複数ソース対応**: MoonBit (Cobertura), Vitest (Istanbul), Playwright (V8)
- **ソースマップ統合**: JS カバレッジを .mbt ソースにマッピング
- **マージ機能**: 複数のカバレッジソースを統合
- **レポーター**: コンソール出力、HTML レポート

## 使い方

```typescript
import {
  createDefaultConfig,
  loadSourceMaps,
  destroySourceMaps,
  parseMoonbitCoverage,
  parseVitestCoverage,
  parseE2ECoverage,
  mergeCoverage,
  reportToConsole,
  reportToHtml,
} from "./lib/cov-reporter/index.ts";

// 設定
const config = createDefaultConfig("/path/to/project");

// ソースマップ読み込み
const sourceMaps = await loadSourceMaps(config.sourceMapDir);

// カバレッジ解析
const moonbit = await parseMoonbitCoverage(config);
const vitest = await parseVitestCoverage(config, sourceMaps, /.*myproject\//);
const e2e = await parseE2ECoverage(config, sourceMaps, /.*myproject\//);

// クリーンアップ
destroySourceMaps(sourceMaps);

// マージ
const merged = mergeCoverage(moonbit, vitest, e2e);

// レポート出力
reportToConsole(merged);
await reportToHtml(merged, config, "Coverage Report");
```

## モジュール構成

```
cov-reporter/
├── index.ts       # 公開API エクスポート
├── types.ts       # 型定義
├── sourcemap.ts   # ソースマップ読み込み
├── merge.ts       # カバレッジマージ・統計計算
├── parsers/       # フォーマット別パーサー
│   ├── moonbit.ts # MoonBit Cobertura XML
│   ├── vitest.ts  # Vitest Istanbul JSON
│   └── e2e.ts     # Playwright V8 JSON
└── reporters/     # レポート生成
    ├── console.ts # コンソール出力
    └── html.ts    # HTML レポート
```

## 型定義

### CoverageConfig

```typescript
interface CoverageConfig {
  projectRoot: string;    // プロジェクトルート
  coverageDir: string;    // カバレッジデータディレクトリ
  sourceMapDir: string;   // ソースマップディレクトリ
  include?: RegExp;       // 含めるファイルパターン
  exclude?: RegExp;       // 除外するファイルパターン
}
```

### FileCoverage

```typescript
interface FileCoverage {
  path: string;           // ファイルパス
  lines: LineCoverage[];  // 行カバレッジ
  source?: string;        // ソースコード（HTML用）
}

interface LineCoverage {
  line: number;           // 行番号
  count: number;          // 実行回数
}
```

## パーサー

### MoonBit (Cobertura)

`moon test --enable-coverage` + `moon coverage report -f cobertura` で生成される XML を解析。

```typescript
const coverage = await parseMoonbitCoverage(config);
```

### Vitest (Istanbul)

`vitest --coverage` で生成される `coverage-final.json` を解析し、ソースマップで .mbt にマッピング。

```typescript
const coverage = await parseVitestCoverage(config, sourceMaps, /.*luna\.mbt\//);
```

### Playwright E2E (V8)

`page.coverage.startJSCoverage()` で収集した V8 カバレッジを解析し、ソースマップで .mbt にマッピング。

```typescript
const coverage = await parseE2ECoverage(config, sourceMaps, /.*luna\.mbt\//);
```

## レポーター

### コンソール

```typescript
reportToConsole(coverage);
```

出力例:
```
──────────────────────────────────────────────────────────────────────
📊 Unified Coverage Report
──────────────────────────────────────────────────────────────────────

Overall: 43.6% (1670/3826 lines in 57 files)

📁 Per-directory breakdown:
  🟢 src/core/signal                           90.1% (237/263)
  🟡 src/renderer                              68.9% (235/341)
  🔴 src/router                                17.1% (18/105)
```

### HTML

```typescript
const outputPath = await reportToHtml(coverage, config, "My Report");
// -> coverage/unified/index.html
```

ファイル一覧とソースコード表示付きの詳細レポートを生成。

## 依存関係

- `source-map`: ソースマップ解析

## ライセンス

MIT
