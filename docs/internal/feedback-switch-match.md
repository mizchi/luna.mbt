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