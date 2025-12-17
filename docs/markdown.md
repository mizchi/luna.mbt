# Incremental Markdown Editor Architecture

## ― Lezer方式 × CST真実モデル × SSR/Hydration × WYSIWYG ―

## 1. 目的と要件

本設計は、以下を同時に満たす Markdown 編集基盤を構築することを目的とする。

* **編集体験最優先**

  * 入力遅延がほぼ感じられない
  * 1文字入力で全文再パース・再レンダしない
* **Incremental Parsing**

  * 最終入力位置（cursor / change range）をヒントに最小再計算
* **GFM互換**

  * 表示・構造はGitHub Markdownと概ね一致
* **SSR + Hydration**

  * サーバ生成HTMLをクライアントで安全に再利用
* **WYSIWYG統合**

  * リッチ表示＋構造編集
  * Markdownへの損失なしラウンドトリップ
* **左右分割ペイン同期**

  * ソース位置 ⇄ プレビュー位置を安定して対応付け

---

## 2. 全体アーキテクチャ概要

```
Markdown Text
      │
      ▼
┌───────────────┐
│   DocCST      │  ← Single Source of Truth
│ (Block/Inline │
│  + Trivia)    │
└───────────────┘
      │
      ├─ Incremental Repair (Lezer-style)
      │
      ├─ Serializer (lossless)
      │
      └─ Renderer
           │
           ▼
     DOM (SSR / CSR)
```

### 中核思想

* **CST（Concrete Syntax Tree）が真実**
* Markdownテキストは *CSTの直列化結果*
* パーサは「生成器」ではなく「修復・検証器」

---

## 3. パース戦略：Lezer方式（Block主導・Fragment Reuse）

### 3.1 なぜCFGではないか

Markdownは以下の性質を持つ：

* 行単位・インデント依存
* 開いているブロック文脈に強く依存
* 参照リンクなど後方依存あり

→ 汎用CFG/LR/PEGは **遅い or インクリメンタルと相性が悪い**

### 3.2 Lezer方式の要点

* **Block層を行駆動の状態機械として処理**
* **Inline層はBlock内部で遅延解析**
* 構文エラーを作らない（失敗しない仮パース）
* **部分木（Fragment）再利用**が前提

---

## 4. DocCST 設計（損失なし）

### 4.1 ノード共通構造

```text
Node {
  nodeId        // 安定ID（reuse時は保持）
  kind          // Block / Inline 種別
  span {from,to} // 元Markdown上の範囲
  children[]
  leadingTrivia
  trailingTrivia
}
```

### 4.2 Triviaとは

* 元の表記を復元するための情報

  * 空白
  * 改行
  * インデント
  * 行末空白
* 意味には影響しないが、**直列化に必須**

### 4.3 Marker保持（損失なしの核心）

Inline / Block ノードは「どの記号を使っていたか」を保持する。

例：

* Emphasis: `*` or `_`
* Strong: `**` or `__`
* FencedCode: ``` or ~~~
* List: `-` / `*` / `+`
* OrderedList: `1.` / `1)`

---

## 5. インクリメンタル処理の役割分担

### 5.1 通常経路（最速）

* 編集操作 → **DocCSTを直接パッチ**
* パースは走らない
* 変更ノードのみ再レンダ

### 5.2 修復経路（保険）

以下の場合のみ Lezer式再パースを起動：

* CST操作が失敗
* 非構造入力（HTMLペースト等）
* 文脈破壊（インデント崩壊など）

処理内容：

* 変更範囲を含むBlockだけ再パース
* Fragment Reuse により旧ノードを最大限再利用
* DocCSTにマージ

---

## 6. WYSIWYG 編集モデル

### 6.1 基本方針

* DOMは**表示専用**
* 編集は **CSTパッチ操作**として定義

### 6.2 操作プリミティブ

代表例：

* `InsertText(nodeId, offset, text)`
* `DeleteRange(anchor, focus)`
* `ToggleMark(range, kind)`
* `WrapBlock(blockId, kind)`
* `SplitParagraph(blockId, offset)`
* `JoinBlocks(a, b)`

IME入力（composition）は確定まで一時テキストとして保持。

---

## 7. Serializer（損失なしラウンドトリップ）

### 7.1 基本原則

* CSTを **そのまま再構成**
* Trivia + marker を忠実に出力
* 勝手に整形しない

### 7.2 Normalizeモード（任意）

* ユーザー明示操作でのみ実行
* 記法統一・空白整理など

---

## 8. SSR + Hydration 設計

### 8.1 SSR HTML 要件

Block単位で以下を必ず付与：

```html
<section
  data-block-id="..."
  data-from="123"
  data-to="456"
