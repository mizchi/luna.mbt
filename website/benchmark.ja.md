---
title: Benchmark Report
sidebar: false
---

# Luna Benchmark Report

このページの数値はすべて、このリポジトリ内のスクリプトが出力したものです。各表には、それを再現するコマンドを併記しています。記憶や第三者のベンチマークからの引用は含みません。

数値は「どこまで信用してよいか」で分類しています:

| 分類 | 指標 | マシンによって変わるか |
|------|------|------------------------|
| **厳密** | バンドルサイズ、伝播回数 | 変わらない — どこで測ってもバイト/回数が一致 |
| **相対的** | Preact / React とのグリッドベンチ | 比率は保たれるが、絶対 ops/s は保たれない |
| **参考値** | Signal スループット、MoonBit マイクロベンチ | マシン・実行ごとに変動する |

## 1. バンドルサイズ

Luna に「唯一のバンドルサイズ」はありません。公開エントリポイントは tree-shaking 可能で、import したものだけが出力に入ります — `resource-lite` の 351 B から、router + resource をフルに使う 24.5 KB まで。

```sh
node luna/scripts/treeshake-size.mjs --check
```

| エントリポイント | Minified | Gzip |
|------------------|---------:|-----:|
| `resource-lite` | 351 B | 210 B |
| `router-lite` | 2,539 B | 1,149 B |
| `render` | 7,021 B | 2,264 B |
| `signals-only` | 7,370 B | 2,591 B |
| `memo` | 8,487 B | 2,917 B |
| `raw-signals` | 8,657 B | 2,869 B |
| `signals-effect` | 8,900 B | 3,005 B |
| `resource-index` | 9,988 B | 3,305 B |
| `split-signals-shared` | 11,933 B | 3,861 B |
| `split-signals` | 14,540 B | 4,195 B |
| `router-index` | 21,482 B | 5,900 B |
| `router-resource` | 24,534 B | 6,800 B |

これらは `luna/scripts/treeshake-baseline.json` にコミットされており、CI は 1 バイトのずれでも失敗します。概算ではなく厳密値です。

### Preact との直接比較

**同じプログラム**を Luna 版と Preact 版の 2 通りでビルドし、生成物を計測します:

```sh
node luna/scripts/preact-size-compare.mjs --build
```

| シナリオ | Luna (min / gzip) | Preact (min / gzip) | 小さい方 |
|----------|------------------:|--------------------:|----------|
| `signals-only` | 7,370 / 2,591 B | 4,538 / 1,645 B | Preact |
| `signals-effect` | 8,900 / 3,005 B | 4,560 / 1,660 B | Preact |
| `memo` | 8,487 / 2,917 B | 4,604 / 1,673 B | Preact |
| `render-static` | 7,021 / 2,264 B | 10,577 / 4,494 B | **Luna** |
| `render-reactive` | 11,915 / 3,851 B | 20,100 / 7,880 B | **Luna** |
| `context-basic` | 4,413 / 1,468 B | 12,854 / 5,360 B | **Luna** |

**Preact が 3 勝、Luna が 3 勝**です。Signal 単体は Preact のほうが小さく、レンダラは Luna のほうが小さい。何かを描画し始めた時点で、これらのケースでは Luna が有利になります。

スクリプトは Luna の signal バンドルに繰り返し現れる 2 つの要因も報告します — 範囲外アクセスの panic 文字列と、スタックトレース解析のパス。どちらも Luna 自体ではなく MoonBit ランタイム由来です。

React はサイズ計測ハーネスに含まれていないため、このページは React のバンドルサイズについて何も主張しません。

## 2. リアクティビティを「回数」で測る

時間は揺れますが、更新回数は揺れません。このスイートは各ノードが**何回実行されたか**をアサートするので、伝播の退行は「遅いベンチ」ではなく「失敗するテスト」として現れます。

```sh
moon test --target js -p mizchi/luna/_bench
```

すべてのシナリオを signal への 5 回の書き込みで駆動します:

