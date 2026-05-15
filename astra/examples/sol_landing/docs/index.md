---
title: Astra Demo
description: Build static landing pages in MoonBit with islands, i18n, and VRT.
layout: home
sidebar: false
---

<div class="lang-switch">
<a href="/">EN</a> · <a href="/ja/">JA</a>
</div>

<section class="hero">

# Astra Demo

Build static landing pages in MoonBit with islands, i18n, and Playwright VRT — out of the box.

<div class="cta">
<a class="primary" href="https://github.com/mizchi/luna.mbt">Get started</a>
<a href="/about/">Learn more</a>
</div>

<theme-toggle></theme-toggle>

</section>

<section class="features">

<div class="card">

### Markdown-first

Every `.md` under `docs/` becomes a route. `index.md` is the directory root, `ja/` is the locale branch.

</div>

<div class="card">

### Islands on demand

Drop a web component into `docs/public/islands/`, reference it in markdown like normal HTML. No bundler config to maintain.

</div>

<div class="card">

### VRT included

`playwright test` captures `fullPage` screenshots of every route — locked viewport, locked fonts, deterministic baselines.

</div>

</section>

<footer>
Built with <a href="https://github.com/mizchi/luna.mbt">mizchi/astra</a> · MIT
</footer>
