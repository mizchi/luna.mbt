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
