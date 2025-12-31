# experimental_ir

**実験的**: 言語間型同期のための中間表現（Intermediate Representation）。

MoonBit と TypeScript 間で Island コンポーネントの Props 型を同期するための IR。
将来的に独立パッケージとして分離予定。

## 設計目標

1. **言語非依存**: MoonBit, TypeScript, Rust, Go など複数言語に対応
2. **シリアライズ可能**: JSON で表現可能
3. **双方向変換**: Source → IR → Target の変換が可能
4. **拡張可能**: 新しい型システムの機能を追加可能

## 対応する型

| カテゴリ | 型 |
|---------|-----|
| Primitive | Bool, Int, Float, String, Unit |
| Compound | Array, Map, Tuple, Option |
| Named | Struct, Enum, Interface |
| Reference | TypeRef (他の型への参照) |
| Generic | TypeParam, Applied |

## ファイル構成

```
src/experimental_ir/
├── README.md
├── moon.pkg.json
├── types.mbt              # コアIR型定義
├── serialize.mbt          # JSON シリアライズ
├── codegen_moonbit.mbt    # MoonBit コード生成
├── codegen_typescript.mbt # TypeScript コード生成
├── parser_moonbit.mbt     # MoonBit ソース解析
├── parser_typescript.mbt  # TypeScript ソース解析
└── types_wbtest.mbt       # テスト
```

## 使用例

```moonbit
// TypeScript → IR → MoonBit
let result = parse_typescript("/** @island */ export interface Props { ... }")
let moonbit_code = result.schema.to_moonbit()

// MoonBit → IR → TypeScript
let result = parse_moonbit("/// @island\npub struct Props { ... }")
let ts_code = result.schema.to_typescript()
```
