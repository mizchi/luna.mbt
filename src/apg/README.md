# APG Patterns for Luna

WAI-ARIA Authoring Practices Guide (APG) に準拠したアクセシブルなUIコンポーネント集。

## 設計原則

1. **APG仕様準拠**: 各コンポーネントは [WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/) の仕様に厳密に従う
2. **キーボードナビゲーション**: 完全なキーボード操作サポート
3. **ARIA属性**: 適切なrole、aria-*属性を自動付与
4. **テスト駆動**: 各コンポーネントはアクセシビリティテストを伴う

## コンポーネント一覧

### 実装済み

| パターン | ファイル | APG仕様 |
|---------|---------|---------|
| Link | link.mbt | [APG Link](https://www.w3.org/WAI/ARIA/apg/patterns/link/) |
| Button | button.mbt | [APG Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) |
| Meter | meter.mbt | [APG Meter](https://www.w3.org/WAI/ARIA/apg/patterns/meter/) |
| Landmarks | landmarks.mbt | [APG Landmarks](https://www.w3.org/WAI/ARIA/apg/patterns/landmarks/) |
| Alert | alert.mbt | [APG Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) |
| Tabs | tabs.mbt | [APG Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/) |
| Radio Group | radio.mbt | [APG Radio](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) |
| Dialog | dialog.mbt | [APG Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) |
| Accordion | accordion.mbt | [APG Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) |

### 実装予定

- Checkbox
- Listbox
- Combobox
- Menu/Menubar
- Tree View
- Grid/Treegrid

## 使い方

```moonbit
// Link
let link = @apg.link("https://example.com", [@luna.text("Example")])

// Button
let btn = @apg.button([@luna.text("Click me")])

// Toggle Button
let toggle = @apg.toggle_button(Pressed, [@luna.text("Mute")])

// Meter
let meter = @apg.meter(75.0, aria_label="Battery level", [])

// Landmarks
let page = @apg.page_layout(
  header=[@luna.text("Site Name")],
  nav_content=[@apg.link("/", [@luna.text("Home")])],
  [@luna.text("Main content")],
  footer_content=[@luna.text("© 2024")]
)
```

## テスト

```bash
# MoonBit Unit Tests
moon test src/apg

# Browser Integration Tests (Vitest + axe-core)
pnpm test:integration -- --grep apg
```
