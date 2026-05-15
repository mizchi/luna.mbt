---
title: Astra Docs Search
description: A docs-style example that wires Astra builds to PageFind for client-side full-text search.
layout: home
sidebar: false
---

<section class="hero">

# Astra Docs Search

A 10-page documentation example that demonstrates how to add **client-side full-text search** to an Astra-built static site using [PageFind](https://pagefind.app/).

The index is generated at build time by chaining `astra build` with `pagefind --site dist`. The Web Component below hits the resulting `/pagefind/pagefind.js` bundle at runtime — no server required.

</section>

<search-box></search-box>

<div class="toc">

## Guide

<ul>
<li><a href="/guide/intro/">1. Introduction</a></li>
<li><a href="/guide/install/">2. Install</a></li>
<li><a href="/guide/configuration/">3. Configuration</a></li>
<li><a href="/guide/first-page/">4. Your first page</a></li>
<li><a href="/guide/components/">5. Components &amp; islands</a></li>
<li><a href="/guide/i18n/">6. Internationalisation</a></li>
<li><a href="/guide/search/">7. Adding search</a></li>
<li><a href="/guide/deploy/">8. Deploy</a></li>
<li><a href="/guide/pagefind/">9. PageFind internals</a></li>
<li><a href="/guide/faq/">10. FAQ</a></li>
</ul>

</div>

<footer>
Built with <a href="https://github.com/mizchi/luna.mbt">mizchi/astra</a> + <a href="https://pagefind.app/">PageFind</a> · MIT
</footer>