>
```

Inlineは必要に応じて `data-node-id`。

### 8.2 Hydration手順

1. SSR HTMLをHydrate
2. 同一Markdown → DocCSTを構築（またはサーバから受信）
3. `nodeId → DOM element` のMapを生成
4. 以後は **変更ノードのみDOM差し替え**

---

## 9. 左右ペイン同期（編集体験）

### 9.1 Source → Preview

1. カーソル位置 → `(nodeId, offset)`
2. 同期対象Blockを決定
3. `blockId → DOM element`
4. `scrollIntoView`

※ Inline基準にしない（スクロールが安定しないため）

### 9.2 Preview → Source

* `IntersectionObserver` で中央Block検出
* 対応する `span.from` へソーススクロール
* クリックは `data-node-id` から直接selection復元

---

## 10. グローバル依存の扱い

### 10.1 参照リンク定義

* `ReferenceIndex` を別管理（label → definition）
* Block変更時に増分更新
* 影響するInlineのみ再解決・再レンダ

### 10.2 リスト番号・採番

* 表記は trivia として保持
* 自動正規化しない
* Normalize時のみ整形

---

## 11. NodeId 安定戦略

* 再利用できるノードは **nodeIdを保持**
* 新規生成時は半安定ID：

```
hash(
  kind,
  parentNodeId,
  localOrdinal,
  span.from,
  markerKind
)
```

→ DOMマップと同期・Hydrationの要

---

## 12. 段階的実装ロードマップ

1. Block CST + trivia（Inlineは生テキスト）
2. Inline導入（Code / Emph / Link）
3. WYSIWYG操作（Toggle / Split / Join）
4. ReferenceIndex増分更新
5. Lezer式再同期フェーズ導入

---

## 13. 設計の本質（要約）

> Markdownを「文法」ではなく
> **編集可能な構造体（CST）」として扱う**

* Lezer方式は **速度と安定性の土台**
* CST真実モデルは **WYSIWYGとSSRの共通基盤**
* 同期・Hydration・差分更新は **nodeId + span** で一本化

---

次のステップとして自然なのは：

* **CSTの具体的型定義（Moonbit）**
* **ToggleMark（太字/斜体）を損失なしで行う詳細アルゴリズム**
* **Lezer式 Block parser の最小実装**

---

## 14. CRDT対応への設計考慮

将来的なリアルタイム協調編集（CRDT）対応を見据えた設計メモ。

参考: [CRDTs Go Brrr](https://josephg.com/blog/crdts-go-brrr/)

### 14.1 現在の実装状況

```
src/core/markdown/
├── types.mbt          # CST型定義 (Span, Block, Inline)
├── scanner.mbt        # O(1)文字アクセス (Array[Char])
├── block_parser.mbt   # ブロックパーサー
├── inline_parser.mbt  # インラインパーサー
├── incremental.mbt    # インクリメンタルパース (EditInfo)
└── serializer.mbt     # ロスレスシリアライザ
```

### 14.2 CRDT対応に必要な拡張

#### (A) 論理ID (Logical Position)

現在の `Span { from, to }` は絶対位置。CRDT では論理位置が必要:

```moonbit
// 現在
#valtype
pub(all) struct Span {
  from : Int  // 絶対位置
  to : Int
}

// CRDT対応案
pub(all) struct LogicalId {
  agent : AgentId   // クライアント識別子
  seq : Int         // Lamport clock / シーケンス番号
}

pub(all) struct CrdtSpan {
  start_id : LogicalId
  end_id : LogicalId
  // キャッシュとして絶対位置も保持可能
  cached_from : Int?
  cached_to : Int?
}
```

#### (B) Tombstone (削除マーカー)

CRDTでは削除時に実際に消さず、マーカーを残す:

```moonbit
pub(all) enum NodeState {
  Active
  Deleted(deleted_by : LogicalId)
}

