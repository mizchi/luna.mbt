# APG Patterns for Luna

WAI-ARIA Authoring Practices Guide (APG) に準拠したアクセシブルなUIコンポーネント集。

## 準拠仕様

- **[WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/)** - W3C Authoring Practices Guide
- **参考実装**: [masuP9/apg-patterns-examples](https://github.com/masuP9/apg-patterns-examples)

## 設計原則

1. **APG仕様準拠**: 各コンポーネントは [WAI-ARIA APG Patterns](https://www.w3.org/WAI/ARIA/apg/patterns/) の仕様に厳密に従う
2. **キーボードナビゲーション**: 完全なキーボード操作サポート
3. **ARIA属性**: 適切なrole、aria-*属性を自動付与
4. **テスト駆動**: 各コンポーネントはアクセシビリティテストを伴う

## コンポーネント一覧

### 実装済み

| パターン | ファイル | APG仕様 |
|---------|---------|---------|
| Accordion | accordion.mbt | [APG Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) |
| Alert | alert.mbt | [APG Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) |
| Breadcrumb | breadcrumb.mbt | [APG Breadcrumb](https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/) |
| Button | button.mbt | [APG Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) |
| Checkbox | checkbox.mbt | [APG Checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) |
| Combobox | combobox.mbt | [APG Combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) |
| Dialog | dialog.mbt | [APG Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) |
| Disclosure | disclosure.mbt | [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) |
| Landmarks | landmarks.mbt | [APG Landmarks](https://www.w3.org/WAI/ARIA/apg/patterns/landmarks/) |
| Link | link.mbt | [APG Link](https://www.w3.org/WAI/ARIA/apg/patterns/link/) |
| Listbox | listbox.mbt | [APG Listbox](https://www.w3.org/WAI/ARIA/apg/patterns/listbox/) |
| Menu Button | menu_button.mbt | [APG Menu Button](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/) |
| Meter | meter.mbt | [APG Meter](https://www.w3.org/WAI/ARIA/apg/patterns/meter/) |
| Radio Group | radio.mbt | [APG Radio](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) |
| Slider | slider.mbt | [APG Slider](https://www.w3.org/WAI/ARIA/apg/patterns/slider/) |
| Spinbutton | spinbutton.mbt | [APG Spinbutton](https://www.w3.org/WAI/ARIA/apg/patterns/spinbutton/) |
| Switch | switch.mbt | [APG Switch](https://www.w3.org/WAI/ARIA/apg/patterns/switch/) |
| Table | table.mbt | [APG Table](https://www.w3.org/WAI/ARIA/apg/patterns/table/) |
| Tabs | tabs.mbt | [APG Tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/) |
| Toolbar | toolbar.mbt | [APG Toolbar](https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/) |
| Tooltip | tooltip.mbt | [APG Tooltip](https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/) |
| Tree View | treeview.mbt | [APG Tree View](https://www.w3.org/WAI/ARIA/apg/patterns/treeview/) |

### 実装予定

- Menu / Menubar
- Grid / Treegrid
- Carousel
- Feed

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
