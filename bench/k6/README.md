# k6 Benchmarks

`k6` で `examples/sol_app` の主要ルートを負荷計測するためのスクリプトです。

仕様の単一ソース: `docs/benchmarking.md`

## 前提

```bash
brew install k6
```

## 使い方

リポジトリルートで実行:

```bash
# デフォルト: 20 VUs / 30s
just bench-k6

# クイック確認: 5 VUs / 10s
just bench-k6-quick

# 60 VUs / 30s / think 0.05 を 5 回実行して中央値を確認
just bench-k6 60 30s 0.05 5

# 2つの結果 JSON を差分比較（mix + route）
just bench-k6-compare bench/k6/results/base.json bench/k6/results/candidate.json auto
```

## 単体実行

サーバーを別ターミナルで起動している場合は直接 `k6` でも実行できます。

```bash
BASE_URL=http://localhost:7777 k6 run bench/k6/sol-app-mix.js
```

ルート別にボトルネックを確認する場合:

```bash
BASE_URL=http://localhost:7777 VUS=10 DURATION=10s k6 run bench/k6/sol-app-route-profile.js
```

`examples/sol_app` では `SOL_BENCH_MODE=1` を付けてサーバーを起動すると、
logger ミドルウェアを無効化して純粋なレスポンス性能を測れます。

k6 スクリプトはデバッグ API ではなくベンチ専用 API を使います。

- `/api/bench/ping`
- `/api/bench/test/[...path]`

`just bench-k6` は `runs > 1` を指定すると、各 run の JSON を保存し、
最後に `bench/k6/summarize-results.js` で中央値を集計します。

`just bench-k6-compare` は 2 つの JSON を比較し、`p95/avg/error/rate` の差分表を表示します。
`mode` は `mix` / `route` / `auto` から選べます。

## 高負荷時のばらつき切り分け（標準手順）

1. CPU 条件を固定する
   - 同一マシン・同一電源状態で実行し、不要なバックグラウンドジョブを止める
   - Linux では可能なら `cpupower` で governor を `performance` に固定する
2. ウォームアップを先に実施する
   - 計測に含めないウォームアップとして `just bench-k6-quick` を 1-2 回実行する
3. 再計測回数を固定して本計測する
   - 高負荷確認では `just bench-k6 60 30s 0.05 5` を基準にし、`runs=5` の中央値を採用する
4. ばらつきが大きい場合は route profile で切り分ける
   - `http_req_duration p95` の `max-min` が中央値の 10% を超える場合は `just bench-k6-profile 10 10s` で route 別の偏りを確認する

### パラメータ

- `BASE_URL` (default: `http://localhost:7777`)
- `VUS` (default: `20`)
- `DURATION` (default: `30s`)
- `THINK_TIME` (default: `0.1`)
- `runs` (`just bench-k6` 第4引数, default: `1`)
- `RESULTS_JSON` (optional, `runs=1` のときのみ有効)
- `RESULTS_JSON_BASE` (optional, `runs>1` のときの出力先プレフィックス。例: `bench/k6/results/high_load`)
- `mode` (`just bench-k6-compare` 第3引数, default: `auto`)
