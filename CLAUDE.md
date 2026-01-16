# Luna UI Library

MoonBitで実装されたIsland ArchitectureベースのUIライブラリ。

## 関連リポジトリ

- **Sol** (SSR/SSGフレームワーク): [mizchi/sol.mbt](https://github.com/mizchi/sol.mbt)

## ディレクトリ構成

```
src/
├── core/             # 環境非依存コア (mizchi/luna/core)
│   ├── vnode.mbt     # VNode型定義
│   ├── routes/       # ルート定義・マッチング
│   ├── serialize/    # シリアライズ
│   └── render/       # VNode → HTML レンダリング
├── js/               # ブラウザ向けJS実装
│   ├── resource/     # リアクティブシグナル (mizchi/luna/js/resource)
│   └── api/          # JavaScript API エクスポート (mizchi/luna/js/api)
├── dom/              # DOM操作、Hydration、ルーター (mizchi/luna/dom)
├── x/                # 実験的モジュール
│   ├── stella/       # Island埋め込み用Shard生成
│   ├── css/          # CSS Utilities
│   └── components/   # UIコンポーネント
├── examples/         # サンプルコード
└── tests/            # 統合テスト
js/                   # NPMパッケージ
├── luna/             # @luna_ui/luna
└── loader/           # @luna_ui/luna-loader
e2e/                  # Playwrightテスト
```

## 開発コマンド

タスク一覧は `just --list` で確認できる。

```bash
# 基本
just check            # 型チェック (moon check --target js)
just fmt              # フォーマット (moon fmt)
just build-moon       # MoonBit ビルド
just build-loader     # Loader ビルド (turbo経由)

# テスト
just test-moonbit     # MoonBit ユニットテスト
just test-vitest      # Vitest テスト (node + browser)
just test-e2e         # E2E テスト (Playwright)
just test-xplat       # クロスプラットフォームテスト (js, wasm, native)

# CI
just ci               # check + test-incremental + size-check
just size             # バンドルサイズ表示
just size-check       # バンドルサイズチェック (loader.js < 5KB)

# ユーティリティ
just luna --help      # Luna CLI (CSS utilities)
just metrics          # メトリクス収集
just vup patch        # バージョンアップ
```

## 開発ポリシー

- `moon check` を通過すること
- `moon fmt` でフォーマット統一
- ローダーサイズは5KB以下を維持

## コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) に従う。

```
<type>(<scope>): <description>
```

| type | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメント |
| `refactor` | リファクタリング |
| `perf` | パフォーマンス改善 |
| `test` | テスト追加・修正 |
| `chore` | ビルド・CI など |

## テストポリシー

テストピラミッドに基づき、可能な限り低レイヤーでテストする。

| レイヤー | ディレクトリ | 対象 |
|---------|-------------|------|
| MoonBit Unit | `src/**/*_test.mbt` | 純粋ロジック（DOM非依存） |
| Vitest | `js/**/tests/*.test.ts` | DOM操作、Hydration |
| E2E | `e2e/**/*.test.ts` | 統合テスト |
