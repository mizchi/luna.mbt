# Luna UI Library

MoonBitで実装されたIsland ArchitectureベースのUIライブラリ。

## モジュール構成

| モジュール | 責務 | ドキュメント |
|-----------|------|-------------|
| **Luna** | コアUIライブラリ。Signal、VNode、DOM操作、CSS Utilities、Hydration | [src/luna/](src/luna/README.md), [src/platform/](src/platform/README.md) |
| **Sol** | SSR/SSGフレームワーク。Hono統合、Middleware、Server Actions、SSG | [src/sol/](src/sol/README.md) |
| **Stella** | Island埋め込み用Shard生成 | [src/stella/](src/stella/README.md) |

## ディレクトリ構成

```
src/
├── luna/           # Luna Core: Signal, Virtual Node, Render, SSR（ターゲット非依存）
├── core/           # 共有型定義: env (FileSystem trait)
├── platform/       # DOM, JS API, Server DOM（プラットフォーム固有）
├── stella/         # Island埋め込み用Shard生成
├── sol/            # SSR/SSGフレームワーク
│   ├── ssg/        # SSG (静的サイト生成、コンポーネント、キャッシュ)
│   ├── isr/        # ISR (Incremental Static Regeneration)
│   ├── router/     # ルーティング
│   ├── routes/     # ファイルベースルーティング、マニフェスト
│   ├── parser/     # MoonBit解析機
│   └── cli/        # CLIツール
├── internal/       # 内部ユーティリティ
└── _bench/         # ベンチマーク
js/                 # NPMパッケージ (@luna_ui/luna)
e2e/                # Playwrightテスト
website/            # 公開ドキュメント（Sol SSGで生成）
spec/               # 仕様・設計ドキュメント
examples/           # サンプルプロジェクト
```

- `website/` は Sol SSG でビルドされる公開ドキュメント
- `spec/` は内部仕様・設計書（開発者向け）

## 開発コマンド

タスク一覧は `just --list` で確認できる。

```bash
# 基本
just check                    # 型チェック (moon check)
just fmt                      # フォーマット (moon fmt)
just build-moon               # MoonBit ビルド

# テスト（ピラミッド軸）
just test-unit                # Unit tests (MoonBit)
just test-integration         # Integration tests (Vitest, Browser)
just test-e2e                 # E2E tests (Playwright)

# テスト（プロダクト軸）
just test-sol                 # Sol 全テスト (SSG含む)
just test-luna                # Luna 全テスト

# ドキュメント
just dev-doc                  # docs 開発サーバー (HMR対応)
just build-doc                # docs ビルド
```

## 開発ポリシー

- `moon check` を通過すること
- `moon fmt` でフォーマット統一
- ローダーサイズは5KB以下を維持
- luna(core): バンドルサイズが最優先
- sol: --target native でサーバーで動くことを目指す。速度 > サイズ。SSG機能も含む
- stella: 実験的なコードは含むが、コア部分はクローズドにする

## コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) に従う。CHANGELOG.md は `git-cliff` で自動生成される。

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
| `deps` | 依存関係の更新 |

scope は `luna`, `sol`, `stella`, `ci`, `docs` など。

```bash
# 例
feat(sol): add dynamic route support
fix(luna): resolve hydration mismatch
docs: update README
```

## テストポリシー

テストピラミッドに基づき、可能な限り低レイヤーでテストする。

| レイヤー | ディレクトリ | 対象 |
|---------|-------------|------|
| MoonBit Unit | `src/**/*_test.mbt` | 純粋ロジック（DOM非依存） |
| Browser | `js/luna/tests/*.test.ts` | DOM操作、Hydration |
| E2E | `e2e/**/*.test.ts` | SSR統合 |

## SSG 設定オプション

`sol.config.json` の `ssg` セクションで設定可能。

### メタファイル生成 (`metaFiles`)

```json
{
  "metaFiles": {
    "sitemap": true,   // sitemap.xml (デフォルト: true)
    "feed": false,     // feed.xml RSS 2.0 (デフォルト: false)
    "llmsTxt": false   // llms.txt (デフォルト: false)
  }
}
```

### CSS Utilities (`cssUtilities`)

```json
{
  "cssUtilities": {
    "enabled": true,        // CSS utility 抽出 (デフォルト: true)
    "split": false,         // ページ別CSS分割 (デフォルト: false)
    "inlineThreshold": 4096 // インライン化閾値 (バイト)
  }
}
```

## 仕様ドキュメント

`spec/` に仕様・設計ドキュメントを配置。

```
spec/
├── internal/           # 内部開発ログ・進行中の設計
│   ├── done/          # 実装完了済みの記録
│   └── deprecated/    # 廃止された設計
└── (確定仕様をここに追加)
```