// Block拡張案
pub(all) struct BlockMeta {
  id : LogicalId
  state : NodeState
  parent_id : LogicalId?
}
```

#### (C) Run-Length Encoding

連続挿入を圧縮（記事では180k→12kエントリに削減）:

```moonbit
// 連続テキスト挿入を1エントリで表現
pub(all) struct TextRun {
  start_id : LogicalId
  content : String      // 複数文字
  len : Int             // 文字数（削除時は負値）
}
```

#### (D) 構造の分離

メタデータとコンテンツを分離してキャッシュ効率向上:

```
DocStructure (B-tree)     DocContent (Rope)
├── BlockMeta[]           ├── TextRun[]
│   ├── id                │   └── content
│   ├── parent_id         │
│   └── state             │
└── aggregate counts      └── (flat array)
```

### 14.3 現時点で採用済みのパターン

| パターン | 状態 | 実装箇所 |
|---------|------|---------|
| インクリメンタル更新 | ✅ 実装済 | `incremental.mbt` |
| カーソルキャッシュ | ✅ 実装済 | `find_affected_range()` |
| #valtype最適化 | ✅ 実装済 | `Span`, `EditInfo` |
| フラット構造 | ✅ Block配列 | `Document.children` |
| Run-Length (テキスト) | 🔶 部分的 | `Inline::Text` で連続テキスト |

### 14.4 初期検証項目

1. **LogicalId の導入コスト**
   - 各ノードにID追加時のメモリ/速度影響

2. **Tombstone の影響**
   - 削除マーカー蓄積によるパース速度低下

3. **ID生成のオーバーヘッド**
   - Agent + Seq の生成・比較コスト

### 14.5 段階的移行案

```
Phase 1: 現状維持
  - 絶対位置ベース (Span)
  - ローカル編集のみ

Phase 2: ID導入 (オプショナル)
  - LogicalId を nullable で追加
  - ローカルではNone、協調時のみ生成

Phase 3: Full CRDT
  - Tombstone導入
  - Operation-based sync
  - Rope + B-tree構造
```

---

## 15. パフォーマンスチューニング知見

### 15.1 ベンチマーク環境

- MoonBit 0.x
- ターゲット: JS (V8), WASM-GC
- 計測: `moon bench`

### 15.2 Scanner最適化

**Array[Char] 変換によるO(1)アクセス:**

```moonbit
// Before: String.get_char(idx) は UTF-8 で O(n)
// After: Array[Char] で O(1)
pub(all) struct Scanner {
  source : String
  chars : Array[Char]  // 事前変換
  mut pos : Int
  len : Int
}
```

| ターゲット | 効果 |
|-----------|------|
| JS | 若干の劣化（JS文字列最適化が強力） |
| WASM-GC | **56%高速化** (scanner peek/advance) |

**結論**: WASM-GC本番向けには有効、JSでも許容範囲。

### 15.3 #valtype 最適化

小さな構造体のヒープ割り当て回避:

```moonbit
#valtype
pub(all) struct Span {
  from : Int
  to : Int
}
```

| ターゲット | 効果 |
|-----------|------|
| JS | **7-9%高速化** |
| WASM-GC | 変化なし（元から最適化済み） |

**適用済み**: `Span`, `EditInfo`

### 15.4 インクリメンタルパース効果

| ドキュメント | フルパース | インクリメンタル | 高速化 |
|-------------|-----------|-----------------|--------|
| 10段落 | 68.89µs | 7.36µs | **9.4x** |
| 50段落 | 327.99µs | 8.67µs | **37.8x** |
| 100段落 | 651.14µs | 15.25µs | **42.7x** |

**キーポイント**:
- 変更ブロックのみ再パース
- 前後のブロックは再利用（Spanシフトのみ）

### 15.5 CRDT関連オーバーヘッド測定

初期検証（JS, 1000回ループ）:

| 操作 | 時間 | 単位あたり |
|------|------|-----------|
| LogicalId生成 | 0.87µs | **0.87ns/ID** |
| LogicalId比較 | 2.93µs | **2.93ns/比較** |
| CrdtDocument insert 100 | 1.10µs | 11ns/挿入 |
| Tombstone走査 (50%削除) | 0.86µs | 微小 |
| Span生成 | 1.31µs | ベースライン |
| CrdtSpan生成 | 4.48µs | **3.4x遅い** |

**考察**:
- LogicalId の生成・比較は十分高速（ナノ秒単位）
- CrdtSpan は Span の約3.4倍のコスト → キャッシュ戦略が重要
- Tombstone走査のオーバーヘッドは最小限

### 15.6 推奨設計パターン

1. **#valtype を小型構造体に適用**
   - Int 2-3個程度の構造体に有効
   - `Span`, `EditInfo`, `LogicalId` など

2. **配列アクセスの最適化**
   - WASM-GC: `Array[Char]` 事前変換が有効
   - JS: ネイティブ文字列APIが高速な場合あり

3. **インクリメンタル処理の積極活用**
   - ドキュメントサイズに比例して効果増大
   - 100段落で40倍以上の高速化

4. **CRDT導入時の注意**
   - CrdtSpan は絶対位置キャッシュを併用
   - Tombstone比率が高くなったら圧縮検討
