# Docs Deploy Guide

`website/dist-docs` を Cloudflare Pages に 2 段階で配信する運用です。

## 目的

- PR では preview を確認する
- `main` では production を更新する
- build 結果を artifact で共有し、同一成果物を deploy する

## GitHub Actions 構成

対象 workflow: `.github/workflows/docs.yaml`

1. `build`
   - docs をビルド
   - `docs-dist` artifact を作成
2. `deploy-preview`
   - `pull_request` で実行
   - `preview-pr-<PR番号>` ブランチに配信
3. `deploy-production`
   - `push` to `main` または `workflow_dispatch`（`rollback_ref` 空）で実行
   - 本番に配信
   - `changed_files_count` がしきい値を超えるとガードで停止
4. `rollback-production`
   - `workflow_dispatch` + `rollback_ref` 指定時に実行
   - `rollback_mode=dry-run` がデフォルト
   - 本番反映には `rollback_mode=apply` と `rollback_confirm=ROLLBACK_PRODUCTION` が必要

workflow には `concurrency` を設定しており、同じ系統の古い run は自動キャンセルされます（`workflow_dispatch` は手動オペレーション保護のためキャンセルしません）。

各 deploy ジョブは `GITHUB_STEP_SUMMARY` に実行サマリを出力します。
build ジョブでは `docs-build-meta` artifact（ref/sha/件数など）を保存します。
差分追跡用に `docs-change-meta` artifact（比較ベース/差分ファイル一覧）も保存します。
`docs-build-meta` には `docs_file_count` と `docs_dist_sha256` を含め、`deploy-preview` / `deploy-production` で成果物整合性（sha256 + 件数）を検証してから deploy します。
`deploy-production` では `### Deploy guard decision` を出力します。
`Resolve guard block issues` では `### Guard issue resolve` を追記し、`target_issue`, `stale_issue_count`, `stale_issue_numbers` を出力します。

## 大差分ガードの解除

`build` の `Evaluate change volume warning` が warning になった場合、`push` 経由の production deploy はブロックされます。反映する場合は `workflow_dispatch` で再実行し、次を指定します。

- `rollback_ref`: 空
- `override_change_warning`: `FORCE_DEPLOY_LARGE_CHANGE`

`workflow_dispatch` 経由の production deploy は解除トークン未指定だと常に停止します。

## しきい値の設定

差分しきい値は repository variable `DOCS_CHANGE_WARN_THRESHOLD` で設定できます。未設定または不正値の場合はデフォルト `200` が使われます。

`docs-change-warning` には次が出力されます。

- `threshold`
- `threshold_source` (`repo_var` or `default`)

## ガードブロック通知

`push` to `main` の production deploy がガードで block された場合、workflow は `docs-deploy-guard` ラベル付き Issue を自動作成します。すでに同じ ref の open Issue がある場合は再利用してコメントを追記します（同じ sha の重複コメントは作成しません）。同じ ref で open が複数ある場合は最新 1 件へ集約し、古い issue を自動 close します。
Issue / コメントには整合性スナップショットとして次を含めます。

- `integrity_status`
- `expected_file_count`, `expected_sha256`
- `verified_file_count`, `verified_sha256`
- 検索キー: `docs_ref=<ref>`, `docs_sha=<sha>`

production deploy が成功した場合、同じ ref の open `docs-deploy-guard` Issue のうち最新 1 件が自動で close されます。

## 必要な Secrets

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

未設定時は workflow 内で deploy ステップをスキップします。

## ローカル事前確認

```bash
just verify
```

次に docs をローカルビルドして成果物を確認します。

```bash
just build-doc
```

## 失敗時の切り分け

1. build 失敗: `build` ジョブのログを確認
2. deploy 失敗: secrets の有無と `wrangler` 実行ログを確認
3. 整合性チェック失敗: `Verify docs artifact integrity (preview|production)` の expected/actual（count, sha256）を確認
4. preview 未反映: PR 番号付き branch (`preview-pr-*`) の deploy 結果を確認

より詳細な障害対応は `docs/runbook.md` を参照してください。
