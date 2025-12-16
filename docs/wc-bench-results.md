# Web Components SSR/Hydration ベンチマーク結果

`js/wcssr` の Web Components 実装と従来の DOM 操作のパフォーマンス比較。

## TL;DR - 重要な発見

### 1. SSR パフォーマンス: WC と Plain HTML の差はわずか10%

```
公平な比較（エスケープ処理込み）:
  Plain HTML (関数コンポーネント): 4,359 ops/sec
  WC SSR (フル処理):               4,022 ops/sec  ← わずか 1.1x 遅いだけ
```

**誤解を招く比較**（エスケープなし vs フル処理）では100倍の差に見えるが、
実際のアプリケーションでは**ほぼ同等のパフォーマンス**。

### 2. SSR のボトルネックは Shadow DOM 構文ではない

```
オーバーヘッド内訳:
  文字列連結のみ:      25,450 ops/sec  (基準)
  Shadow DOM 構文:    25,382 ops/sec  (1.00x) ← 差なし！
  Plain HTML 構文:    25,332 ops/sec  (1.00x)

  escapeAttr:            396 ops/sec  (64x遅) ← 最大のボトルネック
  JSON.stringify:      2,181 ops/sec  (12x遅)
```

**結論**: Shadow DOM テンプレート構文のコストは**ゼロ**。
エスケープ処理が SSR の主要なボトルネック（WC/Plain 共通）。

### 3. Shadow DOM の実際のオーバーヘッド

| 操作 | オーバーヘッド | 影響 |
|------|---------------|------|
| パース (Declarative Shadow DOM) | 9x遅 | SSR で軽減可能 |
| 初期化 (attachShadow) | 同速 | Plain innerHTML と同等 |
| 更新 (textContent) | 1.12x遅 | **ほぼ同等** |

### 4. 推奨最適化

| 最適化 | 効果 |
|--------|------|
| DOM Parts バッチ更新 | 1.38x 速い |
| Adoptable Stylesheets | 8.4x 速い |
| Event delegation | 1.74x 速い |

---

## テスト環境

- Vitest 2.1.9 (Browser Mode)
- Playwright (Chromium, Firefox, WebKit)
- 実行: `pnpm bench` in `js/wcssr/`

## 詳細結果

### 1. SSR 文字列生成 (Node.js/ブラウザ共通)

#### 公平な比較結果

| 方式 | ops/sec | 比較 |
|------|---------|------|
| Plain HTML (エスケープなし) | 439,572 | 不公平な基準 |
| **Plain HTML (エスケープあり)** | **4,456** | **公平な基準** |
| **Plain HTML (関数コンポーネント)** | **4,359** | **1.02x遅** |
| **WC SSR (フル処理)** | **4,022** | **1.11x遅** |
| WC SSR (renderComponentInline) | 3,930 | 1.13x遅 |

**重要な発見**: 公平な比較では **WC SSR と Plain HTML の差はわずか約10%**。

#### オーバーヘッド内訳

| 処理 | ops/sec | 比較 | 備考 |
|------|---------|------|------|
| 文字列連結のみ | 25,450 | 基準 | |
| Shadow DOM 構文 | 25,382 | 1.00x | **Plain と同速** |
| Plain HTML 構文 | 25,332 | 1.00x | |
| JSON.stringify | 2,181 | 11.7x遅 | ボトルネック |
| escapeJson | 592 | 43x遅 | |
| escapeAttr | 396 | **64x遅** | **最大のボトルネック** |
| escapeAttr(escapeJson(...)) | 449 | 57x遅 | |

**結論**:
- Shadow DOM テンプレート構文自体のコストはほぼゼロ
- **エスケープ処理が SSR の主要なボトルネック**
- WC/Plain HTML どちらでもエスケープは必要なので、差は小さい

### 2. DOM 生成 (ブラウザ)

| 方式 | ops/sec | 比較 | 備考 |
|------|---------|------|------|
| `createElement` | 608,134 | **最速** | DOM API 直接 |
| `attachShadow` + `innerHTML` | 171,214 | 3.6x遅 | Shadow Root 生成 |
| Plain `innerHTML` | 170,044 | 3.6x遅 | パース必要 |
| Declarative Shadow DOM | 66,810 | **9.1x遅** | テンプレート解析 + Shadow Root 生成 |

**結論**:
- `attachShadow + innerHTML` と Plain `innerHTML` はほぼ同速
- Declarative Shadow DOM のパースコストは約3倍（他の innerHTML 比較）
- SSR で Declarative Shadow DOM を使うと、パースコストはブラウザが負担

### 3. DOM 更新 (ブラウザ)

