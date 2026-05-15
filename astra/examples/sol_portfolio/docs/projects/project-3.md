---
title: Comet Graph
description: WebGL graph renderer with WASM layout.
layout: doc
sidebar: false
---

<div class="project-detail">

[&larr; Back to portfolio](/)

![Comet Graph screenshot](/projects/project-3.svg)

# Comet Graph

<p class="meta">2025 &middot; webgl &middot; wasm &middot; visualization</p>

An embeddable graph renderer that handles 100k-node force-directed layouts at 60fps. The layout step runs in a WASM worker; the renderer is pure WebGL2 with instanced draws.

## What I built

- A barnes-hut quadtree implementation in Rust, compiled to WASM.
- WebGL2 renderer with instanced rendering for nodes and a single triangle-strip pass for edges.
- A small React wrapper that handles SSR fallback to a static SVG snapshot.

## What I learned

Profile before optimizing. Half the wins came from removing per-frame allocations in JS glue code, not from the WASM layout. `OffscreenCanvas` + transferable buffers cut main-thread jank to near zero.

</div>
