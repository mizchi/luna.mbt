---
title: Astra デモ
description: MoonBit でアイランド / i18n / VRT 付きの静的ランディングを最短で。
layout: home
sidebar: false
---

<div class="lang-switch">
<a href="/">EN</a> · <a href="/ja/">JA</a>
</div>

<section class="hero">

# Astra デモ

MoonBit で書く静的ランディング。アイランド / 多言語 / Playwright VRT を最初から同梱。

<div class="cta">
<a class="primary" href="https://github.com/mizchi/luna.mbt">はじめる</a>
<a href="/ja/about/">詳しく見る</a>
</div>

<theme-toggle></theme-toggle>

</section>

<section class="features">

<div class="card">

### Markdown ファースト

`docs/` 配下の `.md` がそのままルート。`index.md` がディレクトリ ルート、`ja/` がロケール分岐。

</div>

<div class="card">

### 必要な所だけ Island 化

`docs/public/islands/` に web component を置けば markdown 内で普通の HTML として呼び出せる。設定不要。

</div>

<div class="card">

### VRT 同梱

`playwright test` が `fullPage` スクリーンショットでルートを丸ごと検証。 viewport / フォント / アニメをロックして決定論的。

</div>

</section>

<footer>
Built with <a href="https://github.com/mizchi/luna.mbt">mizchi/astra</a> · MIT
</footer>
