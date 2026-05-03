---
title: "ライフサイクル: onMount"
---

# onMount

コンポーネントが DOM にマウントされたときに一度だけコードを実行します。

## 基本的な使い方

```typescript
import { onMount } from '@luna_ui/luna';

function MyComponent() {
  onMount(() => {
    console.log("コンポーネントがマウントされました！");
  });

  return <div>Hello</div>;
}
```

## onMount が実行されるタイミング

- コンポーネントの DOM が作成された後
- 初期レンダリングが完了した後
- コンポーネントインスタンスごとに一度だけ
- Effect が実行される前

## 一般的なユースケース

### DOM アクセス

作成後に DOM 要素にアクセス：

```typescript
function AutoFocus() {
  let inputRef;

  onMount(() => {
    inputRef.focus();
  });

  return <input ref={inputRef} />;
}
```

### データフェッチ

コンポーネントマウント時に初期データをロード：

```typescript
function UserProfile(props) {
  const [user, setUser] = createSignal(null);
  const [loading, setLoading] = createSignal(true);

  onMount(async () => {
    const data = await fetch(`/api/users/${props.id}`);
    setUser(await data.json());
    setLoading(false);
  });

  return (
    <Show when={!loading()} fallback={<Spinner />}>
      <div>{user()?.name}</div>
    </Show>
  );
}
```

### サードパーティライブラリ

DOM 要素が必要なライブラリを初期化：

```typescript
function Chart(props) {
  let containerRef;

  onMount(() => {
    // DOM 準備完了後にチャートライブラリを初期化
    const chart = new ChartLibrary(containerRef, {
      data: props.data,
      type: props.type,
    });

    onCleanup(() => {
      chart.destroy();
    });
  });

  return <div ref={containerRef} class="chart-container" />;
}
```

## onMount vs createEffect

| 観点 | onMount | createEffect |
|------|---------|--------------|
| 実行 | 一度 | 依存関係変更ごと |
| 依存関係追跡 | いいえ | はい |
| 用途 | セットアップ、初期化 | リアクティブな副作用 |

```typescript
// onMount: 一度実行
onMount(() => {
  initializeLibrary();
});

// createEffect: 変更時に実行
createEffect(() => {
  updateLibrary(data());  // data 変更時に再実行
});
```

## 試してみよう

以下を行うコンポーネントを作成：

1. マウント時にユーザーデータをフェッチ
2. 入力フィールドを自動フォーカス
3. マウント時にログを記録

<details>
<summary>解答</summary>

```typescript
function UserForm(props) {
  let nameInput;
  const [user, setUser] = createSignal(null);
  const [loading, setLoading] = createSignal(true);

  onMount(() => {
    console.log("UserForm mounted");
  });

  onMount(async () => {
    const response = await fetch(`/api/users/${props.userId}`);
    setUser(await response.json());
    setLoading(false);
  });

  onMount(() => {
    // DOM 準備完了を確実にするため少し遅延
    setTimeout(() => nameInput?.focus(), 0);
  });

  return (
    <Show when={!loading()} fallback={<p>Loading...</p>}>
      <form>
        <input
          ref={nameInput}
          value={user()?.name || ""}
          placeholder="名前"
        />
      </form>
    </Show>
  );
}
```

</details>

## 次へ

[onCleanup →](./lifecycle_oncleanup) について学ぶ
