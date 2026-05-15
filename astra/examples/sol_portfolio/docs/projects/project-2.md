---
title: Nebula CLI
description: Streaming log viewer with structured filters.
layout: doc
sidebar: false
---

<div class="project-detail">

[&larr; Back to portfolio](/)

![Nebula CLI screenshot](/projects/project-2.svg)

# Nebula CLI

<p class="meta">2024 &middot; go &middot; cli &middot; tui</p>

A terminal log viewer that takes structured JSON on stdin, applies a pipeline of filters, and renders an ANSI-aware diff between two live streams. Built to replace a brittle `jq | less` workflow at work.

## What I built

- `bubbletea`-based TUI with a fixed 60fps render loop, decoupled from input rate.
- Pluggable filter DSL parsed with a hand-written recursive descent parser.
- Snapshot mode that diffs two log streams side-by-side, color-aware.

## What I learned

A custom filter DSL is a tax. CEL would have done the job and shipped two weeks earlier. The lesson stuck: only invent syntax when an existing one is empirically worse.

</div>