| シナリオ | 実測 | 意味 |
|----------|-----:|------|
| 無関係な signal に対する effect | **0** | 余計な起床がない |
| 読んでいる signal に対する effect | **5** | 1 書き込みにつき 1 回 |
| ダイヤモンド (2 経路) 越しの effect | **5** | グリッチフリー: 二重実行しない |
| 深さ 8 の memo チェーンの本体 | **40** | 8 memo × 5 書き込み、無駄なし |
| 5 回をまとめた batch での effect | **1** | `batch` が flush を畳む |
| 値が変わらない `watch` | **0** | 構造的等価でカットオフ |
| 値が潰れる memo 越しの effect | **5** | 下記参照 |
| `Eq` を見る memo 越しの effect | **0** | |

7 行目と 8 行目は、同じ導出を luna の 2 つのカットオフで測ったものです。`memo` は**同一性** (`physical_equal`) で判定するため、毎回新しい値を確保する計算 — ここでは組み立てた `String` — は、内容が変わっていなくても新しいオブジェクトを返し、依存先を起こしてしまいます。`memo_eq` は `Eq` で比較します:

```moonbit
// 5 回のソース更新で effect は 5 回
let loud = @resource.memo(() => "bucket \{src.get() / 100}")

// 同じ 5 回の更新で effect は 0 回
let quiet = @resource.memo_eq(() => "bucket \{src.get() / 100}")
```

ソース 1 変更あたりの本体評価回数はどちらも 1 回で、違うのは「何を再公開するか」だけです。

## 3. Signal のスループット

`runtime-bench.mjs` は、純粋な整数演算の**コントロールループ**と各シナリオを比較して比率を出します。生の ops/s より、別マシンでの再現性が高くなります。

```sh
node luna/scripts/runtime-bench.mjs
```

このページ末尾のマシンでの 3 回の中央値:

| シナリオ | ns/op | コントロール比 |
|----------|------:|---------------:|
| `control-loop` (基準) | 2.83 | 1.00 |
| `signal-set-get` | 6.85 | 2.42 |
| `signal-update-fn` | 9.62 | 3.40 |
| `batch-10-updates` | 20.36 | 7.25 |
| `create-signal` | 33.09 | 11.04 |
| `memo-after-update` | 46.41 | 16.42 |

signal の書き込み + 読み出しで、手書き演算ループ 1 回の約 **2.4 倍**のコストです。この比率もマシン間では動きます — リポジトリにコミットされた `runtime-bench-baseline.json` は、生成元マシンでの `signal-set-get` を 4.41 と記録しています。CI が厳密一致ではなく 20 % の許容幅で検査しているのはそのためです。

## 4. Preact / React との DOM ベンチマーク

```sh
pnpm test:bench     # vitest bench、Playwright 経由の実 Chromium
```

これは jsdom ではなく**ヘッドレス Chromium** で実行されます。この違いは重要です。以前のこのページは jsdom の数値を載せていましたが、マウント中心のケースで Luna を 1 桁近く過小評価していました。

3 回の中央値、ops/s (高いほど速い):

| シナリオ | Luna | Preact | React |
|----------|-----:|-------:|------:|
| 初回マウント、静的 2,500 セル | 818 | 954 | 91 |
| 初回マウント、リアクティブ 2,500 セル | 305 | 443 | 81 |
| 2,500 セルを全更新 | 442 | 9,790 | 95 |
| 初回マウント、5,000 セル | 424 | 444 | 49 |
| リストに 100 件追加 | 275 | 2,704 | 61 |

Luna を基準にすると:

| シナリオ | Preact | React |
|----------|-------:|------:|
| 初回マウント、静的 2,500 セル | 1.17 倍速い | 9.0 倍遅い |
| 初回マウント、リアクティブ 2,500 セル | 1.45 倍速い | 3.8 倍遅い |
| 2,500 セルを全更新 | 22.1 倍速い | 4.7 倍遅い |
| 初回マウント、5,000 セル | 1.05 倍速い | 8.7 倍遅い |
| リストに 100 件追加 | 9.8 倍速い | 4.5 倍遅い |

正直に読むと:

