# リポジトリ分割設計

## 概要

Luna (UI Core) と Sol (SSR/SSG Framework) を別リポジトリに分割する設計。

## 動機

1. **責務の明確化**: UIコアとSSRフレームワークを概念的に分離
2. **外部コントリビュータ**: 各リポジトリへの貢献を分けやすくする
3. **Lunaの軽量化**: Luna単体ユーザーにSol関連の依存を見せない

## 分割後の構成

### mizchi/luna (UIコア)

```
luna/
├── src/
│   ├── luna/              # UIコア
│   │   ├── signal/        # Signal
│   │   ├── css/           # CSS Utilities
│   │   ├── render/        # VNode → DOM
│   │   ├── dom/           # DOM操作
│   │   ├── static_dom/    # ServerNode (SSR用)
│   │   ├── serialize/     # シリアライズ
│   │   ├── routes/        # クライアントルーティング
│   │   └── testing/       # テストユーティリティ
│   ├── stella/            # Island Shard生成
│   ├── internal/          # 内部ユーティリティ
│   │   ├── json_utils/
│   │   └── utils/
│   └── _bench/            # ベンチマーク
├── js/luna/               # NPM: @luna_ui/luna
└── e2e/                   # E2Eテスト (Luna単体)
```

**moon.mod.json:**
```json
{
  "name": "mizchi/luna",
  "deps": {
    "moonbitlang/async": "...",
    "moonbitlang/x": "...",
    "mizchi/js": "..."
  }
}
```

### mizchi/sol (SSR/SSGフレームワーク)

```
sol/
├── src/
│   ├── sol/               # SSR/SSGコア
│   │   ├── router/        # サーバールーティング
│   │   ├── routes/        # ファイルベースルーティング
│   │   ├── ssg/           # 静的サイト生成
│   │   ├── isr/           # ISR
│   │   ├── middleware/    # ミドルウェア
│   │   ├── action/        # Server Actions
│   │   ├── builder/       # ビルダー
│   │   ├── parser/        # MoonBit解析
│   │   ├── cli/           # CLIツール
│   │   ├── hmr/           # HMR
│   │   └── content/       # Markdown, Frontmatter
│   └── core/env/          # FileSystem trait
├── examples/              # サンプルプロジェクト
└── website/               # ドキュメント (Sol SSGで生成)
```

**moon.mod.json:**
```json
{
  "name": "mizchi/sol",
  "deps": {
    "mizchi/luna": "x.y.z",
    "mizchi/npm_typed": "...",
    "mizchi/markdown": "...",
    "mizchi/jsonschema": "...",
    "moonbitlang/parser": "..."
  }
}
```

## 依存関係マップ

```
                    ┌─────────────┐
                    │  mizchi/js  │
                    └──────┬──────┘
                           │
    ┌──────────────────────┼──────────────────────┐
    │                      ▼                      │
    │              ┌─────────────┐                │
    │              │ mizchi/luna │                │
    │              │  (UIコア)    │                │
    │              └──────┬──────┘                │
    │                     │                       │
    │                     ▼                       │
    │   ┌────────────────────────────────────┐    │
    │   │           mizchi/sol               │    │
    │   │  ┌────────────────────────────┐   │    │
    │   │  │  depends on:               │   │    │
    │   │  │  - mizchi/luna             │   │    │
    │   │  │  - mizchi/luna/render      │   │    │
    │   │  │  - mizchi/luna/static_dom  │   │    │
    │   │  │  - mizchi/luna/routes      │   │    │
    │   │  │  - mizchi/luna/stella      │   │    │
    │   │  │  - mizchi/luna/internal/*  │   │    │
    │   │  └────────────────────────────┘   │    │
    │   └────────────────────────────────────┘    │
    └─────────────────────────────────────────────┘
```

## 移行手順

### Phase 1: 準備

1. **依存関係の整理**
   - `internal/json_utils`, `internal/utils` を Luna のパブリック API として整備
   - または Sol 側にコピーして独立させる

2. **Luna の API 安定化**
   - Sol が依存する Luna API を明確にドキュメント化
   - Breaking change の影響範囲を特定

### Phase 2: リポジトリ作成

1. **mizchi/sol リポジトリ作成**
   - `src/sol/`, `src/core/env/` を移動
   - `examples/`, `website/` を移動
   - 新規 `moon.mod.json` 作成

2. **mizchi/luna リポジトリ整理**
   - Sol 関連ファイルを削除
   - `moon.mod.json` から不要な依存を削除

### Phase 3: CI/CD 設定

1. **Luna CI**
   - 単体テスト、Browserテスト
   - NPM パブリッシュ (@luna_ui/luna)

