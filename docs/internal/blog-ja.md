---
title: "Luna UI - MoonBit で JS/Moonbit で動く宣言的UIライブラリ"
emoji: "🌕"
type: "tech"
topics: ["moonbit", "webcomponents", "ssr", "frontend"]
published: false
---

いつかやろうと思っていたUIライブラリ自作に手をつけました。

軽量(7.5kb)、高速(solidと同等)、WebComponents SSR + Hydration という構成です。

この記事では Luna の紹介と、その発展系である Astra SSG, Sol Framework の紹介をします。ただ、記事公開時点では Astra と Sol はプロトタイプとしてリポジトリ内をチェックアウトすると動くんですが、まだ公開されてない点に注意してください。

## 成果物

🌕 **Luna UI** - MoonBit で書かれたシグナルベースの宣言的UIライブラリです。単体で使えるように、preactと同じ方針でとにかく小さく設計しています。

- ドキュメント: https://luna.mizchi.workers.dev/
- npm: `@mizchi/luna`

最小ランタイムは 7.5KBです。これは preact 11kb より小さいんですが、試した感じで treeshake で何の機能を使うかで差が出るので、ここの比較にあまり意味はなさそうでした。

## サンプルコード

Moobit 製ですが、 APIを luna/jsx-runtime でラップしたので, JSXがそのまま使えます。

APIはSolid風です。

```js
// TODO: Counter に合わせる。
function Card(props: { title: string; children?: JSX.Element }): JSX.Element {
  return (
    <div className="card">
      <h2>{props.title}</h2>
      <div className="content">{props.children}</div>
    </div>
  );
}

const node = (
  <Card title="My Card">
    <p>Card content here</p>
  </Card>
);
render(document.querySelector("#app"), <Card title="hello" />);
```

Moonbit 側ではこうなります。

```rust
fn main {
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let count = @signal.signal(0)
      let app = @dom.div([
        p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
        button(
          on=@events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
          [text("Click me")],
        ),
      ])
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
```

動いてるデモ

https://luna.mizchi.workers.dev/demo/game/

TodoMVC

https://luna.mizchi.workers.dev/demo/todomvc/

WebComponents

https://luna.mizchi.workers.dev/demo/wc/

## なぜ作ったか

UI ライブラリを実装するにあたって、今までのUIライブラリの経験から、こういう印象を持っていました

- **React** サイズが大きすぎるし、今再発明するならほとんどの抽象が不要
- **Qwik**: 最適化は素晴らしいですが、コンパイラの挙動が難しす技手、学習負荷が高すぎる
- **Preact**: 軽量ですが Signal は後付けで、互換層の存在を考えるとまだ削る余地がある
- **Solid**: Fine-Grained Reactivity は良いですが、Qwikと同じコンパイル時最適化で負荷が高い
- **Svelte/Vue**: 独自テンプレート構文が拡張性が低くて微妙

というわけで、こういうものを作ることにしました：

- Solid の API デザイン
- preact/signals の実装アプローチ
- Qwik の Resumability に近いローダー設計

コンパイル時にマジックなことをせず、明示的な Signal を中心としたシンプルな設計です。そして SSR と Island Architecture を前提として、遅延ロードできるようにしています。

そのままライブラリとして使ってもいいですが、可能ならば luna であることを意識せず、静的サイトとしてデプロイして WebComponents としてサードパーティスクリプトとして読み込める、というのを念頭に置いています。そのために astro/qwikloader を参考にしたアイランドとして動くようにしています

https://qwik.dev/docs/advanced/qwikloader/

## なぜ MoonBit で実装したか

クライアントとサーバーで同じテンプレートを記述して、クライアントでロジックを引き継ぐという「二重テンプレート問題」は古くからありました。

この問題に、現実的に初めて対処できたのが Next.js です。
SSRとは単にサーバーでHTMLを生成することではありません。JSの稼働部をクライアントに注入することで初めて

自分の Next.js と Qwik の経験からすると、ハイドレーションと SSR 時の最適化を行うなら、クライアントランタイムとサーバー SSR の垂直統合を行う必要があります。

今までは、それは Node.js でしか動きませんでした。Node.js + React は SSR の冪等性・ハイドレーションを同じ JS 実装から生成したことで証明しました。

でも複数の言語にクロスコンパイルできる Pure Moonbitなら？

