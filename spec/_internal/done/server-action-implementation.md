# Server Actions Implementation Log

## Overview

Server Actions は Remix/Next.js のような、クライアントからサーバー関数を呼び出す仕組みを MoonBit で実装したもの。

## 実装日

2024-12-23

## 設計の意思決定

### 1. MoonBit Enum のシリアライゼーション形式

**問題:**
JavaScript から MoonBit のコールバック関数に enum 値を渡す際のフォーマット。

**調査結果:**
- `Option` 型は `{ $: "Some", _0: value }` 形式（文字列タグ）
- `AttrValue` などの enum は `{ $tag: 2, _0: value }` 形式（数値タグ）

**採用した形式:**
```javascript
// $tag (数値インデックス) 形式
callback({ $tag: 0, _0: data });     // Success
callback({ $tag: 1, _0: url });      // Redirect
callback({ $tag: 2, _0: status, _1: msg });  // Error
callback({ $tag: 3, _0: msg });      // NetworkError
```

**理由:**
- 既存の Luna DSL コード（`to_attrs()`）が `$tag` を使用している
- `$: "Success"` 形式では正しくマッチしなかった（`[object Object]` にリダイレクト）

**未解決の課題:**
1. `$tag` vs `$` のどちらが公式/安定フォーマットか不明
2. MoonBit 側で enum 用のヘルパー関数を提供すべきか検討
3. ドキュメント化が必要

### 2. Progressive Enhancement

**要件:**
- JavaScript 無効時でもフォームが動作すること
- JavaScript 有効時は AJAX で送信

**実装:**
```
ActionResult::ok(data)         → JSON レスポンス（JS用）
ActionResult::redirect(url)    → JSON { "redirect": "/" }（JS用）
ActionResult::http_redirect(url) → HTTP 302（非JS用）
```

**フロー:**

```
[With JavaScript]
Form submit → preventDefault() → fetch(/_action/...) → JSON → UI更新

[Without JavaScript]
Form submit → POST /_action/... → Content-Type検出 → HTTP 302 → ホームへ
```

### 3. CSRF 保護

**設計:**
- Origin ヘッダー検証（主要な防御）
- Sec-Fetch-Site 検証（補助）
- Content-Type 検証（オプション）

**Progressive Enhancement との両立:**
```moonbit
// JSON 必須の場合
.with_content_type("application/json")

// フォーム送信も許可する場合
.with_require_json(false)  // content-type チェックをスキップ
```

## ファイル構成

```
src/sol/action/
├── types.mbt      # ActionResult, ActionHandler, ActionRegistry など
├── router.mbt     # Hono への登録、CSRF 適用
├── client.mbt     # クライアント側 invoke_action
└── README.md      # 使い方ドキュメント
```

## テスト

```
examples/sol_app/tests/e2e.test.ts
├── Server Action API endpoint      # curl 相当の直接テスト
├── form submission via browser     # JS有効時のフォーム送信
└── Progressive Enhancement         # JS無効時のフォーム送信
```

## 今後の課題

1. **Enum シリアライゼーションの安定化**
   - MoonBit 公式のフォーマットを確認
   - ヘルパー関数の作成を検討

2. **型安全性の向上**
   - アクション引数の型検証
   - レスポンス型の推論

3. **エラーハンドリング**
   - バリデーションエラーの統一形式
   - 非JS時のエラー表示

4. **セキュリティ**
   - CSRF トークンの追加（オプショナル）
   - Rate limiting

## 参考リンク

- [CSRF 対策の現在](https://blog.jxck.io/entries/2024-04-26/csrf.html)
- Remix Server Actions
- Next.js Server Actions
