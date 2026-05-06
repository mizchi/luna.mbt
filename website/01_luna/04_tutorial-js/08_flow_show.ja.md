---
title: "制御フロー: Show"
---

# Show（条件付きレンダリング）

Signal に基づいてコンテンツを条件付きでレンダリングします。

## 基本的な使い方

```typescript
import { createSignal, Show } from '@luna_ui/luna';

function Toggle() {
  const [visible, setVisible] = createSignal(false);

  return (
    <div>
      <button onClick={() => setVisible(v => !v)}>
        トグル
      </button>

      <Show when={visible()}>
        <p>見えました！</p>
      </Show>
    </div>
  );
}
```

## フォールバックコンテンツ

条件が false のときに代替コンテンツを表示：

```typescript
<Show when={isLoggedIn()} fallback={<LoginForm />}>
  <Dashboard />
</Show>
```

## 値の抽出

条件が値（単なる boolean ではない）の場合、アクセスできます：

```typescript
const [user, setUser] = createSignal(null);

<Show when={user()} fallback={<p>Loading...</p>}>
  {(u) => <p>Welcome, {u.name}!</p>}
</Show>
```

レンダー関数は非 null が保証された truthy 値を受け取ります。

## なぜ Show vs 三項演算子？

```typescript
// 三項演算子 - 動作するが欠点がある
{visible() ? <Content /> : <Fallback />}

// Show - 推奨
<Show when={visible()} fallback={<Fallback />}>
  <Content />
</Show>
```

### Show の利点

1. **遅延評価**: 条件が true のときのみ children がレンダリング
2. **きれいな構文**: 特に複雑な条件で
3. **キー付きレンダリング**: 状態を保持またはリセット可能

## Keyed Show

デフォルトでは、Show はトグル時に DOM ノードを保持します。`keyed` を使用して再作成を強制：

```typescript
const [tab, setTab] = createSignal("home");

// 保持: 同じコンポーネントインスタンス、状態維持
<Show when={tab() === "home"}>
  <Counter />
</Show>

// キー付き: 毎回新しいインスタンス、状態リセット
<Show when={tab()} keyed>
  {(currentTab) => <TabContent tab={currentTab} />}
</Show>
```

## 一般的なパターン

### ローディング状態

```typescript
const [loading, setLoading] = createSignal(true);
const [data, setData] = createSignal(null);
const [error, setError] = createSignal(null);

<Show when={!loading()} fallback={<Spinner />}>
  <Show when={!error()} fallback={<ErrorMessage error={error()} />}>
    <DataView data={data()} />
  </Show>
</Show>
```

### 認証ガード

```typescript
const [user, setUser] = createSignal(null);

<Show when={user()} fallback={<Navigate to="/login" />}>
  {(u) => (
    <Show when={u.verified} fallback={<VerifyEmail />}>
      <App user={u} />
    </Show>
  )}
</Show>
```

## 試してみよう

認証状態に基づいて異なるコンテンツを表示するログイン/ログアウトトグルを作成：

<details>
<summary>解答</summary>

```typescript
function AuthExample() {
  const [user, setUser] = createSignal(null);

  const login = () => setUser({ name: "Alice", role: "admin" });
  const logout = () => setUser(null);

  return (
    <div>
      <Show
        when={user()}
        fallback={
          <div>
            <p>ログインしてください</p>
            <button onClick={login}>ログイン</button>
          </div>
        }
      >
        {(u) => (
          <div>
            <p>ようこそ、{u.name}さん！</p>
            <Show when={u.role === "admin"}>
              <p>管理パネル</p>
            </Show>
            <button onClick={logout}>ログアウト</button>
          </div>
        )}
      </Show>
    </div>
  );
}
```

</details>

## 次へ

[For（リストレンダリング）→](./flow_for) について学ぶ