他の言語でも、似たような構想はありました。例えば [mustache](https://mustache.github.io/) や、 [](https://github.com/glimmerjs/glimmer-vm), 最近だと Elixirの [Hologram](https://github.com/bartblast/hologram) が熱いですね。

Moonbit の強みは、JS Backend でほぼJSと等価な軽量なJSが生成できる事です。そして wasm-gc バックエンドも軽量で、native 200k ぐらいのランタイムを生成しますが、クライアントほどの

Node.js 以外で動く必要があるのは、CPU でボトルネックとなる SSR を Native や Wasm に変換することで、バックエンドを高速化できるからです。そして同じロジックで記述することで、ハイドレーションの正しさを保証できます。手元のベンチマークでは、ネイティブビルドで約 5 倍高速でした。

ただし、現状はサーバーの大部分を Hono へのバインディングとして実装しているので、まだ不完全です。一旦は Cloudflare Workers の JS バックエンドで動かすのをゴールとしています。

MoonBit は複数のターゲットにコンパイルできます：

```
MoonBit → JavaScript (ブラウザ)
        → Native (SSR サーバー)
        → Wasm (エッジ)
        → Wasm-GC (次世代ランタイム)
```

同じコードがサーバー(Native)でもクライアント(JS/Wasm)でも動きます。これは React + Node.js の組み合わせでしか実現できなかった SSR + Hydration を、言語レベルで一般化できる可能性があります。

## 設計意図

### 十分にランタイムが小さいなら、Qwik の最適化は過剰

Qwik は Resumability という素晴らしいコンセプトを持っていますが、そのためにコンパイラが複雑になりすぎています。

Luna の考え方はシンプルで、「十分に小さいランタイムなら、普通にロードすればいい」というものです。1.6KB のローダー + 必要な Island だけをロードする設計なら、Qwik ほどの最適化は必要ありません。

### Fine-Grained Reactivity

Virtual DOM を使わず、Signal が変更されたら直接 DOM を更新します。

```
Signal の変更 → 直接 DOM 更新 (O(1))
```

これは Solid と同じアプローチです。2500 セル全更新のような VDOM 向きのベンチマークでは負けますが、実際のアプリケーションでは部分更新がほとんどなので、こちらの方が有利なケースが多いです。

### MoonBit での Signal 実装

```moonbit
fn counter() -> @dom.DomNode {
  let count = @luna.signal(0)
  let doubled = @luna.memo(fn() { count.get() * 2 })

  @dom.div(class="counter", [
    @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
    @dom.button(
      on=@dom.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
      [@dom.text("+")],
    ),
  ])
}
```

`signal`, `memo`, `effect` という preact/signals と同じプリミティブです。MoonBit の型システムで守られているので、実行時エラーが起きにくくなっています。

## Sol: 多分世界初の WebComponents SSR + Hydration

自分が知る限り、この機能は自分が最初に実装していると思います。

実際に動いているデモはこちらです:
https://sol-example.mizchi.workers.dev/wc-counter

![](https://gyazo.com/3295e8521d7eb98bfa0bdc13f235ba4f.png)

Declarative Shadow DOM を使って、サーバーで展開した要素を shadowroot の下に配置し、JS からイベントハンドラを差分で注入します。

### なぜ WebComponents なのか

WebComponents が普及しない理由のひとつに、SSR との相性の悪さが挙げられます。

Solid の作者 Ryan Carniato も「Web Components Are Not the Future」という記事を書いています：
https://dev.to/ryansolid/web-components-are-not-the-future-48bh

これは自分の意見ですが、既存のライブラリを WebComponents に当てはめる、という発想だとうまくいきません。WebComponents の特性を活かした設計から始める必要があります。

Luna では Declarative Shadow DOM を前提として、以下を実現しました：

1. **SSR 時**: `<template shadowrootmode="open">` でスタイルと DOM を出力
2. **Hydration 時**: Shadow DOM 内の既存 DOM にイベントハンドラを接続
3. **CSS カプセル化**: Shadow DOM のおかげで自然に実現

```html
<!-- サーバーレンダリング出力 -->
<wc-counter luna:wc-url="/static/wc_counter.js" luna:wc-state='{"count":0}'>
  <template shadowrootmode="open">
    <style>:host { display: block; } .count { font-size: 2rem; }</style>
    <div class="counter">
      <span class="count-display">0</span>
      <button class="inc">+</button>
    </div>
  </template>
</wc-counter>
```

ブラウザはこの HTML を受け取った時点で Shadow DOM を構築するので、FOUC (Flash of Unstyled Content) が起きません。JS が読み込まれたらイベントハンドラだけ接続します。

### パフォーマンス

現状、パフォーマンス面のメリットはそこまで大きくありません。Plain HTML と比較して約 10% のオーバーヘッドがあります。ただし CSS カプセル化が自然に手に入るのは大きいです。

## vs RSC (React Server Components)

昨今の RSC の脆弱性で、クライアントとサーバー境界が曖昧なのはどうなんだ、という話があります。

Luna/Sol ではそもそも機能を分けています。SSR のみの async コンポーネントはイベントハンドラを注入できる必要はないので、型から別物にしました。

```
sol_app/
  client/           # Island コンポーネント (Hydration あり)
    counter.mbt
    moon.pkg.json
  server/           # サーバーコンポーネント (SSR のみ)
    home.mbt
    routes.mbt
    moon.pkg.json
```

サーバーコンポーネントは MoonBit の `async fn` で最初から非同期です：

```moonbit
async fn about(props : @router.PageProps) -> @server_dom.ServerNode {
  let content = [
    h1([text("About")]),
    p([text("Built with MoonBit and Sol framework.")]),
  ]
  @server_dom.ServerNode::sync(@luna.fragment(content))
}
```

クライアントコンポーネントとサーバーコンポーネントは型が違うので、混同する余地がありません。

## Astra: SSG フレームワーク

まだインターナルですが、ドキュメントサイト https://luna.mizchi.workers.dev/ は Astra という SSG で生成しています。

Next.js の Static Export みたいなもので、Sol とコードを共有しつつ静的サイトを生成できます。このドキュメントサイト自体が Astra の成果物です。

## ベンチマーク

### Luna の強み (MoonBit 内部ベンチマーク)

| 指標 | Luna | 備考 |
|------|------|------|
| バンドルサイズ | 9.4 KB (gzip) | React の 1/6 |
| SSR 性能 | 12,800 pages/sec | 1000アイテムリスト (78µs) |
| Signal 更新 | 11M ops/sec | Fine-Grained Reactivity |
| 部分 DOM 更新 | 4.5M ops/sec | VDOM diff なしで直接更新 |

### Luna の弱み (jsdom ベンチマーク、正直に)

| 指標 | Luna | Preact | 備考 |
|------|------|--------|------|
| Initial Mount (2,500 cells) | 67 ops/sec | 981 ops/sec | 14.6x 遅い |
| Large Grid (5,000 cells) | 29 ops/sec | 387 ops/sec | 13.3x 遅い |
| State Update (2,500 cells) | 111 ops/sec | 12,523 ops/sec | 113x 遅い |

全要素更新には向きませんが、部分更新・SSR・Island Architecture では強いです。

### なぜ VDOM ベンチで遅いのか

1. **全要素更新は Luna の想定外ユースケース** - Fine-Grained Reactivity は「一部だけ更新」が前提です
2. **MoonBit → JS コンパイル** - 生成された JS コードはまだ最適化の余地があります
3. **実際のアプリでは Luna が有利なケース** - ほとんどの UI は部分更新です

## MoonBit で UI ライブラリを作った感想

### 良かったこと

- **型システム**: コンパイル時にバグが見つかります
- **パターンマッチ**: enum + match で状態遷移を表現しやすいです
- **マルチターゲット**: 同じコードが Native/JS/Wasm で動きます

### 難しかったこと

- **エコシステムの若さ**: ライブラリが少ないです
- **FFI の設計**: JS との境界をどう設計するか悩みました
- **async/await**: まだ発展途上です

### MoonBit が流行るにはキラーアプリが必要

これは Rust における ripgrep や、Go における Docker みたいな話です。MoonBit にもキラーアプリが必要で、Luna がその一つになれたらいいなと思っています。

## まとめ

Luna は以下のような方向けです：

- SSR + 選択的ハイドレーションが必要
- Island Architecture で部分ハイドレーションしたい
- 小さなバンドルサイズが重要 (React の 1/6)
- MoonBit で型安全な UI を書きたい
- 将来的な Wasm-GC 対応を見据えている

興味があれば触ってみてください：
https://luna.mizchi.workers.dev/

---

ああ、それと。ドキュメントサイトも SSG ごと自作しています。これも MoonBit 製です。
