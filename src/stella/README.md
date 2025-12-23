# Stella

Island埋め込み用のShard生成モジュール。

## 概要

Shard は Island Architecture における hydration 可能なHTML断片。
`luna:*` 属性でマークアップされ、ローダーがクライアントで検知・hydrate する。

## ファイル構成

| ファイル | 責務 |
|---------|------|
| `types.mbt` | Shard設定・出力の型定義 |
| `html_builder.mbt` | HTML生成ユーティリティ |
| `serializer.mbt` | JSON/HTMLエスケープ処理 |

## Shard出力例

```html
<div luna:id="counter"
     luna:url="/static/counter.js"
     luna:state='{"count":0}'
     luna:client-trigger="load">
  <!-- SSR済みコンテンツ -->
</div>
```

## 主要な型

### ShardConfig

```moonbit
pub struct ShardConfig {
  id : String              // コンポーネントID (luna:id)
  script_url : String      // Hydrationスクリプト (luna:url)
  trigger : TriggerType    // トリガー (luna:client-trigger)
  state : StateConfig      // 状態設定
  ssr_content : String?    // SSR済みHTML
  include_loader : Bool    // ローダー埋め込み
  loader_url : String      // ローダーURL
}
```

### StateConfig

```moonbit
pub enum StateConfig {
  Empty                  // 状態なし
  Inline(String)         // luna:state属性に埋め込み
  ScriptRef(String)      // <script id="...">への参照
  Url(String)            // 外部URLからフェッチ
}
```

## セキュリティ

- `serializer.mbt` でXSSエスケープ処理
- JSON内の `</script>` はエスケープ済み
- HTML属性値は適切にクォート

## 参照

- [Luna Core](../luna/README.md) - TriggerType の定義
- [Sol](../sol/README.md) - Island統合の実装