| 方式 | ops/sec | 比較 |
|------|---------|------|
| Plain `textContent` | 54,786 | **基準** |
| WC `textContent` (Shadow DOM内) | 48,932 | 1.12x遅 |
| WC `innerHTML` 全体 | 2,201 | 25x遅 |
| Plain `innerHTML` 全体 | 1,774 | 31x遅 |

**結論**:
- **更新速度は Shadow DOM と通常 DOM でほぼ同じ（12%差）**
- 部分更新 (`textContent`) は全体再描画 (`innerHTML`) の約25-31倍速い

### 4. DOM Parts vs 直接操作

| 方式 | ops/sec | 比較 |
|------|---------|------|
| DOM Parts バッチ | 198,380 | **1.38x速** |
| Direct `textContent` | 143,361 | 基準 |
| DOM Parts 個別 commit | 39,572 | 3.6x遅 |

**DOM Parts バッチが速い理由**:

```typescript
// バッチ: プロパティ代入100回 + DOM書き込み1回
for (let i = 0; i < 100; i++) {
  part.value = String(i);  // JS オブジェクト操作のみ
}
part.commit();              // DOM に1回だけ反映

// 直接: DOM書き込み100回
for (let i = 0; i < 100; i++) {
  textNode.textContent = String(i);  // 毎回 DOM 操作
}
```

**結論**: DOM Parts は Shadow DOM と無関係に、バッチ更新パターンで効果を発揮する

### 5. Hydration

| 方式 | ops/sec | 比較 |
|------|---------|------|
| DOM Parts + イベントバインド | 42,637 | **最速** |
| Plain DOM + イベントバインド | 38,060 | 1.12x遅 |
| WC Full hydration | 16,518 | 2.58x遅 |

**WC Full hydration が遅い理由**:
- `shadowRoot` へのアクセス
- `querySelectorAll` を Shadow DOM 内で実行

### 6. スタイル処理

| 方式 | ops/sec | 比較 |
|------|---------|------|
| Adoptable Stylesheets | 70,130 | **8.4x速** |
| Inline `<style>` | 8,340 | 基準 |

**結論**: コンポーネントが多い場合、Adoptable Stylesheets を使うべき

### 7. イベントバインディング

| 方式 | ops/sec | 比較 |
|------|---------|------|
| Event delegation | 397,874 | **最速** |
| Plain querySelectorAll | 270,768 | 1.47x遅 |
| WC querySelectorAll (Shadow DOM) | 228,888 | 1.74x遅 |

**結論**: Event delegation が最も効率的

---

## Shadow DOM のオーバーヘッド分析

| 操作フェーズ | オーバーヘッド | 理由 |
|-------------|---------------|------|
| **パース** | 10倍遅い | Declarative Shadow DOM テンプレート解析 + Shadow Root 生成 |
| **初期化** | 2-4倍遅い | `attachShadow()` のコスト |
| **更新** | ほぼ同等 (1.2倍) | Shadow Tree も通常の DOM アルゴリズム |

### 重要な洞察

1. **パース/初期化コストは高いが、SSR で軽減可能**
   - サーバーで HTML 生成 → ブラウザでパース
   - Hydration 時はイベントバインドのみ

2. **更新コストは Shadow DOM でも変わらない**
   - 継続的な状態更新に影響なし
   - 部分更新パターンを使えば高速

3. **DOM Parts はバッチ更新で真価を発揮**
   - Shadow DOM と無関係に有効
   - Signal との組み合わせで効果的

---

## 移行判断の指針

### パフォーマンス観点での結論

**SSR パフォーマンスは WC 採用の障壁にならない**

- SSR 文字列生成: WC と Plain HTML でほぼ同等（10%差）
- ボトルネックはエスケープ処理（両方式共通）
- Shadow DOM 構文自体のコストはゼロ

### WC 版を採用すべきケース

- CSS カプセル化が必須（スタイル衝突を避けたい）
- コンポーネントの再利用性・ポータビリティが重要
- Adoptable Stylesheets で最適化できる（8.4x速い）
- 外部配信ウィジェットとして使う

### 現行 `ln:*` 方式が有利なケース

- Declarative Shadow DOM のパースオーバーヘッド（9x）を避けたい
- グローバル CSS で十分
- 既存コードベースとの互換性を優先

### 最適化チェックリスト（WC 採用時）

- [ ] Adoptable Stylesheets を使用（Inline style の 8.4x 速い）
- [ ] DOM Parts でバッチ更新（直接操作の 1.38x 速い）
- [ ] Event delegation を検討（querySelectorAll の 1.74x 速い）
- [ ] 部分更新パターンを使用（全体 innerHTML の 25x 速い）

---

## ベンチマーク実行方法

