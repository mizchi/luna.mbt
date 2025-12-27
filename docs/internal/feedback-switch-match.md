https://x.com/kikuchan98/status/2004866211059036589

 tsx で Switch Match が少し期待と違ってて、使い方合ってますかね…。

      <h1>Luna Counter Example</h1>
      <p>
        Count: {count}
        <Switch>
          <Match when={() => count() % 3 === 0}>
            <div>Bang!</div>
          </Match>
        </Switch>
  
Show だと期待通りなので、動的な値に反応してないような気がしてます。

うーん、でもなんかまだおかしいです…。
１つ目の Match が無視されているような感じです。
例えば fallback あり & Match 1つだと常に fallback になります。
でも必ず無視されるわけでもないので、ちょっと混乱してます。

Show が子ノードを2つ以上取れないのは仕様ですか…？

mizchi: Fragment に包むとどうですか

Fragment に包むと、何も出なくなっちゃいました…。
というか、Fragment 単体で使っても子要素が何も出ないです。

---

Solid のサンプルを引用する。

場合によっては、2 つ以上の排他的な結果を持つ条件式を扱う必要があります。このような場合には、JavaScript の switch/case を大まかにモデル化した <Switch> と <Match> のコンポーネントを用意しました。

各条件にマッチするかどうかを順に試し、最初に true と評価されたものをレンダリングして停止します。すべてに失敗した場合は、フォールバックをレンダリングします。

この例では、ネストした <Show> コンポーネントを次のように置き換えることができます:

```html
<Switch fallback={<p>{x()} is between 5 and 10</p>}>
  <Match when={x() > 10}>
    <p>{x()} is greater than 10</p>
  </Match>
  <Match when={5 > x()}>
    <p>{x()} is less than 5</p>
  </Match>
</Switch>
```

---

## 修正内容 (2025-12-27)

### 問題1: Switch/Match が正しく動作しない

**原因:**
- `Switch` コンポーネントが `children` が配列でない場合（単一の Match）に対応していなかった
- 単一の Match を渡すと配列チェックで失敗し、常に fallback が返されていた

**修正:**
- `js/luna/src/index.ts` の `Switch` 関数を修正
- children を配列に正規化し、ネストした配列もフラット化
- `__isMatch` プロパティを持つ要素のみをフィルタリング

### 問題2: Fragment が子要素を表示しない

**原因:**
- `jsx-runtime.ts` の `Fragment` 関数が配列を返していただけで、MoonBit の `fragment()` 関数を呼んでいなかった
- 配列は DomNode として認識されず、レンダリングされなかった

**修正:**
- `js/luna/src/jsx-runtime.ts` で MoonBit の `fragment` 関数をインポート
- `Fragment` 関数が `fragment(children)` を呼び出して DomNode を返すように変更

### テスト追加
- `js/luna/tests/solidjs-api.test.ts` に Switch/Match のテストを追加
  - 単一の Match
  - 単一の Match + fallback
  - 複数の Match
  - アクセサ条件での動的更新