---
title: Astra Components Demo
description: Three component systems composed on one Astra page — TSX SSR, MoonBit SSR, and a Web Component island.
layout: home
sidebar: false
---

# Astra Components Demo

<p class="lead">A single Astra page composing three rendering systems side by side: a TSX component (React <code>renderToString</code> SSR), a MoonBit component (<code>pub fn render() -&gt; Node[Unit]</code>), and a client-side Web Component hydrated as an island.</p>

<section class="component-section">

<span class="label">TSX · React SSR</span>

## ColorPalette

A static palette rendered server-side from a `.tsx` file. See [/color_palette/](/color_palette/) for the standalone page.

<div class="color-palette-swatches">
<span class="swatch" style="background:#4f46e5">#4f46e5</span>
<span class="swatch" style="background:#10b981">#10b981</span>
<span class="swatch" style="background:#f59e0b">#f59e0b</span>
</div>

</section>

<section class="component-section">

<span class="label">MoonBit · Luna SSR</span>

## InfoBox

A static box rendered from MoonBit's `pub fn render() -> Node[Unit]`. See [/info_box/](/info_box/) for the standalone page.

<div class="info-box">
<span class="icon">i</span>
<div class="body">
<strong>MoonBit-rendered box</strong>
Built from a local <code>.mbt</code> file using <code>@luna.h</code> on the server.
</div>
</div>

</section>

<section class="component-section">

<span class="label">Web Component · Island</span>

## my-counter

A client-side Custom Element hydrated by Astra's island loader. Click to increment — the count is owned by the browser.

<my-counter start="0"></my-counter>

</section>

<footer>
Built with <a href="https://github.com/mizchi/luna.mbt">mizchi/astra</a> · MIT
</footer>
