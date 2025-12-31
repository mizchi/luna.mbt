---
title: コンポーネントカタログ
---

# Radix コンポーネントカタログ

Luna は [Radix UI](https://radix-ui.com/) と [shadcn/ui](https://ui.shadcn.com/) にインスパイアされた77個のヘッドレスUIコンポーネントを提供します。

各コンポーネントは3つのバリアントがあります：
- **Headless** (`radix_xxx`) - スタイルなし、セマンティックなHTMLとdata属性
- **Styled** (`radix_xxx_styled`) - Declarative Shadow DOMによるカプセル化されたスタイル
- **UCSS** (`radix_xxx_ucss`) - luna/cssによるアトミックCSSクラス

## レイアウト・構造

| コンポーネント | 説明 |
|---------------|------|
| [AspectRatio](#aspect-ratio) | アスペクト比を維持 |
| [Card](#card) | ヘッダー、コンテンツ、フッター付きカード |
| [Separator](#separator) | 区切り線 |
| [Resizable](#resizable) | リサイズ可能なパネル |
| [ScrollArea](#scroll-area) | カスタムスクロールバー |

## ナビゲーション

| コンポーネント | 説明 |
|---------------|------|
| [Breadcrumb](#breadcrumb) | パンくずリスト |
| [NavigationMenu](#navigation-menu) | サイトナビゲーション |
| [Menubar](#menubar) | アプリケーションメニューバー |
| [Pagination](#pagination) | ページネーション |
| [Tabs](#tabs) | タブ |
| [Sidebar](#sidebar) | 折りたたみ可能なサイドバー |
| [Stepper](#stepper) | ステップウィザード |

## フォーム・入力

| コンポーネント | 説明 |
|---------------|------|
| [Button](#button) | ボタン |
| [Input](#input) | テキスト入力 |
| [Textarea](#textarea) | 複数行テキスト入力 |
| [NumberInput](#number-input) | 数値入力（増減ボタン付き） |
| [Checkbox](#checkbox) | チェックボックス |
| [Radio](#radio) | ラジオボタン |
| [Switch](#switch) | トグルスイッチ |
| [Slider](#slider) | スライダー |
| [RangeSlider](#range-slider) | 範囲スライダー（デュアルハンドル） |
| [Select](#select) | セレクトボックス |
| [Combobox](#combobox) | 検索可能セレクト |
| [AutoComplete](#autocomplete) | 入力補完 |
| [InputOTP](#input-otp) | OTP/PIN入力 |
| [Label](#label) | ラベル |
| [Toggle](#toggle) | トグルボタン |
| [ToggleGroup](#toggle-group) | トグルボタングループ |
| [Rating](#rating) | 星評価 |
| [ColorPicker](#color-picker) | 色選択 |
| [FileUpload](#file-upload) | ファイルアップロード |
| [Mentions](#mentions) | @メンション入力 |

## 日付・時刻

| コンポーネント | 説明 |
|---------------|------|
| [Calendar](#calendar) | カレンダー |
| [DatePicker](#date-picker) | 日付選択 |
| [DateRangePicker](#date-range-picker) | 日付範囲選択 |
| [TimePicker](#time-picker) | 時刻選択 |
| [Countdown](#countdown) | カウントダウン表示 |

## オーバーレイ・モーダル

| コンポーネント | 説明 |
|---------------|------|
| [Dialog](#dialog) | モーダルダイアログ |
| [AlertDialog](#alert-dialog) | 確認ダイアログ |
| [Sheet](#sheet) | スライドインパネル |
| [Drawer](#drawer) | ドロワー |
| [Popover](#popover) | ポップオーバー |
| [Tooltip](#tooltip) | ツールチップ |
| [HoverCard](#hover-card) | ホバープレビュー |
| [ContextMenu](#context-menu) | 右クリックメニュー |
| [DropdownMenu](#dropdown-menu) | ドロップダウンメニュー |
| [Command](#command) | コマンドパレット |

## データ表示

| コンポーネント | 説明 |
|---------------|------|
| [Table](#table) | データテーブル |
| [Avatar](#avatar) | ユーザーアバター |
| [AvatarGroup](#avatar-group) | アバターグループ |
| [Badge](#badge) | バッジ |
| [Tag](#tag) | タグ |
| [Skeleton](#skeleton) | ローディングプレースホルダー |
| [Progress](#progress) | プログレスバー |
| [Spinner](#spinner) | ローディングスピナー |
| [Empty](#empty) | 空状態 |
| [Statistic](#statistic) | 統計値表示 |
| [Timeline](#timeline) | タイムライン |
| [Tree](#tree) | ツリービュー |

## フィードバック

| コンポーネント | 説明 |
|---------------|------|
| [Alert](#alert) | アラートメッセージ |
| [Callout](#callout) | 情報ボックス |
| [Toast](#toast) | トースト通知 |
| [Result](#result) | 操作結果画面 |

## タイポグラフィ

| コンポーネント | 説明 |
|---------------|------|
| [Blockquote](#blockquote) | 引用ブロック |
| [Code](#code) | インライン/ブロックコード |
| [Kbd](#kbd) | キーボードショートカット |
| [List](#list) | リスト |
| [DescriptionList](#description-list) | 説明リスト |

## ユーティリティ

| コンポーネント | 説明 |
|---------------|------|
| [Accordion](#accordion) | アコーディオン |
| [Collapsible](#collapsible) | 折りたたみ可能コンテンツ |
| [Carousel](#carousel) | カルーセル |
| [Image](#image) | 遅延読み込み画像 |
| [BackTop](#back-top) | トップに戻るボタン |
| [FAB](#fab) | フローティングアクションボタン |
| [CopyButton](#copy-button) | クリップボードコピー |
| [SegmentedControl](#segmented-control) | セグメントコントロール |
| [Toolbar](#toolbar) | ツールバー |

---

## 使用例

各コンポーネントの詳細な使用例は[英語版](/05_components/)を参照してください。

### 基本的な使い方

```moonbit
// ヘッドレスバージョン（スタイルなし）
radix_button(variant=Primary, children=[@luna.text("Click me")])

// スタイル付きバージョン（Shadow DOM）
radix_button_styled(variant=Primary, children=[@luna.text("Click me")])

// UCSSバージョン（アトミックCSS）
radix_button_ucss(variant=Primary, children=[@luna.text("Click me")])
```

### 3つのバリアント

| バリアント | 用途 |
|-----------|------|
| **Headless** | 独自のスタイルを適用したい場合。data属性でスタイリング可能 |
| **Styled** | すぐに使えるスタイルが必要な場合。Shadow DOMでカプセル化 |
| **UCSS** | luna/cssと統合したい場合。軽量なアトミッククラス |
