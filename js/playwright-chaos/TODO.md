# playwright-chaos TODO

## 評価: Luna Docs クロール結果 (2024-12-25)

### 発見された問題

| 問題 | 深刻度 | ステータス | 詳細 |
|------|--------|-----------|------|
| フッターリンク `/overview/` | High | **修正済み** | → `/introduction/overview/` |
| フッターリンク `/js/tutorial/` | High | **修正済み** | → `/luna/tutorial-js/` |
| Browser Router デモ 500 | Medium | 未対応 | SPA history mode + 静的ホスティングの制限 |
| Cloudflare Analytics CORS | Low | 無視 | `--ignore-analytics` オプションで対応済み |

### 改善版クローラー (v2) の評価

**実装した改善:**
1. **リンクソース追跡**: デッドリンク発見時に「どのページから」「どの要素から」かを記録
2. **Discovery Metrics**: extracted links vs clicked links の分離
3. **hover フォールバック削除**: 非表示要素はスキップ
4. **undefined オプションのフィルタリング**: デフォルト値が正しく適用されるように

**定量評価 (v2):**
```
Pages Visited: 50
Extracted links: 735
Clicked links: 4
Dead links: 0  ← 修正済み
Console Errors: 1 (browser_router 500)
Network Errors: 1 (browser_router ERR_ABORTED)
```

**アクション分布の改善:**
```
Before (v1):           After (v2):
hover: 23              hover: 0 (削除)
scroll: 9              scroll: 低優先度で継続
click: 8               click: 適切に実行
```

**結論:**
- リンク抽出 (extractLinks) が包括的: 735 links/50 pages
- クリックアクションは動的リンク発見用として機能
- ノイズが大幅に削減 (Analytics エラー無視、hover 削除)

---

## Chaos Monkey の空間探索有効性

### 現状の探索戦略

| 発見方法 | 発見数 | 役割 |
|---------|-------|------|
| **Link Extraction** | 735 | メイン。HTML解析で全リンクを収集 |
| **Click Actions** | 4 | 補助。動的リンク、JS生成リンク用 |

### アクションの重み付け

```typescript
const DEFAULT_ACTION_WEIGHTS = {
  navigationLinks: 3,    // nav, header 内のリンク優先
  buttons: 2,            // ボタン
  inputs: 1,             // 入力フィールド
  ariaInteractive: 2,    // ARIA role持ちの要素
  visibleText: 1.5,      // 可視テキスト持ちをブースト
  scroll: 0.5,           // スクロールは低優先
};
```

### 有効性の考察

**Chaos アプローチが有効なケース:**
1. **SPA/CSR アプリ**: 初期HTMLにリンクがなく、JSで動的生成される場合
2. **無限スクロール**: スクロールで追加コンテンツがロードされる場合
3. **モーダル/ドロワー**: ユーザー操作で表示されるUIに隠れたリンク
4. **フォーム送信後のナビゲーション**: フォーム→リダイレクトのフロー

**静的サイト (Astra docs) では:**
- Link Extraction だけで十分な網羅性
- Chaos Actions は JS エラー検出に有効
- 動的コンテンツが少ないため、クリック経由の発見は少ない

### 重み付け改善 (実装済み)

**実装した動的重み付け:**

```typescript
// 未踏リンクを強くブースト
if (!visited.has(href) && !isQueued) weight *= 3;

// 既訪問リンクは優先度を下げる
if (visited.has(href)) weight *= 0.2;

// メインコンテンツエリア内の要素を優先
if (isInMainContent(element)) weight *= 1.5;
```

**結果:**
- 未踏リンクが優先的にクリックされるようになった
- 既訪問ページへの重複アクセスが減少
- `main`, `article`, `[role="main"]` 内の要素がブーストされる

---

## 改善 TODO

### High Priority

- [x] **ignore patterns の拡充**
  - `cloudflareinsights.com` を自動無視
  - `*analytics*`, `*beacon*` パターンのプリセット追加
  - CLI: `--ignore-analytics` フラグ追加済み

- [x] **レポートのノイズ削減**
  - hover フォールバック削除
  - 非表示要素のスキップ
  - 外部ドメインブロックのログレベルを debug に

- [x] **SPA 検出と特別処理**
  - CLI: `--spa <pattern>` オプション追加済み
  - SPA パターンにマッチする URL のエラーは `spaIssues` として別カテゴリに分類
  - レポートに "SPA ISSUES (expected behavior)" セクションを追加

### Medium Priority

- [ ] **差分レポート機能**
  - 前回のレポートと比較して新規エラーのみ表示
  - CI で regression detection に使用

- [ ] **HTML リンク抽出の改善**
  - 現在: アクセシビリティツリー + DOM からリンク収集
  - 追加: `<link rel="preload">`, `<script src>` も検証対象に

- [ ] **Playwright Test fixtures の強化**
  - `expectNoDeadLinks(page)` アサーション追加
  - レポートを Playwright HTML Report に統合

### Low Priority

- [ ] **パフォーマンスメトリクス活用**
  - TTFB/FCP/LCP の閾値アラート
  - Core Web Vitals のスナップショット比較

- [ ] **スクリーンショット機能**
  - エラー発生時の自動スクリーンショット
  - Visual regression testing との統合

---

## 次のアクション (Luna プロジェクト向け)

### 即時対応

1. **Browser Router デモの修正**
   - Option A: Hash mode に変更 (`createHashRouter`)
   - Option B: `404.html` で SPA フォールバック
   - Option C: デモを iframe で外部ホスト

2. **Linter の HTML タグ誤検出修正**
   - `src/astra/cli/lint.mbt` で `<head>`, `<title>` 等を除外

### CI 統合 (実装済み)

**justfile コマンド:**
```bash
# 基本チェック（デッドリンクのみ）
just test-docs-links

# strictモード（コンソールエラーも検出）
just test-docs-links-strict
```

**GitHub Actions (.github/workflows/docs.yaml):**
```yaml
- name: Install Playwright
  run: npx playwright install chromium

- name: Check links with Chaos Crawler
  run: |
    npx serve dist-docs -p 3355 &
    sleep 2
    cd js/playwright-chaos
    npx tsx src/cli.ts http://localhost:3355 \
      --max-pages 100 \
      --max-actions 0 \
      --ignore-analytics \
      --exclude "/public/demo/" \
      --compact
```

**オプション解説:**
- `--max-actions 0`: リンク抽出のみ（ランダムアクション無効）
- `--ignore-analytics`: Cloudflare Insights 等のエラー無視
- `--exclude "/public/demo/"`: SPA デモを除外（history mode 問題回避）
- `--compact`: CI向け簡潔出力

---

## 設計メモ

### wrangler dev との互換性

`wrangler.json` 設定:
```json
{
  "assets": {
    "not_found_handling": "404-page"
  }
}
```

この設定では:
- 静的ファイル 404 → `404.html` を表示
- SPA の history mode は動作しない

SPA 対応には `not_found_handling: "single-page-application"` が必要だが、
docs 全体に適用すると通常の 404 が壊れる。

**解決案:**
- デモは別の Worker でホスト
- または `_routes.json` で `/public/demo/*` のみ SPA モードに

### 類似ツールとの比較

| ツール | 特徴 | playwright-chaos との違い |
|--------|------|-------------------------|
| broken-link-checker | HTML 解析ベース | JS 実行なし、SPA 非対応 |
| linkinator | 再帰クロール | アクション実行なし |
| pa11y | アクセシビリティ | リンク検証なし |
| **playwright-chaos** | ランダムアクション | JS 実行、SPA 対応、Recovery 機能 |