2. **Sol CI**
   - Luna の最新版でテスト
   - SSG/ISR 統合テスト
   - NPM パブリッシュ (@luna_ui/sol)

### Phase 4: バージョニング

- Luna: セマンティックバージョニング
- Sol: Luna バージョンを `deps` で固定
- Breaking change 時は Sol も同時リリース

## 検討事項

### internal/ の扱い

| オプション | メリット | デメリット |
|-----------|---------|-----------|
| Luna に残す | 変更不要 | Sol が Luna 内部に依存 |
| Sol にコピー | 独立性向上 | コード重複 |
| 別パッケージ化 | 再利用可能 | 管理コスト増 |

**推奨**: Luna に残し、`mizchi/luna/internal/*` として公開 API 扱いにする

### static_dom (ServerNode) の位置

現在 `luna/static_dom/` にあるが、これは SSR 専用。

| オプション | メリット | デメリット |
|-----------|---------|-----------|
| Luna に残す | Luna 単体で SSR 可能 | SSR 不要ユーザーにも含まれる |
| Sol に移動 | 責務が明確 | Luna と Sol 両方で VNode が必要 |

**推奨**: Luna に残す（tree-shaking で除外可能）

### examples/ の扱い

- `examples/sol_*`: Sol リポジトリへ
- `examples/` で Luna 単体サンプルがあれば Luna へ

## スケジュール案

1. **準備期間**: 依存関係の整理、API ドキュメント
2. **分割実施**: リポジトリ作成、ファイル移動
3. **検証期間**: CI/CD 設定、テスト確認
4. **リリース**: 両リポジトリで v1.0.0

## リスクと対策

| リスク | 対策 |
|-------|------|
| Luna 変更時に Sol が壊れる | CI で Luna latest でテスト |
| バージョン管理の複雑化 | Dependabot / Renovate 導入 |
| コントリビュータ混乱 | 明確なドキュメント |

## 未決定事項

- [ ] internal/ の最終的な扱い
- [ ] NPM パッケージ名の確定
- [ ] 分割実施日の決定

---

## 詳細移行計画

### Sol が依存する Luna パッケージ一覧

```
mizchi/luna                  # core VNode, Node types
mizchi/luna/render           # VNode → string rendering
mizchi/luna/static_dom       # ServerNode for SSR
mizchi/luna/routes           # client-side routing
mizchi/luna/signal           # (browser_router経由)
mizchi/luna/js/stream_renderer   # streaming SSR
mizchi/luna/js/fs_adapter    # FileSystem implementation
mizchi/luna/stella                # Island shard generation
mizchi/luna/internal/json_utils   # JSON utilities
mizchi/luna/internal/utils        # string utilities
mizchi/luna/core/env              # FileSystem trait
```

### Step 1: Luna リポジトリの準備

```bash
# 1. Luna リポジトリで作業
cd luna.mbt

# 2. Sol 依存を削除した moon.mod.json を準備
# 以下の依存を削除予定:
#   - moonbitlang/parser (Sol の parser で使用)
#   - mizchi/markdown (Sol の content で使用)
#   - mizchi/jsonschema (Sol の config で使用)
#   - mizchi/process_pool (Sol の builder_pool で使用)

# 3. npm_typed/hono も削除候補だが、Luna 側で使う可能性があるか確認
```

### Step 2: Sol リポジトリ作成

```bash
# 1. 新規リポジトリ作成
mkdir sol.mbt && cd sol.mbt
git init

# 2. moon.mod.json 作成
cat > moon.mod.json << 'EOF'
{
  "name": "mizchi/sol",
  "version": "0.1.0",
  "deps": {
    "mizchi/luna": "0.x.x",
    "moonbitlang/async": "0.15.0",
    "moonbitlang/x": "0.4.38",
    "moonbitlang/parser": "0.1.12",
    "mizchi/npm_typed": "0.1.6",
    "mizchi/markdown": "0.3.3",
    "mizchi/js": "0.10.7",
    "mizchi/jsonschema": "0.6.0",
    "mizchi/process_pool": "0.1.1"
  },
  "source": "src"
}
EOF

# 3. ディレクトリ構造作成
mkdir -p src/sol src/core
```

### Step 3: ファイル移動

```bash
# Luna リポジトリから Sol へコピー
# (git mv ではなく履歴を残すため後で git filter-branch 等を検討)

# Sol コア
cp -r ../luna.mbt/src/sol/* src/sol/

# core/env (FileSystem trait)
cp -r ../luna.mbt/src/core/env src/core/

# examples
cp -r ../luna.mbt/examples .

# website
cp -r ../luna.mbt/website .

# spec (Sol関連のみ)
mkdir -p spec
cp ../luna.mbt/spec/sol/* spec/ 2>/dev/null || true
```