- **マウントは僅差**。Luna は Preact の 1.05〜1.45 倍以内で、5,000 セルではほぼ互角。React は両者より 4〜9 倍遅い。
- **「2,500 セル全更新」は Luna の最悪ケースであり、それは構成上そうなっている**。このベンチはグリッド全体を 1 つの signal に持たせ、各セルに動的な `className` バインディングを張ります。1 回の書き込みが 2,500 個の独立したバインディングを再実行する一方、Preact はコンポーネント 1 回の再描画と keyed diff 1 回で済みます。きめ細かいリアクティビティは逆の形 — 多数のうち少数だけが変わる — のために設計されているので、このシナリオは「設計対象外のケース」を測っています。
- **リストへの追加**も、規模が小さいだけで同じ話です。

実行ごとのばらつきも実在します。「初回マウント、リアクティブ 2,500 セル」の Luna は 3 回で 166 / 305 / 321 ops/s、vitest の相対誤差は最大 ±63 % でした。この表の数 % の差はノイズとして扱ってください。

## 5. MoonBit 側のベンチマーク

`moon bench` は SSR レンダラとシリアライザを対象にします。コンテナ環境の実時間は公開できるほど安定しません — 無変更のツリーで同じ `core/render` スイートが 10 倍以上ぶれることが観測されています。そのため CI は絶対速度ではなく、記録済みベースラインに対する **35 %** の許容幅で比較します:

```sh
node luna/scripts/moonbench-check.mjs --check
```

記録されているベースライン (`luna/scripts/moonbench-baseline.json`):

| スイート | ケース | ns/op |
|----------|--------|------:|
| `core/render` | list (10 items) | 2,530 |
| `core/render` | page | 2,665 |
| `core/render` | large_list (100 items, escaped) | 63,770 |
| `core/stream_render` | list (10 items) | 2,585 |
| `core/stream_render` | page | 2,980 |
| `core/stream_render` | large_list (100 items, escaped) | 72,740 |
| `core/serialize` | state_value_to_json: large_array | 3,200 |

同じ入力に対して、ストリーミング描画はバッファ描画より 2〜14 % 高コストです。これは最初のバイトを早く送り出すための対価です。

## Luna が向いている場面

願望ではなく、上記の実測に基づくと:

- **向いている**: ページの大半が静的で、リアクティブな領域が限られる場合 (ドキュメント、コンテンツサイト、局所更新のダッシュボード)。SSR と部分ハイドレーションが欲しい場合。UI 層を MoonBit の型システムで書きたい場合。
- **向いていない**: 更新のたびに DOM の大半が変わる場合。その形では Preact の VDOM diff が 1 桁勝ちますし、「2,500 バインディングが再実行される」という漸近的な性質は Luna 側のチューニングでは変わりません。
- **エコシステムは React/Preact と比較にならない** — コンポーネントライブラリ、devtools、採用のしやすさ、どれも別次元です。このページはそれを一切測っていませんが、実務では上のどの行より効いてくることが多い要素です。

`Signal`・`render`・ハイドレーションは MoonBit の全バックエンド向けにコンパイルできます (`luna/src` と `luna/src/core` は `supported_targets = "all"`)。ただし DOM 層 (`luna/src/dom`) は JS 専用で、公開している npm パッケージも JS 向けです。wasm-gc については、このページはまだ何もベンチマークできていません。

## 実行環境

このページのすべての数値は次の環境で計測しました:

- Linux x86-64、Intel Xeon @ 2.10 GHz、4 vCPU (コンテナ)
- Node.js v22.22.2
- Vitest 4.1.10、Playwright 経由のヘッドレス Chromium
- esbuild 0.28.1 (バンドル計測)
- moon 0.1.20260904 / moonc v0.10.12
- React 19.2.7 + ReactDOM 19.2.7、Preact 10.29.5

すべて再実行するには:

```sh
node luna/scripts/treeshake-size.mjs --check
node luna/scripts/preact-size-compare.mjs --build
node luna/scripts/runtime-bench.mjs
node luna/scripts/moonbench-check.mjs --check
moon test --target js -p mizchi/luna/_bench
pnpm test:bench
```
