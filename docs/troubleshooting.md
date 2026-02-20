# Sol トラブルシューティング

`sol` 開発中によく起きる問題の切り分け手順をまとめます。

## 1. ルートが 404 になる

症状:

- `sol dev` は起動しているが、期待したページ/API が 404

確認:

1. `app/server/routes.mbt` に対象 route が定義されているか
2. ルーティング API の使い分けが合っているか
   - `@router.register_routes` / `@router.register_server_routes`: path prefix 割り当て
   - `@router.register_sol_routes`: Layout 合成込み
3. 変更後に `sol generate --mode dev` を実行したか

参照: `docs/routing.md`

## 2. HMR が効かない

症状:

- ページ更新が自動反映されない

確認:

1. `sol dev` で起動しているか（`sol serve` では HMR しない）
2. コンソールに HMR WebSocket エラーがないか
3. `head` / loader 周りのカスタムで script 注入を壊していないか

参照: `docs/hot-reload.md`

## 3. `sol build` は通るが `sol serve` で想定どおり動かない

確認:

1. `sol build --clean` で生成物を再作成する
2. 直前に `sol generate --mode prod` を実行して差分を確認する
3. `sol.config.ts`（または `sol.config.json`）の `routes` / `output` が意図どおりか確認する

## 4. k6 ベンチ結果が安定しない

症状:

- 同じ条件でも `p95` が大きくぶれる

確認:

1. `just bench-k6-quick` でウォームアップしてから本計測する
2. `just bench-k6 60 30s 0.05 5` で複数回実行し中央値で比較する
3. ぶれが大きい場合は `just bench-k6-profile 10 10s` で route 別に確認する

参照: `docs/benchmarking.md`

## 5. ベンチ実行時に接続エラーになる

症状:

- `k6` 実行時に `connection refused` が出る

確認:

1. サーバーが `http://localhost:7777` で起動しているか
2. `SOL_BENCH_MODE=1` で起動した場合に `/api/bench/ping` が 200 か
3. 別ポートで起動している場合は `BASE_URL` を合わせる

## 6. まず見るべき一次資料

- ルーティング仕様: `docs/routing.md`
- ベンチ仕様: `docs/benchmarking.md`
- HMR 契約: `docs/hot-reload.md`