```bash
cd js/wcssr

# ブラウザテスト（クロスブラウザ）
pnpm test:browser:all

# ベンチマーク実行
pnpm bench

# 特定ブラウザでテスト
pnpm test:browser:chromium
pnpm test:browser:firefox
pnpm test:browser:webkit
```

---

## MoonBit ベンチマーク結果

MoonBit 側のエスケープ・シリアライズ処理のベンチマーク。

### Escape 処理 (src/core/render)

| 関数 | 入力 | 時間 (µs) | 備考 |
|------|------|-----------|------|
| `escape_html` | short_safe (11文字) | 0.08 | **fast path** |
| `escape_html` | short_escape (26文字) | 0.47 | slow path |
| `escape_html` | medium_safe (123文字) | 0.67 | fast path |
| `escape_html` | medium_escape (133文字) | 1.96 | slow path |
| `escape_html` | long_safe (333文字) | 2.08 | fast path |
| `escape_html` | long_escape_end (333文字+8) | 6.50 | **最悪ケース** |
| `escape_html` | heavy_escape (91文字) | 1.27 | 多くの特殊文字 |

| 関数 | 入力 | 時間 (µs) |
|------|------|-----------|
| `escape_attr` | short_safe | 0.05 |
| `escape_attr` | json_string | 0.70 |
| `escape_attr` | heavy_escape | 1.14 |

| 関数 | 入力 | 時間 (µs) |
|------|------|-----------|
| `escape_js_string` | short_safe | 0.14 |
| `escape_js_string` | json_string | 0.60 |
| `escape_js_string` | heavy_escape | 1.17 |

**発見**:
- Fast path チェックは効果的（safe文字列で最大6倍速い）
- 長い文字列の末尾に特殊文字がある場合が最悪ケース（6.5µs）
- `escape_html` と `escape_attr` は同程度の速度

### Serialize 処理 (src/core/serialize)

| 関数 | 入力 | 時間 (µs) |
|------|------|-----------|
| `state_value_to_json` | int | 0.01 |
| `state_value_to_json` | string | 0.15 |
| `state_value_to_json` | escaped_string | 0.49 |
| `state_value_to_json` | small_array (3要素) | 0.08 |
| `state_value_to_json` | medium_array (10要素) | 0.23 |
| `state_value_to_json` | large_array (100要素) | 1.87 |
| `state_value_to_json` | mixed_array (5要素) | 1.56 |

| 関数 | 入力 | 時間 (µs) | 備考 |
|------|------|-----------|------|
| `state_value_from_json` | int | 0.26 | パースは遅い |
| `state_value_from_json` | small_array | 0.76 | |
| `state_value_from_json` | medium_array | 2.21 | |

| 関数 | 入力 | 時間 (µs) |
|------|------|-----------|
| `ResumableState::to_json` | small (3値) | 0.16 |
| `ResumableState::to_json` | medium (10値) | 0.25 |
| `ResumableState::to_json` | large (100値) | 2.06 |
| `state_to_script_tag` | small | 0.57 |
| `state_to_script_tag` | large | 5.98 |

### ボトルネック分析

| 処理 | 時間 | ボトルネック度 |
|------|------|---------------|
| `needs_html_escape` (長文字列) | 1.52µs | **検査自体が遅い** |
| `escape_html` (長文字列 + 末尾特殊文字) | 6.50µs | 最悪ケース |
| `state_to_script_tag` (100値) | 5.98µs | JSON生成 + escape |
| `state_value_from_json` (10要素) | 2.21µs | パース処理 |

### 最適化の方向性

1. **`needs_html_escape` の高速化**
   - 現状: 全文字をイテレート
   - 改善案: SIMD的なバッチ処理（MoonBit では難しい）

2. **`escape_html_to` の StringBuilder 再利用**
   - 現状: 毎回新規 StringBuilder 作成
   - 改善案: 事前確保した StringBuilder を再利用

3. **JSON パースの高速化**
   - 現状: `@json.parse` 使用
   - 改善案: StateValue 専用の軽量パーサー

### 実行方法

```bash
# Escape ベンチマーク
moon bench --target js -p mizchi/luna/core/render

# Serialize ベンチマーク
moon bench --target js -p mizchi/luna/core/serialize
```

---

## 関連ファイル

- `js/wcssr/tests/bench.browser.test.ts` - JS ベンチマークコード
- `js/wcssr/vitest.bench.config.ts` - JS ベンチマーク設定
- `src/core/render/escape_bench.mbt` - MoonBit escape ベンチマーク
- `src/core/serialize/serialize_bench.mbt` - MoonBit serialize ベンチマーク
- `docs/wc_ssr_hydrate.md` - 統合計画
