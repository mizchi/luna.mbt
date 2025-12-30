# Shoelace + Luna UI コンポーネント計画

## 背景

- ShoelaceはDeclarative Shadow DOM (DSD) に対応していない
- SSR時のCLS対策が困難
- 2つのアプローチで対応する

## アプローチ

### 1. Shoelaceバインディング (外部依存)

CDNからShoelaceを読み込み、Luna DSLからカスタム要素を生成。

**利点**:
- 豊富なコンポーネント
- アクセシビリティ対応済み
- メンテナンス不要

**欠点**:
- CLSの完全な解決は困難
- 外部依存
- バンドルサイズ

**対象コンポーネント** (優先度順):
- `sl-button` - ボタン
- `sl-input` - テキスト入力
- `sl-checkbox` - チェックボックス
- `sl-switch` - スイッチ
- `sl-select` - セレクト
- `sl-dialog` - ダイアログ
- `sl-dropdown` - ドロップダウン
- `sl-card` - カード

### 2. Lunaネイティブ実装 (自前)

Light DOM + CSSでShoelace互換のコンポーネントを実装。

**利点**:
- SSR完全対応（CLS = 0）
- バンドルサイズ最小
- 完全なカスタマイズ

**欠点**:
- 実装コスト
- メンテナンスコスト

**対象コンポーネント** (最小セット):
- Button
- Input
- Checkbox
- Switch
- Select (基本)

## 実装計画

### Phase 1: Shoelaceバインディング

```
src/luna/shoelace/
├── mod.mbt           # モジュール定義
├── button.mbt        # sl-button
├── input.mbt         # sl-input
├── checkbox.mbt      # sl-checkbox
├── switch.mbt        # sl-switch
├── select.mbt        # sl-select, sl-option
├── dialog.mbt        # sl-dialog
└── dropdown.mbt      # sl-dropdown, sl-menu
```

### Phase 2: Lunaネイティブコンポーネント

```
src/luna/ui/
├── mod.mbt
├── button.mbt        # Luna Button (Light DOM)
├── input.mbt         # Luna Input
├── checkbox.mbt      # Luna Checkbox
├── switch.mbt        # Luna Switch
├── select.mbt        # Luna Select
└── css/
    └── components.css  # 共通CSS
```

## CSS設計

Shoelaceと互換のCSS変数を使用：

```css
:root {
  /* Colors */
  --luna-color-primary-600: #0ea5e9;
  --luna-color-success-600: #22c55e;
  --luna-color-warning-600: #f59e0b;
  --luna-color-danger-600: #ef4444;

  /* Spacing */
  --luna-spacing-sm: 0.5rem;
  --luna-spacing-md: 1rem;

  /* Border */
  --luna-border-radius: 0.25rem;

  /* Typography */
  --luna-font-sans: system-ui, sans-serif;
}
```

## 進捗

### 完了
- [x] Shoelace Button バインディング (`src/shoelace/button.js`)
- [x] Luna Native Button (`src/ui/button.js` + `button.css`)
- [x] CLS比較テストページ (`comparison.html`)
- [x] Shoelace Input バインディング (`src/shoelace/input.js`)
- [x] Luna Native Input (`src/ui/input.js` + `input.css`)
- [x] **`@luna_ui/shoelace` パッケージ作成** (`js/luna-shoelace/`)
  - Button, Input, Checkbox, Switch コンポーネント
  - TypeScript型定義付き
  - CSR/SSR両対応

### 次のステップ
1. [ ] Luna Native Checkbox/Switch コンポーネント
2. [ ] Select コンポーネント (Shoelace + Luna)
3. [ ] MoonBitへの移植 (`src/luna/shoelace/`, `src/luna/ui/`)
