# Docs Runbook

docs 配信の障害対応と rollback 手順を定義します。

## 対象

- workflow: `.github/workflows/docs.yaml`
- 配信先: Cloudflare Pages (`sol-docs`)

## 監視ポイント

1. GitHub Actions `docs` workflow の失敗有無
2. `deploy-preview` / `deploy-production` / `rollback-production` の実行ログ
3. `GITHUB_STEP_SUMMARY` の deploy サマリ
4. 公開 URL の表示可否
5. `### Deploy guard decision` の `decision`（allow/block）
6. `concurrency` による自動キャンセルの有無（意図した run が残っているか）
7. `### Artifact integrity` の `status=ok`（`sha256` と file count が一致）
8. `### Guard issue resolve` の `target_issue` / `stale_issue_count` / `stale_issue_numbers`

## 事前チェック

ローカルで最低限の確認を行います。

```bash
just verify
just build-doc
just smoke-docs
```

## 障害時の一次対応

1. 直近の失敗ジョブを特定する
2. 失敗段階を分類する（build / smoke / deploy）
3. `CLOUDFLARE_API_TOKEN` と `CLOUDFLARE_ACCOUNT_ID` の設定を確認する
4. `docs-build-meta` / `docs-change-meta` artifact と step summary を確認する
   - `docs-build-meta` の `docs_file_count` / `docs_dist_sha256` を確認する
5. `Verify docs artifact integrity (preview|production)` の expected/actual（count, sha256）を確認する
6. `docs-change-warning` の `level` / `threshold` / `threshold_source` と `docs-deploy-guard` の `decision` を確認する
7. `docs-deploy-guard` ラベル付き Issue の状態（block 時は作成または同じ ref へのコメント追記、同じ sha は重複コメントしない、成功時は同じ ref の最新 issue 1 件が close）を確認する
   - issue 本文/コメントの `integrity_status`, `expected_sha256`, `verified_sha256` を確認する
   - 検索キー `docs_ref=<ref>`, `docs_sha=<sha>` で該当 issue/comment を追跡できることを確認する
   - 同じ ref の open issue が複数ある場合、最新 1 件に集約され古い issue が自動 close されることを確認する
8. 影響が大きい場合は rollback を実施する

## 大差分ガードで止まった場合

`Guard production deploy on large change` が失敗した場合は、以下で手動反映します。

1. 差分内容をレビューし、反映して問題ないことを確認する
2. GitHub Actions で `docs` workflow を `workflow_dispatch` 実行する
3. `rollback_ref` は空のままにする（通常 production deploy）
4. `override_change_warning=FORCE_DEPLOY_LARGE_CHANGE` を指定する
5. `### Deploy guard decision` が `decision=allow` であることを確認する
6. 成功後に同じ ref の `docs-deploy-guard` Issue の最新 1 件が自動 close されることを確認する

`workflow_dispatch` 経由で production deploy する場合、この解除トークンは常に必須です。

`threshold_source=default` の場合は repository variable `DOCS_CHANGE_WARN_THRESHOLD` が未設定または不正値です。必要なら値を修正して再実行します。

## Rollback 手順（production）

`docs` workflow を `workflow_dispatch` で実行し、`rollback_ref` を指定します。

1. 復旧対象の ref（tag / commit / branch）を決める
2. GitHub Actions で `docs` workflow を手動実行する
3. `rollback_ref` に復旧対象 ref を入力する
4. まず `rollback_mode=dry-run` で実行し、`rollback-production` の dry-run 完了を確認する
5. 本番反映が必要な場合のみ `rollback_mode=apply` にし、`rollback_confirm=ROLLBACK_PRODUCTION` を入力して実行する
6. 本番 URL を開いて復旧を確認する

`rollback_ref` が空の場合は通常 build フローが実行されます。

## 復旧確認

1. `index.html` が配信される
2. 主要ページが 200 を返す
3. 直近デプロイとの差分が想定どおり

## 事後対応

1. 障害原因を `docs/troubleshooting.md` または関連ドキュメントへ反映する
2. 必要に応じて `docs.yaml` の smoke 条件を追加する