### Step 4: パッケージパス書き換え

Sol リポジトリ内の `moon.pkg.json` で Luna への参照を更新:

```bash
# 書き換えパターン
# Before: "mizchi/luna/sol/*"  → "mizchi/sol/*"
# Before: "mizchi/luna/core/*" → "mizchi/sol/core/*"

# 一括置換スクリプト
find src -name "moon.pkg.json" -exec sed -i '' \
  -e 's|mizchi/luna/sol/|mizchi/sol/|g' \
  -e 's|mizchi/luna/core/|mizchi/sol/core/|g' \
  {} \;
```

### Step 5: Luna リポジトリから Sol を削除

```bash
cd luna.mbt

# Sol 関連ディレクトリ削除
rm -rf src/sol
rm -rf src/core/env
rm -rf examples/sol_*
rm -rf website

# moon.mod.json から不要な依存削除
# (手動で編集)

# 確認
moon check
```

### Step 6: CI/CD 設定

**Luna (.github/workflows/ci.yml):**
```yaml
name: Luna CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install MoonBit
        run: curl -fsSL https://cli.moonbitlang.com/install.sh | bash
      - run: moon check
      - run: moon test
      - run: pnpm install && pnpm test
```

**Sol (.github/workflows/ci.yml):**
```yaml
name: Sol CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install MoonBit
        run: curl -fsSL https://cli.moonbitlang.com/install.sh | bash
      - run: moon update  # Luna の最新版を取得
      - run: moon check
      - run: moon test
      - run: pnpm install && pnpm test
```

### Step 7: NPM パッケージ設定

**Luna (js/luna/package.json):**
```json
{
  "name": "@luna_ui/luna",
  "version": "0.x.x",
  "exports": {
    ".": "./dist/luna.js",
    "./signal": "./dist/signal.js"
  }
}
```

**Sol (js/sol/package.json):** (新規作成)
```json
{
  "name": "@luna_ui/sol",
  "version": "0.x.x",
  "peerDependencies": {
    "@luna_ui/luna": "^0.x.x"
  },
  "bin": {
    "sol": "./dist/cli.js"
  }
}
```

### 検証チェックリスト

- [ ] Luna 単体で `moon check` が通る
- [ ] Luna 単体で `moon test` が通る
- [ ] Sol で `moon update && moon check` が通る
- [ ] Sol で `moon test` が通る
- [ ] `examples/sol_app` が動作する
- [ ] `website/` がビルドできる
- [ ] NPM パッケージが publish できる

### ロールバック手順

問題が発生した場合:

```bash
# Luna リポジトリを元に戻す
git reset --hard HEAD~1

# Sol リポジトリを削除
rm -rf sol.mbt
```

---

## 分割後の依存関係図 (確定版)

```
┌─────────────────────────────────────────────────────────────────┐
│                       外部パッケージ                              │
│  moonbitlang/async, moonbitlang/x, mizchi/js                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     mizchi/luna (公開)                           │
│                                                                 │
│  ┌────────────┐  ┌────────────┐                                │
│  │   luna/    │  │  stella/   │                                │
│  │  signal    │  │  (shard)   │                                │
│  │  render    │  └────────────┘                                │
│  │  css       │                                                 │
│  │  dom       │                                                 │
│  │  static_dom│  ← SSR用だが Luna に含める                       │
│  │  routes    │  ← クライアントルーティング                        │
│  │  js/       │                                                 │
│  │   stream_  │  ← streaming SSR (Luna に残す)                   │
│  │   renderer │                                                 │
│  │   api      │                                                 │
│  └────────────┘                                                 │
│                                                                 │
│  ※ internal/, core/env, js/fs_adapter は Luna から削除          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       mizchi/sol (公開)                          │
│                                                                 │
│  追加依存: moonbitlang/parser, mizchi/npm_typed,                │
│           mizchi/markdown, mizchi/jsonschema, mizchi/process_pool│
│                                                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│  │   sol/     │  │  core/     │  │ internal/  │                │
│  │  router    │  │  env       │  │ json_utils │  ← コピー       │
│  │  ssg       │  │ (FS trait) │  │ utils      │                │
│  │  isr       │  └────────────┘  └────────────┘                │
│  │  cli       │  ┌────────────┐  ┌────────────┐                │
│  │  content   │  │ adapters/  │  │ examples/  │                │
│  │  ...       │  │  fs/       │  │ website/   │                │
│  └────────────┘  └────────────┘  └────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

## core/env の扱いについて

`core/env` は FileSystem trait を定義しており、これは:
- Sol の SSG/builder で使用
- `luna/js/fs_adapter` が実装を提供

**選択肢:**

| オプション | 説明 |
|-----------|------|
| Sol に移動 | SSG 専用なので Sol 側に |
| Luna に残す | `fs_adapter` が依存するため Luna 側に |
| 両方に配置 | trait を Luna、実装を各側に |

**推奨**: `core/env` は Sol に移動し、`luna/js/fs_adapter` も Sol に移動。
Luna 側に残すと「ファイルシステム」という SSR/SSG 関心が Luna に入ってしまう。

### 代替案: fs_adapter の移動

```bash
# Sol に fs_adapter も移動
mv src/luna/js/fs_adapter src/sol/adapters/fs/

