# Sol ドキュメントガイド

`docs/` の入口です。目的別に読む順を固定し、仕様の単一ソースを明確にします。

## 読む順

1. 開発参加の準備
   - `docs/onboarding.md`
2. 導入（最短起動）
   - `docs/quickstart.md`
3. デプロイ運用
   - `docs/deploy.md`
4. 障害対応
   - `docs/runbook.md`
5. ルーティング仕様
   - `docs/routing.md`
6. 開発運用（ベンチ）
   - `docs/benchmarking.md`
7. トラブルシューティング
   - `docs/troubleshooting.md`
8. 開発時体験（HMR）
   - `docs/hot-reload.md`
9. 移行
   - `docs/migrate-from-mars.md`
10. 高度な設計（Wasm entrypoint）
   - `docs/wasm-entrypoint.md`

## 目的別リンク

- 仕様を確認したい
  - `docs/routing.md`
  - `docs/benchmarking.md`
- まず動かしたい
  - `docs/onboarding.md`
  - `docs/quickstart.md`
- デプロイを確認したい
  - `docs/deploy.md`
- 障害対応を確認したい
  - `docs/runbook.md`
- 問題を切り分けたい
  - `docs/troubleshooting.md`
- `mars` から段階移行したい
  - `docs/migrate-from-mars.md`
- HMR の契約を確認したい
  - `docs/hot-reload.md`
- `.mbtx` / WASI / WAGI の将来設計を確認したい
  - `docs/wasm-entrypoint.md`

## ドキュメントマップ

| Path | Role | Notes |
|---|---|---|
| `docs/onboarding.md` | ガイド | 開発参加の初日手順と `just verify` |
| `docs/quickstart.md` | ガイド | `dev -> build -> serve` の最短手順 |
| `docs/deploy.md` | ガイド | docs の preview / production 配信手順 |
| `docs/runbook.md` | 運用 | docs の障害対応と rollback 手順 |
| `docs/routing.md` | 仕様（単一ソース） | API 選択、Layout semantics、`source_path` 規約 |
| `docs/benchmarking.md` | 仕様（単一ソース） | k6 手順、`SOL_BENCH_MODE`、高負荷時のばらつき切り分け |
| `docs/troubleshooting.md` | 運用 | 404/HMR/ベンチぶれの切り分け |
| `docs/hot-reload.md` | 設計 | `sol`/`mars` 共通の HMR 契約 |
| `docs/migrate-from-mars.md` | ガイド | `mars` 既存コードからの段階移行 |
| `docs/wasm-entrypoint.md` | 設計ドラフト | `.mbtx` ベースの wasm entrypoint 方針 |
| `docs/router-layout-support.md` | リダイレクト | `docs/routing.md` へ統合済み |
| `docs/catch-all-encoding.md` | リダイレクト | `docs/routing.md` へ統合済み |

## 更新ルール

- 仕様変更は先に単一ソース（`docs/routing.md` / `docs/benchmarking.md`）を更新する
- README や補助文書は単一ソースへのリンクを貼り、同内容を重複記述しない
- 互換のため残した文書は、統合先リンクを先頭に明示する
