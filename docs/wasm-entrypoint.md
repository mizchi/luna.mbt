# Sol Wasm Entrypoint Design (mbtx + Mars WASI/WAGI)

## Purpose

`sol` に「ルート/機能ごとに個別 prebuild した wasm をエントリポイントとして実行する」モードを追加する。

想定ランタイム:

- WASI CLI
- Spin WAGI (`executor = "wagi"`)
- Wasm Component (将来)

この設計は `.mbtx` を起点にするが、`mars` 側の WASI/WAGI 互換レイヤー（`spin_wagi` / `wasm_component`）との接続を前提にする。

## Constraints (as of 2026-02-18)

`.mbtx` は nightly 限定機能で、以下制約がある。

- `moon >= 0.1.20260214` が必要
- `fn main` 前提（main package）
- `moon test file.mbtx` は実用不可
- custom wasm export の直接指定は不可（`moon.pkg link` を inline できない）
- クロスファイル import 不可（単一ファイル）

したがって `.mbtx` 単体をそのまま「任意 export を持つ wasm API」として扱うのは難しい。
本機能では「`main` 実行型の wasm entrypoint」を採用する。

## Scope

### In scope

- 複数 `.mbtx` の個別 prebuild
- ルート -> wasm artifact の対応表生成
- WAGI 向け response protocol（stdout で HTTP レスポンスを返す）統一
- Spin 用 manifest 断片の生成

### Out of scope

- `.mbtx` 自体への export 拡張
- `moon test` の `.mbtx` 対応
- `mars` 全機能の即時 wasm 対応（段階移行）

## High-level Architecture

1. `sol` は `wasm-entrypoints` 定義を読む
2. 各 entrypoint を独立して build（prebuild）
3. 生成物と route の mapping manifest を出力
4. 実行時は host（Spin/WASI launcher）が route に応じて対応 wasm を起動

```
route request
  -> host router (Spin/WAGI or launcher)
  -> selected prebuilt wasm entrypoint
  -> stdout HTTP response
```

## Configuration Draft

`sol.config.ts` に `wasmEntryPoints` を追加する。

```ts
export default {
  wasmEntryPoints: [
    {
      id: "users_show",
      route: "/users/:id",
      source: "app/entries/users_show.mbtx",
      runtime: "wagi", // "wagi" | "wasi-cli" | "component"
      method: ["GET"],
    },
  ],
}
```

## Build Pipeline Draft

各 `.mbtx` を独立して build し、artifact を固定パスに配置:

```bash
moon run app/entries/users_show.mbtx --target wasm-gc --release --build-only
```

出力先（例）:

```
.sol/wasm/
  entries/
    users_show/
      module.wasm
      metadata.json
  manifest.json
  spin.toml.fragment
```

`manifest.json` 例:

```json
{
  "entries": [
    {
      "id": "users_show",
      "route": "/users/:id",
      "method": ["GET"],
      "runtime": "wagi",
      "wasm": ".sol/wasm/entries/users_show/module.wasm"
    }
  ]
}
```

## Runtime Contract

`.mbtx` entrypoint は以下の最小契約に従う:

- 入力:
  - path/method/query/body を env/argv/stdin で受け取る
- 出力:
  - `Status-Line + Headers + Body` を stdout に書く（WAGI 互換）
- 終了コード:
  - 正常: `0`
  - 異常: `!= 0`

この契約を `sol` が生成するテンプレート化で固定する。

## Mars Integration Strategy

短期は `mars` の pure 部分（router/trie）を再利用し、I/O 境界は `sol` 側で吸収する。

中期で `mars` adapters と接続:

- `@mars/adapters/spin_wagi` の設定情報生成
- `@mars/adapters/wasm_component` 向け binding hint 生成

`mars` 側でも adapter は現状 placeholder 的実装が含まれるため、`sol` は「生成物と manifest/hint を揃える」責務を先行する。

## Proposed Commands

- `sol build --wasm-entrypoints`
- `sol build --wasm-entrypoints --runtime wagi`
- `sol build --wasm-entrypoints --emit-spin-fragment`

将来:

- `sol dev --wasm-entrypoints`（変更された `.mbtx` のみ差分 rebuild）

## Migration Plan

### Phase 0 (Doc + Prototype)

- 1 entrypoint のみ対応
- `manifest.json` と `spin.toml.fragment` 出力

### Phase 1 (Multi-entrypoint)

- 複数 entrypoint の prebuild
- route conflict 検査

### Phase 2 (Mars adapter bridge)

- `spin_wagi` / `wasm_component` 設定出力を正式化

### Phase 3 (Operational hardening)

- build cache
- error format 標準化
- tracing/logging 規約

## Risks

- `.mbtx` が nightly 依存であること
- WAGI 実行系で method/body 取得に差異があること
- entrypoint 数が増えると build/起動コストが増えること

## Decision Record

- `.mbtx` の制約（main-only, no custom exports）を前提に「per-entrypoint executable wasm」モデルを採用
- API export モデルではなく protocol（stdin/stdout/env）モデルで統一
- `sol` は build orchestrator と manifest generator を担い、runtime 実装依存は adapter boundary に閉じ込める