# 参照を更新
# Before: mizchi/luna/js/fs_adapter
# After:  mizchi/sol/adapters/fs
```

## 決定事項

| 項目 | 決定 | 理由 |
|------|------|------|
| `core/env` + `fs_adapter` | **Sol に移動** | FileSystem は SSG の関心 |
| `stella` | **Luna に残す** | Island shard 生成は UI コアの一部 |
| `internal/` | **Sol にコピー** | 重複を許容して完全分離 |
| Git 履歴 | **新規リポジトリ** | シンプルに開始 |
| NPM スコープ | **@luna_ui を維持** | `@luna_ui/luna`, `@luna_ui/sol` |

### 事前準備 (完了)

以下の作業は既に完了:

1. **browser_router を Luna に移動** ✅
   - `src/sol/browser_router` → `src/luna/browser_router`

2. **Luna の internal/utils 依存をインライン化** ✅
   - `stream_renderer`: extract_wc_name_from_url
   - `render`: extract_wc_name_from_url
   - `serialize`: extract_substring
   - `dom/client`: extract_wc_name_from_url
   - `routes`: split_by

3. **core/env + fs_adapter を Sol に移動** ✅
   - `src/core/env` → `src/sol/core/env`
   - `src/luna/js/fs_adapter` → `src/sol/adapters/fs`

Luna パッケージから `internal/` と `core/` への依存が完全に解消された。

---

## 移動対象ファイル一覧

### Luna から削除するファイル

```
src/sol/                    # → mizchi/sol へ
src/core/env/               # → mizchi/sol/core/env へ
src/internal/               # → mizchi/sol/internal へ
src/luna/js/fs_adapter/     # → mizchi/sol/adapters/fs へ
examples/sol_*              # → mizchi/sol/examples へ
examples/ssg_test/          # → mizchi/sol/examples へ
website/                    # → mizchi/sol/website へ
spec/sol/                   # → mizchi/sol/spec へ
```

### Luna に残すファイル

```
src/luna/                   # UIコア
src/luna/signal/            # Signal
src/luna/css/               # CSS Utilities
src/luna/render/            # VNode → string
src/luna/dom/               # DOM操作
src/luna/static_dom/        # ServerNode (SSR)
src/luna/routes/            # クライアントルーティング
src/luna/serialize/         # シリアライズ
src/luna/testing/           # テストユーティリティ
src/luna/js/stream_renderer/  # streaming SSR
src/luna/js/api/            # JS API
src/stella/                 # Island Shard生成
src/_bench/                 # ベンチマーク
js/luna/                    # NPMパッケージ
e2e/                        # E2Eテスト
examples/stella-component/  # Stella サンプル
```

### moon.mod.json の変更

**Luna (分割後):**
```json
{
  "name": "mizchi/luna",
  "deps": {
    "moonbitlang/async": "0.15.0",
    "moonbitlang/x": "0.4.38",
    "moonbitlang/parser": "0.1.12",
    "mizchi/js": "0.10.7"
  }
}
```

削除される依存:
- `mizchi/npm_typed` (hono など)
- `mizchi/markdown`
- `mizchi/jsonschema`
- `mizchi/process_pool`

**注意**: `moonbitlang/parser` は `luna/css/analyzer` で使用しているため残す

**Sol (新規):**
```json
{
  "name": "mizchi/sol",
  "deps": {
    "mizchi/luna": "0.x.x",
    "moonbitlang/async": "0.15.0",
    "moonbitlang/x": "0.4.38",
    "moonbitlang/parser": "0.1.12",
    "mizchi/npm_typed": "0.1.6",
    "mizchi/markdown": "0.3.3",
    "mizchi/js": "0.10.7",
    "mizchi/jsonschema": "0.6.0",
    "mizchi/process_pool": "0.1.1"
  }
}
```
