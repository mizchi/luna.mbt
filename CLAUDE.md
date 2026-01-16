# Luna UI Library

MoonBitで実装されたIsland ArchitectureベースのUIライブラリ。

## 関連リポジトリ

- **Sol** (SSR/SSGフレームワーク): [mizchi/sol.mbt](https://github.com/mizchi/sol.mbt)

## モジュール構成

| モジュール | 責務 | ドキュメント |
|-----------|------|-------------|
| **Luna** | コアUIライブラリ。Signal、VNode、DOM操作、CSS Utilities、Hydration | [src/](src/README.md) |
| **Stella** | Island埋め込み用Shard生成 | [src/stella/](src/stella/README.md) |

## ディレクトリ構成

```
src/
├── core/             # 環境非依存コア (mizchi/luna/core)
│   ├── vnode.mbt     # VNode型定義
│   ├── async_state.mbt # AsyncState型定義
│   ├── routes/       # ルート定義・マッチング
│   ├── serialize/    # シリアライズ
│   └── render/       # VNode → HTML レンダリング
├── js/               # ブラウザ向けJS実装
│   ├── resource/     # リアクティブシグナル・リソース (mizchi/luna/js/resource)
│   └── api/          # JavaScript API エクスポート (mizchi/luna/js/api)
├── dom/              # DOM操作、Hydration、ルーター、静的DOM (mizchi/luna/dom)
├── x/                # 実験的モジュール
│   ├── stella/       # Island埋め込み用Shard生成
│   ├── testing/      # テストユーティリティ
│   ├── css/          # CSS Utilities
│   ├── components/   # UIコンポーネント
│   └── ir/           # 言語間型同期IR
├── examples/         # サンプルコード
├── tests/            # 統合テスト
├── _bench/           # ベンチマーク
├── top.mbt           # トップレベル再エクスポート
└── moon.pkg
js/                   # NPMパッケージ (@luna_ui/luna)
e2e/                  # Playwrightテスト
spec/                 # 仕様・設計ドキュメント
examples/             # サンプルプロジェクト
```

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
just test-luna                # Luna 全テスト
```

## 開発ポリシー

- `moon check` を通過すること
- `moon fmt` でフォーマット統一
- ローダーサイズは5KB以下を維持
- luna(core): バンドルサイズが最優先
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

scope は `luna`, `stella`, `ci`, `docs` など。

```bash
# 例
feat(luna): add new signal API
fix(luna): resolve hydration mismatch
docs: update README
```

## テストポリシー

テストピラミッドに基づき、可能な限り低レイヤーでテストする。

| レイヤー | ディレクトリ | 対象 |
|---------|-------------|------|
| MoonBit Unit | `src/**/*_test.mbt` | 純粋ロジック（DOM非依存） |
| Browser | `js/luna/tests/*.test.ts` | DOM操作、Hydration |
| E2E | `e2e/**/*.test.ts` | 統合テスト |

## 仕様ドキュメント

`spec/` に仕様・設計ドキュメントを配置。

```
spec/
├── internal/           # 内部開発ログ・進行中の設計
│   ├── done/          # 実装完了済みの記録
│   └── deprecated/    # 廃止された設計
└── (確定仕様をここに追加)
```
