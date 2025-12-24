# Luna UI Library

MoonBitで実装されたIsland ArchitectureベースのUIライブラリ。

## モジュール構成

| モジュール | 責務 | ドキュメント |
|-----------|------|-------------|
| **Luna** | コアUIライブラリ。Signal、VNode、DOM操作、Hydration | [src/luna/](src/luna/README.md), [src/platform/](src/platform/README.md) |
| **Sol** | SSRフレームワーク。Hono統合、Middleware、Server Actions | [src/sol/](src/sol/README.md) |
| **Astra** | SSG（静的サイトジェネレーター）。Markdown → HTML | [src/astra/](src/astra/README.md) |
| **Stella** | Island埋め込み用Shard生成 | [src/stella/](src/stella/README.md) |

## ディレクトリ構成

```
src/
├── luna/           # Luna Core: Signal, Virtual Node, Render（ターゲット非依存）
├── core/           # 共有型定義: Routes, Serialize, SSG Types
├── platform/       # DOM, JS API, Server DOM（プラットフォーム固有）
├── stella/         # Island埋め込み用Shard生成
├── sol/            # SSRフレームワーク (Middleware, Server Actions)
├── astra/          # SSG
├── internal/       # 内部ユーティリティ
└── _bench/         # ベンチマーク
js/                 # NPMパッケージ (@luna_ui/luna)
e2e/                # Playwrightテスト
docs/               # ドキュメント（Astraで生成）
examples/           # サンプルプロジェクト
```

docs/ は astra のパターンに沿って生成される。
docs/internal は内部の開発ログが設置される。

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
just test-astra               # Astra 全テスト
just test-sol                 # Sol 全テスト
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
- sol: --target native でサーバーで動くことを目指す。速度 > サイズ。
- astra: next.js の static build みたいなもので、 sol と可能な限りコードを統合する
- stella: 実験的なコードは含むが、コア部分はクローズドにする

## テストポリシー

テストピラミッドに基づき、可能な限り低レイヤーでテストする。

| レイヤー | ディレクトリ | 対象 |
|---------|-------------|------|
| MoonBit Unit | `src/**/*_test.mbt` | 純粋ロジック（DOM非依存） |
| Browser | `js/luna/tests/*.test.ts` | DOM操作、Hydration |
| E2E | `e2e/**/*.test.ts` | SSR統合 |
