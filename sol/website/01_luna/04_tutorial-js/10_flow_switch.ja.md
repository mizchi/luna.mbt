---
title: "制御フロー: Switch"
---

# Switch（複数条件）

複数の相互排他的な条件を処理します。

## 基本的な使い方

```typescript
import { createSignal, Switch, Match } from '@luna_ui/luna';

function StatusBadge() {
  const [status, setStatus] = createSignal("pending");

  return (
    <Switch fallback={<span>不明</span>}>
      <Match when={status() === "pending"}>
        <span class="yellow">保留中</span>
      </Match>
      <Match when={status() === "active"}>
        <span class="green">アクティブ</span>
      </Match>
      <Match when={status() === "error"}>
        <span class="red">エラー</span>
      </Match>
    </Switch>
  );
}
```

## Switch vs ネストした Show

### ネストした Show（冗長）

```typescript
<Show when={status() === "loading"} fallback={
  <Show when={status() === "error"} fallback={
    <Show when={status() === "success"} fallback={
      <DefaultView />
    }>
      <SuccessView />
    </Show>
  }>
    <ErrorView />
  </Show>
}>
  <LoadingView />
</Show>
```

### Switch（きれい）

```typescript
<Switch fallback={<DefaultView />}>
  <Match when={status() === "loading"}>
    <LoadingView />
  </Match>
  <Match when={status() === "error"}>
    <ErrorView />
  </Match>
  <Match when={status() === "success"}>
    <SuccessView />
  </Match>
</Switch>
```

## 値の抽出

`<Show>` と同様に、`<Match>` は truthy 値を抽出できます：

```typescript
const [response, setResponse] = createSignal(null);

<Switch>
  <Match when={response()?.error}>
    {(error) => <p>Error: {error.message}</p>}
  </Match>
  <Match when={response()?.data}>
    {(data) => <DataView data={data} />}
  </Match>
</Switch>
```

## 順序が重要

最初にマッチした `<Match>` が勝ちます：

```typescript
const [score, setScore] = createSignal(85);

<Switch fallback={<p>F</p>}>
  <Match when={score() >= 90}><p>A</p></Match>
  <Match when={score() >= 80}><p>B</p></Match>  {/* 85 でこれがマッチ */}
  <Match when={score() >= 70}><p>C</p></Match>
  <Match when={score() >= 60}><p>D</p></Match>
</Switch>
```

## 一般的なパターン

### タブコンテンツ

```typescript
const [tab, setTab] = createSignal("overview");

<div>
  <nav>
    <button onClick={() => setTab("overview")}>概要</button>
    <button onClick={() => setTab("details")}>詳細</button>
    <button onClick={() => setTab("reviews")}>レビュー</button>
  </nav>

  <Switch>
    <Match when={tab() === "overview"}>
      <OverviewPanel />
    </Match>
    <Match when={tab() === "details"}>
      <DetailsPanel />
    </Match>
    <Match when={tab() === "reviews"}>
      <ReviewsPanel />
    </Match>
  </Switch>
</div>
```

### ステップウィザード

```typescript
const [step, setStep] = createSignal(1);

<div>
  <Switch>
    <Match when={step() === 1}>
      <Step1 onNext={() => setStep(2)} />
    </Match>
    <Match when={step() === 2}>
      <Step2
        onBack={() => setStep(1)}
        onNext={() => setStep(3)}
      />
    </Match>
    <Match when={step() === 3}>
      <Step3
        onBack={() => setStep(2)}
        onSubmit={handleSubmit}
      />
    </Match>
  </Switch>

  <p>ステップ {step()} / 3</p>
</div>
```

## 試してみよう

3つの状態（赤、黄、緑）を持つ信号機コンポーネントを作成し、それらを循環：

<details>
<summary>解答</summary>

```typescript
function TrafficLight() {
  const [light, setLight] = createSignal("red");

  const cycle = () => {
    setLight(current => {
      switch (current) {
        case "red": return "green";
        case "green": return "yellow";
        case "yellow": return "red";
      }
    });
  };

  return (
    <div>
      <div class="traffic-light">
        <Switch>
          <Match when={light() === "red"}>
            <div class="light red">止まれ</div>
          </Match>
          <Match when={light() === "yellow"}>
            <div class="light yellow">注意</div>
          </Match>
          <Match when={light() === "green"}>
            <div class="light green">進め</div>
          </Match>
        </Switch>
      </div>
      <button onClick={cycle}>次へ</button>
    </div>
  );
}
```

</details>

## 次へ

[onMount →](./lifecycle_onmount) について学ぶ
